//
//  WrapModule.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation
import SwiftyJSON
import PythonLib
import PythonSwiftCore
import PyAstParser
//class WrapModuleBase: Codable {
//    var filename: String
//    var classes: [WrapClass]
//
//}


public class WrapModule: Codable {
    
    
    var filename: String
    var classes: [WrapClass] = []
    var custom_structs: [CustomStruct] = []
    var custom_enums: [CustomEnum] = []
    var python_classes: [String] = []
    var dispatchEnabled = false
    
    var functions: [WrapFunction] = []
    
    var constants: [WrapArgProtocol] = []
    var vars: [WrapArgProtocol] = []

    var usedTypes: [WrapArg] = []
    var usedListTypes: [WrapArg] = []
    let working_dir = FileManager().currentDirectoryPath
    
    var pyi_mode: Bool = false
    
    var swift_import_list = [String]()
    
    var swiftui_mode: Bool = false
    
    
    private enum CodingKeys: CodingKey {
        case filename
        case classes
        case custom_structs
        case custom_enums
        case python_classes
        case functions
    }
    public init(fromAst name: String, string: String, swiftui: Bool = false) async {
        swiftui_mode = swiftui
        filename = name
        let pyString = string.pyPointer
        guard let _parsed: PythonPointerU = Ast.py_cls(method: "parse", args: [pyString]) else { PyErr_Print(); pyString.decref(); return }
        #if DEBUG
        //Py_IncRef(_parsed)
        //print(String(Ast.py_cls?.pyObject.dump(node: _parsed, indent: 4 ).pyPointer) ?? "no dump")
        #endif
        let parsed = PythonObject(ptr: _parsed)
        let ast_module = PyAst_Module(parsed)
        
        for element in ast_module.body {
            
            switch element.type {
                
            case .FunctionDef:
                
                functions.append(.init(fromAst: element as! PyAst_Function))
                
            case .ClassDef:
                
                guard let ast_cls = element as? PyAst_Class else { fatalError() }
                if ast_cls.decorator_list.first(where: {$0.name == "wrapper" }) != nil {
                    classes.append(.init(fromAst: ast_cls))
                }
                
            case .Expr:

                if element.name.contains("import") {
                    swift_import_list.append(element.name)
                }
                
            case .ImportFrom: continue
                
            default:
      
                continue
                
            }
        }
        
        
        //fatalError("temp exit")
    }
    
    internal init(filename: String) {
            self.filename = filename
        }
    
    required public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filename = try container.decode(String.self, forKey: .filename)
        wrap_module_shared = self
        
        custom_structs.append(contentsOf: try container.decode([CustomStruct].self, forKey: .custom_structs))
        custom_enums.append(contentsOf: try container.decode([CustomEnum].self, forKey: .custom_enums))
        classes.append(contentsOf: try container.decode([WrapClass].self, forKey: .classes))
        python_classes.append(contentsOf: try container.decode([String].self, forKey: .python_classes))
        functions.append(contentsOf: try container.decode([WrapFunction].self, forKey: .functions))
        postProcess()
        build()
    }
    
    
    func postProcess() {
        for cls in classes {
            for function in cls.functions {
                for arg in function.args {
                    arg.postProcess(mod: self, cls: cls)
                }
            }
        }
    }
