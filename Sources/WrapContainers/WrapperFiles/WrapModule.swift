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
fileprivate extension PyPointer {

    func callAsFunction(method: String, args: [PyConvertible]) throws -> PyPointer {
        //PyObject_Vectorcall(self, args, arg_count, nil)
        var _args: [PyPointer?] = [self.xINCREF]
        for arg in args {
            _args.append(arg.pyPointer)
        }
        let name = method.pyPointer
        guard let rtn = _args.withUnsafeBufferPointer({ buffer in
            PyObject_VectorcallMethod(name, buffer.baseAddress, _args.count, nil)
        }) else {
            PyErr_Print()
            throw PythonError.call
        }
        _args.forEach(Py_DecRef)
        
        return rtn
    }
}

public class WrapModule {
	public init(filename: String, classes: [WrapClass] = [], custom_enums: [CustomEnum] = [], python_classes: [String] = [], dispatchEnabled: Bool = false, expose_module_functions: Bool = false, functions: [WrapFunction] = [], constants: [WrapArgProtocol] = [], vars: [WrapArgProtocol] = [], usedTypes: [WrapArg] = [], usedListTypes: [WrapArg] = [], pyi_mode: Bool = false, swift_import_list: [String] = [String](), swiftui_mode: Bool = false) {
		self.filename = filename
		self.classes = classes
		self.custom_enums = custom_enums
		self.python_classes = python_classes
		self.dispatchEnabled = dispatchEnabled
		self.expose_module_functions = expose_module_functions
		self.functions = functions
		self.constants = constants
		self.vars = vars
		self.usedTypes = usedTypes
		self.usedListTypes = usedListTypes
		self.pyi_mode = pyi_mode
		self.swift_import_list = swift_import_list
		self.swiftui_mode = swiftui_mode
	}
	
    
    
    public var filename: String
    public var classes: [WrapClass] = []
    //var custom_structs: [CustomStruct] = []
    public var custom_enums: [CustomEnum] = []
    public var python_classes: [String] = []
    public var dispatchEnabled = false
    
    public var expose_module_functions = false
    
    public var functions: [WrapFunction] = []
    
    public var constants: [WrapArgProtocol] = []
    public var vars: [WrapArgProtocol] = []

    public var usedTypes: [WrapArg] = []
    public var usedListTypes: [WrapArg] = []
    public let working_dir = FileManager().currentDirectoryPath
    
    public var pyi_mode: Bool = false
    
    public var swift_import_list = [String]()
    
    public var swiftui_mode: Bool = false
    
    
    
    public init(fromAst name: String, string: String, swiftui: Bool = false) async {
        swiftui_mode = swiftui
        filename = name
        let pyString = string.pyPointer
        guard let _parsed = try? Ast.py_cls?(method: "parse", args: [pyString]) else { PyErr_Print(); pyString.decref(); return }
        #if DEBUG
        //Py_IncRef(_parsed)
        //print(String(Ast.py_cls?.pyObject.dump(node: _parsed, indent: 4 ).pyPointer) ?? "no dump")
        #endif
        let parsed = PythonObject(ptr: _parsed)
        let ast_module = PyAst_Module(parsed)
        
        for element in ast_module.body {
            
            switch element.type {
                
            case .With:
                
                if let with = element as? PyAst_With {
                    guard with.name == "swift_settings" else { break }
                    for item in with.body {
                        switch item.name {
                        case "shared_module_functions":
                            if let shared_module_functions = item as? PyAst_Assign, let value = shared_module_functions.value {
                                
                                expose_module_functions = (Bool(value.name) ?? false)
                            }
                            //
                            
                        default: continue
                        }
                    }
                }
                
                
                
                
            case .FunctionDef:
                
                functions.append(.init(fromAst: element as! PyAst_Function))
                
            case .ClassDef:
                
                guard let ast_cls = element as? PyAst_Class else { fatalError() }
                if ast_cls.decorator_list.first(where: {$0.name == "wrapper" }) != nil {
                    classes.append(.init(fromAst: ast_cls))
                }
                
            case .Expr:
                if element.name.contains("import") {
                    swift_import_list.append(element.name.replacingOccurrences(of: "import ", with: ""))
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
    
    
    
    
//    func postProcess() {
//        for cls in classes {
//            for function in cls.functions {
//                for arg in function.args {
//                    arg.postProcess(mod: self, cls: cls)
//                }
//            }
//        }
//    }
//    required init(from decoder: Decoder) throws {
//        try super.init(from: decoder)
//        build()
//    }

    
    var classes_has_swift_function: Bool {
        true
        }
    
//    func build() {
//        for _class in classes {
//            _class.build()
//            if _class.dispatch_mode {
//                dispatchEnabled = true
//            }
//            
//            
//        }
//        find_used_arg_types()
//    }
    
//    func add_missing_arg_type(type:String) -> WrapArg {
//        let is_data = ["data","jsondata"].contains(type)
//        let json_arg: JSON = [
//            "name":type,
//            "type":type,
//            "idx": 0,
//            "is_data": is_data
//        ]
//
//        let decoder = JSONDecoder()
//        return try! decoder.decode(WrapArg.self, from: json_arg.rawData())
//    }
    
//    func find_used_arg_types() {
//        let test_types = ["object","json","jsondata","data","str", "bytes"]
//        
//        for cls in classes {
//            //var has_swift_functions = false
//            for function in cls.functions {
//                let returns = function.returns
////                if (returns.has_option(.list) || returns.has_option(.data)) && !["object","void"].contains(returns.type.rawValue) {
////                    fatalError("\n\t\(if: returns.has_option(.list),"list[\(returns.type.rawValue)]",returns.type.rawValue) as return type is not supported atm")
////                }
//                if !usedTypes.contains(where: {$0.type == returns.type && ($0.has_option(.list) == returns.has_option(.list))}) {
//                    //check for supported return list
//                    
//                    
//                    if returns.has_option(.list) || returns.has_option(.data) || returns.has_option(.json) || test_types.contains(returns.type.rawValue) {
//                        
//                        usedTypes.append(returns)
//                        if !usedTypes.contains(where: {$0.type == returns.type && !$0.has_option(.list)}) {
//                            usedTypes.append(add_missing_arg_type(type: returns.type.rawValue))
//                        }
//                    }
//                        
//                }
//                                    
//                for arg in function.args {
//                    let is_list = arg.has_option(.list)
//                    
//                    if !usedTypes.contains(where: {$0.type == arg.type && ($0.has_option(.list) == is_list)}) {
//                        if is_list || arg.has_option(.data) || arg.has_option(.json) || test_types.contains(arg.type.rawValue){
//                            usedTypes.append(arg)
//                        }
//                    }
//                }
//                //if function.swift_func {has_swift_functions = true}
//            } //function loop end
//            
//           
//            
//        }
//    }
    
    func export(objc: Bool, header: Bool) -> String {
        for _ in classes {
            //_class.export(objc: objc, header: header)
        }
        
        return ""
    }
}


var wrap_module_shared: WrapModule!
