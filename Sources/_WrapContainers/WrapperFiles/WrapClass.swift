//
//  WrapClasses.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation
import SwiftyJSON
import PyAst
import SwiftSyntax

public enum ClassPropertyType: String, Codable, CaseIterable {
    case Getter
    case GetSet
    case Property
    case NumericProperty
    case StringProperty
}

class WrapClassPropertyOld {
    
    
    let name: String
    let property_type: ClassPropertyType
    let arg_type: WrapArg
    let arg_type_new: WrapArgProtocol
    

    init(name: String, property_type: ClassPropertyType, arg_type: WrapArg) {
        self.name = name
        self.property_type = property_type
        self.arg_type = arg_type
        self.arg_type_new = otherArg()//handleWrapArgTypes(args: [arg_type]).first!
    }
    
    
}

public class WrapClassProperty {
    
    
    public let name: String
    public let property_type: ClassPropertyType
    //let arg_type: WrapArg
    public let arg_type: WrapArgProtocol
	
	public let target_name: String?
    
    
	public init(name: String, property_type: ClassPropertyType, arg_type: WrapArgProtocol, target_name: String? = nil) {
        self.name = name
        self.property_type = property_type
        self.arg_type = arg_type
		self.target_name = target_name
        //self.arg_type_new = handleWrapArgTypes(args: [arg_type]).first!
    }
    
    
}

public extension PyAst_Assign {
    
    
    
}

public enum PyClassFunctions: String, CaseIterable {
    case __init__
    case __repr__
    //case __bytes__
    case __str__
    case __hash__
    //case __bool__
    //case __dir__
    case __set_name__
    //case __instancecheck__
    case __call__
    case __iter__
    case __buffer__
    
    public var protocol_string: String {
        switch self {
        case .__repr__:
            return "func __repr__() -> String"
        case .__str__:
            return "func __str__() -> String"
        case .__hash__:
            return "func __hash__() -> Int"
        case .__set_name__:
            return "func __set_name__() -> String"
        case .__buffer__:
            return "func __buffer__(s: PyPointer?, buffer: UnsafeMutablePointer<Py_buffer>) -> Int32"
        default: return ""
        }
    }
    
}


public enum PySequenceFunctions_ {
    case __len__ // PySequenceMethods.sq_length - methods.length
    case __getitem__(key: PythonType, returns: PythonType) // PySequenceMethods.sq_item - methods.get_item
    case __setitem__(key: PythonType, value: PythonType) // PySequenceMethods.sq_ass_item - methods.set_item
    case __delitem__(key: PythonType)
    case __missing__
    case __reversed__
    case __contains__ // PySequenceMethods.sq_contains - methods.contains
    
    public var protocol_string: String {
        switch self {
        case .__len__:
            return "func __len__() -> Int"
        case .__getitem__(_, let returns):
            return "func __getitem__(idx: Int) throws -> \(returns.swiftType) // hello"
        case .__setitem__(_, let value):
            return "func __setitem__(idx: Int, newValue: \(value.swiftType)) throws"
        case .__delitem__(_):
            return "func __delitem__(idx: Int) throws"
        case .__missing__:
            return ""
        case .__reversed__:
            return ""
        case .__contains__:
            return ""
        }
    }
    
    public var name: String {
        switch self {
        case .__len__:
            return "__len__"
        case .__getitem__(_,_):
            return "__getitem__"
        case .__setitem__(_,_):
            return "__setitem__"
        case .__delitem__(_):
            return "__delitem__"
        case .__missing__:
            return "__missing__"
        case .__reversed__:
            return "__reversed__"
        case .__contains__:
            return "__contains__"
        }
    }
    
}

public enum PyNumericFunctions: String, CaseIterable {
    case __add__
    case __sub__
    case __mul__
}
public enum PyAsyncFunctions: String, CaseIterable {
    
    // async
    case __await__
    case __aiter__
    case __anext__
    
}

public enum PySequenceFunctions: String, CaseIterable {
    case __len__ // PySequenceMethods.sq_length - methods.length
    case __getitem__ // PySequenceMethods.sq_item - methods.get_item
    case __setitem__ // PySequenceMethods.sq_ass_item - methods.set_item
    case __delitem__
    case __missing__
    case __reversed__
    case __contains__ // PySequenceMethods.sq_contains - methods.contains
}

public enum RepresentedPyPType: String {
	case `class`
	case tuple
	case dict
	case list
}

public class WrapClass: Codable {
	
	
	enum WrapClassError: Error {
		case AnnAssignType(_ message: String)
	}

    public var _title: String
    public var title: String {
		if alternate_title == "nil" { return _title}
        return alternate_title ?? _title
    }
	public var extension_title: String?
	public var full_extension_title: String {
		if let extension_title = extension_title {
			return "\(extension_title).\(title)"
		}
		return title
	}
    public var alternate_title: String?
    public var functions: [WrapFunction]
    public var decorators: [WrapClassDecorator]
    public var properties: [WrapClassProperty]
    public let singleton: Bool
    
