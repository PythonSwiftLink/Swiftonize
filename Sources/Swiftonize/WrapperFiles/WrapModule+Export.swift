//
//  WrapModule+Export.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 13/03/2022.
//

import Foundation


extension WrapModule {
    
    
    var pyx_new: String {
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
//        let type_imports = """
//        \(generateTypeDefImports(imports: usedTypes))
//        """
//        \(classes.map{ cls -> String in
//            "\(if: cls.dispatch_mode, generateEnums(cls: cls, options: [.cython,.dispatch_events]))"
//        }
//        .joined(separator: newLine))
        
        var pyx_base: String
        
        pyx_base = """
        cdef extern from "_\(filename).h":
            
            ####### cdef extern Global Functions: ########
            \(generateGlobalSendFunctions(mod: self, objc: false, header: true))
            ######## cdef extern Send Functions: ########
            
            \(classes.map{ cls -> String in
                if cls.swift_object_mode {
                    return """
                    
                        void* \(cls.title)_pyInitializer(PyObject* py_cls)
                        void \(cls.title)_pyDeinitializer(void* __ptr)
                        \(generateSendFunctions(cls: cls, objc: false, header: true))
                       
                    """
                } else {
                    return """
                    void set_\(cls.title)_Callback(PyObject* callback\(if: !cls.singleton, ", const void* cython_class"))
                        \(generateSendFunctions(cls: cls, objc: false, header: true))
                    """
                }
            }.joined(separator: newLineTab))
        #generateCallbackFunctions(options: [.header, .pyx_extern])
        \("")
            
        \(custom_structs.map{$0.export(options: [.python])}.joined(separator: newLine))
        \(if: custom_enums.filter({$0.type != .object}).count != 0, "from enum import IntEnum\n")
        \(generateGlobalEnums(mod: self, options: [.python]))
        
        \(generatePyxGlobalFunctions())
        """
    
        var pyx_strings = [imports,pyx_base]
//        var pyx_strings = [imports,type_imports,pyx_base]
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
            
            let class_string = """
            
            ######## Cython Class: ########
            \(generateCythonClass(module_name: filename , cls: cls, class_vars: cls.class_vars.joined(separator: newLine), dispatch_mode: cls.dispatch_mode))
                ######## Cython Class Extensions: ########
                
                \(extendCythonClassTempNew(cls: cls, options: cls.class_ext_options))
                ######## Class Functions: ########
                \(if: cls.dispatch_mode, "def on_default(self, *args, **kwargs):...")
                \(if: cls.dispatch_mode, cls.dispatch_events.map{"def on_\($0)(self, *args, **kwargs):..."}.joined(separator: newLineTab))
            \(generatePyxClassFunctionsNew(cls: cls))
            """
            pyx_strings.append(class_string)

        }
        pyx_strings.append("\n\n")
        pyx_strings.append(contentsOf: self.python_classes)
        return pyx_strings.joined(separator: newLine).replacingOccurrences(of: "    ", with: "\t")
    }
    
    
    var h_new: String {
        
        generateHeaderFile()
        
    }
    
    public var pyswift_code: String {
        
        """
        //
        // \(filename).swift
        //
        
        import Foundation
        \(if: swiftui_mode, """
        import PythonSwiftCore
        import PythonLib
        """)
        
        \(swift_import_list.joined(separator: newLine))
        
        \(classes.map(\.swift_string).joined(separator: newLine))

        \(generateSwiftPythonObjectCallbackWrap)
        
        \(generatePyModule)
        """
    }
    
    var swift_new: String {
        let enum_structs = """
         \(classes.filter{$0.dispatch_mode}.map{ cls -> String in
             generateEnums(cls: cls, options: [.dispatch_events, .swift])
         }.joined(separator: newLine))
         
         \(generateObjectEnums(mod: self, options: .swift))
         
         """

        var swift_string = """
        import Foundation
        import UIKit
        
        \(enum_structs)
        \(generateGlobalEnums(mod: self, options: [.swift]))
        \(custom_structs.map{$0.export(options: [.swift])}.joined(separator: newLine))
        //######## Send Functions Protocol: ########//
        \(generateSwiftSendProtocol)

        \(generateSwiftPythonObjectCallbackWrap)
        \(generateGlobalSwiftFunctions(mod: self))
        """
        
            let send_options: [handlerFunctionCodeType] = [.swift, .init_delegate, .send]
        
        for cls in self.classes {
            print(cls.functions.filter{$0.has_option(option: .callback)}.map{$0.name})
            var send_opts = send_options
            if cls.callbacks_count > 0 { send_opts.append(.callback) }
            swift_string.append("\n\(generateHandlerFuncs(cls: cls, options: send_opts))")
        }
        return swift_string
    }
     
    
    private func generateHeaderFile() -> String {
        
        let global_functions = functions.map { _func -> String in
            generateGlobalSendFunctions(mod: self, objc: true, header: true)
        }.joined(separator: newLine)
        
        let set_callbacks = classes.map{ cls -> String in
            generateHandlerFuncs(cls: cls, options: [.objc_h])
        }.joined(separator: newLine)
        
        let send_functions = classes.map{ cls -> String in
            generateSendFunctions(cls: cls, objc: true, header: true)
        }.joined(separator: newLine)
        
        return """
        #ifndef \(filename)_h
        #define \(filename)_h
        #include "python.h"
        #include <stdbool.h>
        
        //insert enums / Structs
        //generateGlobalEnums(mod: self, options: [.c])
        \("")

        //######## cdef extern Callback Function Pointers: ########//
        //generateFunctionPointers(objc: true, options: [.excluded_callbacks])
        \("")
        //generateStruct(options: [.swift_functions, .objc])
        \("")
        \(generateFunctionPointers(objc: true, options: [.excluded_callbacks_only]))
        //######## cdef extern Callback Struct: ########//
        //generateStruct(options: [.objc, .callbacks])
        \("")
        \(global_functions)
        //######## Set Callback Functions: ########//
        \(set_callbacks)
        //######## Send Functions: ########//
        \(send_functions)
        #endif /* \(filename)_h */
        """
    }
    
}





