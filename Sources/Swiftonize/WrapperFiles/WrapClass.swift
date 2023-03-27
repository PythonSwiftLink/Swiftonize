//
//  WrapClasses.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation
import SwiftyJSON
import PyAstParser

enum ClassPropertyType: String, Codable, CaseIterable {
    case Getter
    case GetSet
    case Property
    case NumericProperty
    case StringProperty
}

class WrapClassProperty {
    
    
    let name: String
    let property_type: ClassPropertyType
    let arg_type: WrapArg
    let arg_type_new: WrapArgProtocol
    

    init(name: String, property_type: ClassPropertyType, arg_type: WrapArg) {
        self.name = name
        self.property_type = property_type
        self.arg_type = arg_type
        self.arg_type_new = handleWrapArgTypes(args: [arg_type]).first!
    }
    
    
}

public extension PyAst_Assign {
    
    
    
}

public class WrapClass {
    

    
    var title: String
    var alternate_title: String?
    var functions: [WrapFunction]
    var decorators: [WrapClassDecorator]
    var properties: [WrapClassProperty]
    let singleton: Bool
    
    var wrapper_target_type: WrapperTargetType = ._class
    
    
    var callbacks_count = 0
    var pointer_compare_strings: [String] = []
    var pointer_compare_dict: [String:[String:String]] = [:]
    var dispatch_mode = false
    var has_swift_functions = false
    var dispatch_events: [String] = []
    var class_vars: [String] = []
    //var class_ext_options: [CythonClassOptionTypes] = [.init_callstruct]
    var class_ext_options: [CythonClassOptionTypes] = [.init_callstruct]
    
    var pySequenceMethods: [PySequenceFunctions_] = []
    
    var pyClassMehthods: [PyClassFunctions] = []
    
    var pyNumericMethods: [PyNumericFunctions] = []
    
    var pyAsyncMethods: [PyAsyncFunctions] = []
    
    var swift_object_mode = false
    
    var init_function: WrapFunction?
    
    var ignore_init = false
    
    var debug_mode = false
    
    init(_ name: String) {
        title = name
        functions = []
        decorators = []
        properties = []
        singleton = false
        swift_object_mode = true
        
    }
    
    init(fromAst cls: PyAst_Class) {
        title = cls.name
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
                            title = kw.value.name
                        case .service_mode:
                            break
                        default: break
                        }
                        
                    }
                }
            default: break
            }
        }
        
        for element in cls.body {
            switch element.type {
            case .ClassDef:
                guard element.name == "Callbacks" else { continue }
                if let callback_cls = element as? PyAst_Class {
                    
                    for cb in callback_cls.body.compactMap({$0 as? PyAst_Function}) {
                        let f = WrapFunction(fromAst: cb, callback: true)
                        functions.append(f)
                        callbacks_count += 1
                    }
                    
                }
                
            case .FunctionDef:
                let f = element as! PyAst_Function
                switch PySequenceFunctions(rawValue: element.name) {
                case .__getitem__:
                    let return_type: PythonType =  .init(rawValue: f.returns?.name ?? "" ) ?? .object
                    pySequenceMethods.append(.__getitem__(key: .int, returns: return_type))
                    continue
                case .__setitem__:
             
                    let args = f.args.filter({$0.name != "self"})
                    let value_type: PythonType = .init(rawValue: args.first?.annotation?.name ?? "" ) ?? .object
                    pySequenceMethods.append(.__setitem__(key: .int, value: value_type ))
                    continue
                default: break
                }
                let t = PyClassFunctions(rawValue: element.name)
                switch t {
                case .__call__:
                    pyClassMehthods.append(.__call__)
                case .__init__:
                    let init_f = WrapFunction(fromAst: element as! PyAst_Function)
                    init_function = init_f
                case .__buffer__:
                    pyClassMehthods.append(.__buffer__)
                
                default:
                    functions.append(.init(fromAst: element as! PyAst_Function))
                }
                
            case .Assign:
                // handle property
                guard
                    let assign = element as? PyAst_Assign,
                    let target = assign.targets.first
                else { fatalError() }
                if let value = assign.value {
                    switch value {
                    case let call as PyAst_Call:
          
                        if ["Property", "property"].contains(call.name) {
                            var setter = true
                            var prop_type: ClassPropertyType = .GetSet
                            
                            if let kw = call.keywords.first(where: {$0.name == "setter"}) {
                                if let bool = Bool(kw.value.name) {
                                    setter = bool
                                }
                            }
                            prop_type = setter ? .GetSet : .Getter
                            
                 
                            var arg_type: PythonType = .init(rawValue: "") ?? .object
                            var arg_options = [WrapArgOptions]()
                            if let first = call.args.first, let t = PythonType(rawValue: first.name) {
                                
                                switch t {
                                case .list:
                                    if let list = first as? PyAst_Subscript {
                                        arg_type = .init(rawValue: list.slice.name)!
                                    }
                                    arg_options.append(.list)
                                case .optional:
                                    if let optional = first as? PyAst_Subscript {
                                        arg_type = .init(rawValue: optional.slice.name)!
                                    }
                                    arg_options.append(.optional)
                                default: arg_type = t
                                }
                                
                            }
                            
                            
                            properties.append(
                                .init(name: target.name, property_type: prop_type,
                                    arg_type: .init(
                                        name: target.name,
                                        type: arg_type,
                                        other_type: "",
                                        idx: 0,
                                        arg_options: arg_options
                                    )
                                )
                            )
                        }
                    case let _name as PyAst_Name:
                        fatalError()
                    default: fatalError()
                    }
                }
        
            default:
                //fatalError()
                continue
            }
        
        }
        callbacks_count = functions.filter({$0.has_option(option: .callback)}).count
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
    
}



class WrapClassDecoratorBase: Codable {
    let type: String
    let args: [String]
}

class WrapClassDecorator: WrapClassDecoratorBase {
    var dict: [[String:Any]] = []
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        dict.append(contentsOf: args.map({JSON(parseJSON: $0).dictionaryObject!}))
    }
}