    public var new_class = false
    
    public var bases: [WrapClassBase] = []
    
    public var wrapper_target_type: WrapperTargetType = ._class
    
    
    public var callbacks_count = 0
    public var pointer_compare_strings: [String] = []
    public var pointer_compare_dict: [String:[String:String]] = [:]
    public var dispatch_mode = false
    public var has_swift_functions = false
    public var dispatch_events: [String] = []
    public var class_vars: [String] = []
    //var class_ext_options: [CythonClassOptionTypes] = [.init_callstruct]
    public var class_ext_options: [CythonClassOptionTypes] = [.init_callstruct]
    
    public var pySequenceMethods: [PySequenceFunctions_] = []
	
	public var pyAsyncMethods: [PyAsyncFunctions] = []
    
    public var pyClassMehthods: [PyClassFunctions] = []
    
    public var pyNumericMethods: [PyNumericFunctions] = []
    
    
    public var callback_protocols: [String] = []
    
    public var swift_object_mode = false
    
    public var init_function: WrapFunction?
    
    public var ignore_init = false
    
    public var debug_mode = false
    
    public var unretained = false
    
    public var callbacks: [WrapFunction] { functions.filter({$0.has_option(option: .callback)}) }
    public var send_functions: [WrapFunction] { functions.filter({!$0.has_option(option: .callback)}) }
	
	public var representedPyType: RepresentedPyPType = .class
    
    public init(_ name: String) {
        _title = name
        functions = []
        decorators = []
        properties = []
        singleton = false
        swift_object_mode = true
        
    }
    
    public required init?<S>(_ node: S) where S : SyntaxProtocol {
        _title = ""
		
        functions = []
        decorators = []
        properties = []
        singleton = false
        swift_object_mode = true
    }
    
    init(fromAst cls: PyAst_Class) throws {
        print("############ \(cls) - \(cls.name) ############")
		if cls.name.contains(".") {
			let split = cls.name.split(separator: ".", maxSplits: 1)
			_title = .init(split[1])
			extension_title = .init(split[0])
		} else {
			_title = cls.name
		}
        
        functions = []
        decorators = []
        properties = []
        singleton = false
        swift_object_mode = true
        
        
        cls.decorator_list.forEach { deco in
            switch deco.name {
            case "wrapper":
                if let deco = deco as? PyAst_Call {
                    deco.keywords.forEach { kw in
                        switch WrapperClassOptions(rawValue: kw.name) {
                        case .py_init:
                            ignore_init = !(Bool(kw.value.name) ?? false)
                        case .debug_mode:
                            debug_mode = (Bool(kw.value.name) ?? false)
                        case .type:
                            wrapper_target_type = .init(rawValue: kw.value.name) ?? ._class
                        case .target:
                            alternate_title = kw.value.name
                        case .service_mode:
                            break
                        case .new:
                            new_class = (Bool(kw.value.name) ?? false)
                        case .unretained:
                            unretained = (Bool(kw.value.name) ?? false)
						case .pytype:
							if let rpType = RepresentedPyPType(rawValue: kw.value.name) {
								representedPyType = rpType
							}
                        default: break
                        }
                        
                    }
                }
			case "bases":
				if let deco = deco as? PyAst_Call {
					
					bases.append(contentsOf: deco.args.compactMap({WrapClassBase(rawValue: $0.name)}))
					print(bases)
//					deco.keywords.forEach { kw in
//
//					}
					
				}
            case "combine": if let deco = deco as? PyAst_Call {
                deco.keywords.forEach { kw in
                    switch kw.name {
                    default: break
                    }
                }
				
            }
			
            default: break
            }
        }
        
        //bases = cls.bases.compactMap({.init(rawValue: $0.name)})
        
        for element in cls.body {
            switch element.type {
            case .ClassDef:
                guard element.name == "Callbacks" else { continue }
                if let callback_cls = element as? PyAst_Class {
                    handleClassDef(callback_cls)
                }
                
            case .FunctionDef:
                //let f = element as! PyAst_Function
                handleFunctionDefs(element as! PyAst_Function)
                
            case .Assign:
                guard
                    let assign = element as? PyAst_Assign,
                    let target = assign.targets.first
                else { fatalError() }
                handleProperties(assign: assign, target: target)
			case .AnnAssign:
				guard
					let assign = element as? PyAst_AnnAssign
					
				else { throw WrapClassError.AnnAssignType(element.name)}
				let target = assign.annotation.name
				if let ptype = PythonType(rawValue: target) {
					properties.append(.init(name: assign.name, property_type: .GetSet, arg_type: _WrapArg.wrapArgFromType(name: element.name, type: ptype, _other_type: nil, idx: 0, options: [])))
				} else {
					properties.append(.init(name: element.name, property_type: .GetSet, arg_type: otherArg(_name: element.name, _type: .other, _other_type: target, _idx: 0, _options: [])))
				}
				//throw WrapClassError.AnnAssignType(element.name)
				//fatalError(<#T##message: String##String#>)
            default:
                //fatalError()
                continue
            }
        
        }
        callbacks_count = functions.filter({$0.has_option(option: .callback)}).count
        functions.forEach{[weak self] in $0.wrap_class = self}
		
		if representedPyType == .tuple {
			init_function = .init(
				name: "init",
				_args_: [objectArg(_name: "tuple", _type: .object, _other_type: nil, _idx: 0, _options: [])],
				_return_: objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [.return_]),
				options: [],
				wrap_class: self
			)
		}
    }
    
    

