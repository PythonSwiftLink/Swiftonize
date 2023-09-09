//
//  WrapClasses.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation
import SwiftyJSON
import PyAstParser
import SwiftSyntax

enum ClassPropertyType: String, Codable, CaseIterable {
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

class WrapClassProperty {
    
    
    let name: String
    let property_type: ClassPropertyType
    //let arg_type: WrapArg
    let arg_type: WrapArgProtocol
    
    
    init(name: String, property_type: ClassPropertyType, arg_type: WrapArgProtocol) {
        self.name = name
        self.property_type = property_type
        self.arg_type = arg_type
        
        //self.arg_type_new = handleWrapArgTypes(args: [arg_type]).first!
    }
    
    
}

public extension PyAst_Assign {
    
    
    
}

public class WrapClass {
    

    var _title: String
    var title: String {
        alternate_title ?? _title
    }
    var alternate_title: String?
    var functions: [WrapFunction]
    var decorators: [WrapClassDecorator]
    var properties: [WrapClassProperty]
    let singleton: Bool
    
    public var new_class = false
    
    var bases: [WrapClassBase] = []
    
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
    
    var callback_protocols: [String] = []
    
    var swift_object_mode = false
    
    var init_function: WrapFunction?
    
    var ignore_init = false
    
    var debug_mode = false
    
    var unretained = false
    
    var callbacks: [WrapFunction] { functions.filter({$0.has_option(option: .callback)}) }
    var send_functions: [WrapFunction] { functions.filter({!$0.has_option(option: .callback)}) }
    
    init(_ name: String) {
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
    
    init(fromAst cls: PyAst_Class) {
        print("############ \(cls) - \(cls.name) ############")
        _title = cls.name
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
                        default: break
                        }
                        
                    }
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
        
        bases = cls.bases.compactMap({.init(rawValue: $0.name)})
        
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
        
            default:
                //fatalError()
                continue
            }
        
        }
        callbacks_count = functions.filter({$0.has_option(option: .callback)}).count
        functions.forEach{[weak self] in $0.wrap_class = self}
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
            let init_f = WrapFunction(fromAst: element)
            init_function = init_f
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
