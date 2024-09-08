//
//  WrapModule.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation
import SwiftyJSON
////import PythonLib
import PySwiftCore
import PyAst
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

public class WrapModule: Codable {
	public init(filename: String, classes: [WrapClass] = [], custom_enums: [CustomEnum] = [], python_classes: [String] = [], dispatchEnabled: Bool = false, expose_module_functions: Bool = false, functions: [WrapFunction] = [], constants: [WrapArgProtocol] = [], vars: [WrapArgProtocol] = [], pyi_mode: Bool = false, swift_import_list: [String] = [String](), swiftui_mode: Bool = false) {
		self.filename = filename
		self.classes = classes
		self.custom_enums = custom_enums
		self.python_classes = python_classes
		self.dispatchEnabled = dispatchEnabled
		self.expose_module_functions = expose_module_functions
		self.functions = functions
		self.constants = constants
		self.vars = vars

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
//
//    public var usedTypes: [WrapArg] = []
//    public var usedListTypes: [WrapArg] = []
    public let working_dir = FileManager().currentDirectoryPath
    
    public var pyi_mode: Bool = false
    
    public var swift_import_list = [String]()
    
    public var swiftui_mode: Bool = false
    
    
    
    public init(fromAst name: String, string: String, swiftui: Bool = false) async throws {
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
				
				guard ast_cls.decorator_list.contains(where: { o in
					switch o.name {
					case "wrapper", "autowrap":
						return true
					default: return false
					}
				}) else { continue }
				
				classes.append(try .init(fromAst: ast_cls))
                
            case .Expr:
                if element.name.contains("import") {
                    swift_import_list.append(element.name.replacingOccurrences(of: "import ", with: ""))
                }
          
            case .ImportFrom: continue
			
				
			case .AnnAssign:
				
				print(element)
				if let annAssign = element as? PyAst_AnnAssign {
					vars.append(_WrapArg._fromAst(index: 0, annAssign, name: annAssign.name))
				}
            default:
      
                continue
                
            }
        }
        
        
        //fatalError("temp exit")
    }
    
    internal init(filename: String) {
            self.filename = filename
        }
    
    
	

    
    var classes_has_swift_function: Bool {
        true
        }
    

    func export(objc: Bool, header: Bool) -> String {
        for _ in classes {
            //_class.export(objc: objc, header: header)
        }
        
        return ""
	}
	
	enum CodingKeys: CodingKey {
		case filename
		case classes
		case custom_enums
		case python_classes
		case dispatchEnabled
		case expose_module_functions
		case functions
		case constants
		case vars
		case usedTypes
		case usedListTypes
		case working_dir
		case pyi_mode
		case swift_import_list
		case swiftui_mode
	}
	
	public required init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		filename = try c.decode(String.self, forKey: .filename)
		
	}
	
	public func encode(to encoder: Encoder) throws {
		
	}
}


var wrap_module_shared: WrapModule!