//    func handleDecorators() {
//        let decs = decorators.map({$0.type})
//        if decs.contains("EventDispatch") {self.dispatch_mode = true}
//        if let dis_dec = decorators.filter({$0.type=="EventDispatch"}).first {
//            dispatch_events = (dis_dec.dict[0]["events"] as! [String])
//        }
//        if decs.contains("swift_object") { swift_object_mode = true }
//
//        for function in self.functions {if function.has_option(option: .swift_func) {self.has_swift_functions = true; break}}
//
//    }
    
    var callback_functions: [WrapFunction] { functions.filter {$0.has_option(option: .callback)}  }
    
    func handleClassDef(_ callback_cls: PyAst_Class) {
        for deco in callback_cls.decorator_list {
            switch deco.name {
            case "protocols":
                if let pcall = deco as? PyAst_Call {
                    callback_protocols.append(contentsOf: pcall.args.map(\.name))
                }
            default: continue
            }
        }
        for cb in callback_cls.body.compactMap({$0 as? PyAst_Function}) {
            let f = WrapFunction(fromAst: cb, callback: true)
            f.wrap_class = self
            functions.append(f)
            callbacks_count += 1
        }
    }
    
    func handleFunctionDefs(_ element: PyAst_Function) {
        let f = element
        switch PySequenceFunctions(rawValue: element.name) {
        case .__getitem__:
            let return_type: PythonType =  .init(rawValue: f.returns?.name ?? "" ) ?? .object
            pySequenceMethods.append(.__getitem__(key: .int, returns: return_type))
            return
        case .__setitem__:
            
            let args = f.args.filter({$0.name != "self"})
            let value_type: PythonType = .init(rawValue: args.first?.annotation?.name ?? "" ) ?? .object
            pySequenceMethods.append(.__setitem__(key: .int, value: value_type ))
            return
        default: break
        }
        let t = PyClassFunctions(rawValue: element.name)
        switch t {
        case .__call__:
            pyClassMehthods.append(.__call__)
        case .__init__:
			if representedPyType == .class {
				let init_f = WrapFunction(fromAst: element)
				init_function = init_f
			}
        case .__buffer__:
            pyClassMehthods.append(.__buffer__)
            
        case .__str__:
            pyClassMehthods.append(.__str__)
            
        case .__repr__:
            pyClassMehthods.append(.__repr__)
        case .__hash__:
            pyClassMehthods.append(.__hash__)
            
        default:
            functions.append(.init(fromAst: element))
        }
    }
    
    func handleProperties(assign: PyAst_Assign, target: PyAstObject) {
        if let value = assign.value {
            switch value {
            case let call as PyAst_Call:
                
                if ["Property", "property"].contains(call.name) {
                    handleProperties(call: call, target: target)
                }
            case _ as PyAst_Name:
                fatalError()
            default: fatalError()
            }
        }
	}
	
	enum CodingKeys: CodingKey {
		case title
		case alternate_title
		case functions
		case decorators
		case properties
		case singleton
		case new_class
		case bases
		case wrapper_target_type
		case callbacks_count
		case pointer_compare_strings
		case pointer_compare_dict
		case dispatch_mode
		case has_swift_functions
		case dispatch_events
		case class_vars
		case class_ext_options
		case pySequenceMethods
		case pyClassMehthods
		case pyNumericMethods
		case pyAsyncMethods
		case callback_protocols
		case swift_object_mode
		case init_function
		case ignore_init
		case debug_mode
		case unretained
		case representedPyType
	}
	
	public required init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		_title = try c.decode(String.self, forKey: .title)
		decorators = try c.decode([WrapClassDecorator].self, forKey: .decorators)
		properties = [] //try c.decode([WrapClassProperty].self, forKey: .properties)
		
		functions = []
		
		singleton = false
	}
	
	public func encode(to encoder: Encoder) throws {
		
	}
}



public class WrapClassDecoratorBase: Codable {
    let type: String
    let args: [String]
}

public class WrapClassDecorator: WrapClassDecoratorBase {
    var dict: [[String:Any]] = []
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        dict.append(contentsOf: args.map({JSON(parseJSON: $0).dictionaryObject!}))
    }
}