//    required init(from decoder: Decoder) throws {
//        try super.init(from: decoder)
//        build()
//    }
    var pyx: String {
        
        var imports = """
        #cython: language_level=3
        import json
        from typing import List,Sequence
        from libc.stdlib cimport malloc, free
        from cpython.ref cimport PyObject
        
        """
        if dispatchEnabled {
            imports.append("\nfrom kivy._event cimport EventDispatcher")
        }
        let type_imports = """
        \(generateTypeDefImports(imports: usedTypes))
        """
//        \(classes.map{ cls -> String in
//            "\(if: cls.dispatch_mode, generateEnums(cls: cls, options: [.cython,.dispatch_events]))"
//        }
//        .joined(separator: newLine))
        
        let pyx_base = """
        cdef extern from "_\(filename).h":
            ######## cdef extern Callback Function Pointers: ########
            \(generateFunctionPointers(objc: false, options: [.excluded_callbacks]))
            ######## cdef extern Callback Struct: ########
            \(classes.map{ cls -> String in
                if cls.has_swift_functions {
                    if !cls.class_ext_options.contains(.init_callstruct) {cls.class_ext_options.append(.init_callstruct)}
                    cls.class_ext_options.append(.swift_functions)
                    cls.class_vars.append("\t" + cls.functions.filter{$0.has_option(option: .swift_func) && !$0.has_option(option: .callback)}.map{"cdef \($0.function_pointer) _\($0.name)_"}.joined(separator: "\n\t") + newLine)
                    return """
                    \(generateStruct(options: [.swift_functions]))
                        \(generateFunctionPointers(objc: false, options: [.excluded_callbacks_only]))
                    """
                }
                return ""
            }.joined(separator: newLine))
            \("#swift_funcs_struct")
            
            \(generateStruct(options: [.callbacks]))
            
            ######## cdef extern Send Functions: ########
            \(classes.map{ cls -> String in
                """
                void set_\(cls.title)_Callback(PyObject* callback\(if: !cls.singleton, ", const void* cython_class"))
                    \(generateSendFunctions(cls: cls, objc: false, header: true))
                """
            }.joined(separator: newLineTab))
        
        \(generateCallbackFunctions(options: [.header, .pyx_extern]))
            
        \(custom_structs.map{$0.export(options: [.python])}.joined(separator: newLine))
        \(if: custom_enums.filter({$0.type != .object}).count != 0, "from enum import IntEnum\n")
        \(generateGlobalEnums(mod: self, options: [.python]))
        """
    
        
        var pyx_strings = [imports,type_imports,pyx_base]
        for cls in classes {
            //var swift_funcs_struct = ""
            //\t__events__ = \(cls.title)_events
            if cls.dispatch_mode {
                let events = cls.dispatch_events.map{"\"on_\($0)\""}
                cls.class_vars.append("""
                \t__events__ = [\"on_default\", \(events.joined(separator: ", "))]
                """)
                cls.class_ext_options.append(.event_dispatch)
                //EnumStrings = generateEnums(cls: cls, options: [.cython,.dispatch_events])
            }
            if !cls.singleton {
                cls.class_vars.append("\tcdef object callback_class")
            }
            cls.class_vars.append("")
            
            let class_string = generatePyxClass(cls: cls, class_vars: cls.class_vars.joined(separator: newLine), dispatch_mode: cls.dispatch_mode)
//            let class_string = """
//
//            ######## Cython Class: ########
//                \(generateCythonClass(module_name: filename, cls: cls, class_vars: cls.class_vars.joined(separator: newLine), dispatch_mode: cls.dispatch_mode))
//                ######## Cython Class Extensions: ########
//
//                \(extendCythonClassNew(cls: cls, options: cls.class_ext_options))
//                ######## Class Functions: ########
//                \(if: cls.dispatch_mode, "def on_default(self, *args, **kwargs):...")
//                \(if: cls.dispatch_mode, cls.dispatch_events.map{"def on_\($0)(self, *args, **kwargs):..."}.joined(separator: newLineTab))
//            \(generatePyxClassFunctions(cls: cls))
//            """
            pyx_strings.append(class_string)

        }
        pyx_strings.append(contentsOf: self.python_classes)
        return pyx_strings.joined(separator: newLine).replacingOccurrences(of: "    ", with: "\t")
    }
    
    var h: String {
//        let enum_structs = """
//        \(classes.filter{$0.dispatch_mode}.map{ cls -> String in
//            generateEnums(cls: cls, options: [.dispatch_events, .objc])
//        }.joined(separator: newLine))
//        """
        
        //let swift_function_classes = classes.filter{$0.has_swift_functions}
        
        let set_callbacks = classes.map{ cls -> String in
            generateHandlerFuncs(cls: cls, options: [.objc_h])
        }.joined(separator: newLine)
        
        let send_functions = classes.map{ cls -> String in
            generateSendFunctions(cls: cls, objc: true, header: true)
        }.joined(separator: newLine)
        
//        for cls in self.classes{
//            h_string.append( """
//            //insert enums / Structs
//            \(if: cls.dispatch_mode,generateEnums(cls: cls, options: [.dispatch_events, .objc]))
//            //######## cdef extern Callback Function Pointers: ########//
//            \(generateFunctionPointers(objc: true, options: [.excluded_callbacks]))
//
//            //######## cdef extern Callback Struct: ########//
//            \(if: cls.has_swift_functions, generateStruct(options: [.swift_functions, .objc]) )
//            \(if: cls.has_swift_functions, generateFunctionPointers(objc: true, options: [.excluded_callbacks_only]) )
//            \(generateStruct(options: [.objc, .callbacks]))
//
//            //######## Send Functions Protocol: ########//
//            \(generateHandlerFuncs(cls: cls, options: [.objc_h]))
//            //######## Send Functions: ########//
//            \(generateSendFunctions(cls: cls, objc: true, header: true))
//            """)
//            //\(generateSendProtocol(module: self))
//            //\(generateStruct(module: self, options: [.objc, .swift]))
//            //\(generateHandlerFuncs(cls: cls, options: [.objc_h, .init_delegate, .callback]))
//            //
//        }
        //h_string.append("#endif /* \(filename)_h */")
        return """
        #ifndef \(filename)_h
        #define \(filename)_h
        #include "wrapper_typedefs.h"
        #include <stdbool.h>
        
        //insert enums / Structs
        \(generateGlobalEnums(mod: self, options: [.c]))

        //######## cdef extern Callback Function Pointers: ########//
        \(generateFunctionPointers(objc: true, options: [.excluded_callbacks]))

        \(generateStruct(options: [.swift_functions, .objc]))
        \(generateFunctionPointers(objc: true, options: [.excluded_callbacks_only]))
        //######## cdef extern Callback Struct: ########//
        \(generateStruct(options: [.objc, .callbacks]))
        
        //######## Set Callback Functions: ########//
        \(set_callbacks)
        //######## Send Functions: ########//
        \(send_functions)
        #endif /* \(filename)_h */
        """
    }
    
    var m: String {
        var m_string = """
        #import "_\(filename).h"
        
        """
        for cls in self.classes {
            m_string.append("\(generateHandlerFuncs(cls: cls, options: [.objc_m, .init_delegate, .callback, .send]))")
        }
        return m_string
        }
    
    var c: String {
        var c_string = """
        #import "_\(filename).h"
        """
        for cls in self.classes {
            c_string.append("\(generateHandlerFuncs(cls: cls, options: [.objc_m, .init_delegate, .callback, .send]))")
        }
        return c_string
    }
    
    var swift: String {
        let enum_structs = """
            \(classes.filter{$0.dispatch_mode}.map{ cls -> String in
                generateEnums(cls: cls, options: [.dispatch_events, .swift])
            }.joined(separator: newLine))
            
            \(generateObjectEnums(mod: self, options: .swift))
            
            """
        var swift_string = """
        import Foundation
        \(enum_structs)
        \(generateGlobalEnums(mod: self, options: [.swift]))
        \(custom_structs.map{$0.export(options: [.swift])}.joined(separator: newLine))
        //######## Send Functions Protocol: ########//
        \(generateSwiftSendProtocol)
        
        \(generateSwiftPythonObjectCallbackWrap)
        
        """
        for cls in self.classes {
            swift_string.append("\(generateHandlerFuncs(cls: cls, options: [.swift, .init_delegate, .callback, .send]))")
        }
        return swift_string
        }
    
    var classes_has_swift_function: Bool {
        true
        }
    
    func build() {
        for _class in classes {
            _class.build()
            if _class.dispatch_mode {
                dispatchEnabled = true
            }
            
            
        }
        find_used_arg_types()
    }
    
    func add_missing_arg_type(type:String) -> WrapArg {
        let is_data = ["data","jsondata"].contains(type)
        let json_arg: JSON = [
            "name":type,
            "type":type,
            "idx": 0,
            "is_data": is_data
        ]
        
        let decoder = JSONDecoder()
        return try! decoder.decode(WrapArg.self, from: json_arg.rawData())
    }
    
    func find_used_arg_types() {
        let test_types = ["object","json","jsondata","data","str", "bytes"]
        
        for cls in classes {
            //var has_swift_functions = false
            for function in cls.functions {
                let returns = function.returns
//                if (returns.has_option(.list) || returns.has_option(.data)) && !["object","void"].contains(returns.type.rawValue) {
//                    fatalError("\n\t\(if: returns.has_option(.list),"list[\(returns.type.rawValue)]",returns.type.rawValue) as return type is not supported atm")
//                }
                if !usedTypes.contains(where: {$0.type == returns.type && ($0.has_option(.list) == returns.has_option(.list))}) {
                    //check for supported return list
                    
                    
                    if returns.has_option(.list) || returns.has_option(.data) || returns.has_option(.json) || test_types.contains(returns.type.rawValue) {
                        
                        usedTypes.append(returns)
                        if !usedTypes.contains(where: {$0.type == returns.type && !$0.has_option(.list)}) {
                            usedTypes.append(add_missing_arg_type(type: returns.type.rawValue))
                        }
                    }
                        
                }
                                    
                for arg in function.args {
                    let is_list = arg.has_option(.list)
                    
                    if !usedTypes.contains(where: {$0.type == arg.type && ($0.has_option(.list) == is_list)}) {
                        if is_list || arg.has_option(.data) || arg.has_option(.json) || test_types.contains(arg.type.rawValue){
                            usedTypes.append(arg)
                        }
                    }
                }
                //if function.swift_func {has_swift_functions = true}
            } //function loop end
            
           
            
        }
    }
    
    func export(objc: Bool, header: Bool) -> String {
        for _ in classes {
            //_class.export(objc: objc, header: header)
        }
        
        return ""
    }
}


var wrap_module_shared: WrapModule!
