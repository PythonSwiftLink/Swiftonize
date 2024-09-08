//
//  WrapFunction.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation
import PySwiftCore
import PyAst

public enum WrapFunctionOption: String, CaseIterable,Codable {
    case list
    case data
    case json
    case callback
    case swift_func
    case dispatch
    case direct
    case property
    case cfunc
    case send_self
    case no_protocol
}

public enum WrapFunctionDecoratorType: String, Codable {
    case direct_arg
    case args_rename
    case args_alias
    case no_labels
    case no_protocol
    case call_target
    case func_options
	case `throws`
}

class WrapFunctionDecorator: Codable {
    let type: WrapFunctionDecoratorType
}

public class WrapFunction {
	public init(name: String, _args_: [WrapArgProtocol], _return_: WrapArgProtocol, call_class: String? = nil, call_target: String? = nil, options: [WrapFunctionOption], wrap_class: WrapClass?) {
		self.name = name
		self.args = []
		self._args_ = _args_
		self._return_ = _return_
		self.call_class = call_class
		self.call_target = call_target
		self.options = options
		self.compare_string = ""
		self.function_pointer = ""
		self.wrap_class = wrap_class
	}
	
    public let name: String
    public var args: [WrapArg]
    public var _args_: [WrapArgProtocol]
    //let returns: WrapArg
    public var _return_: WrapArgProtocol
    //let is_callback: Bool
    //let swift_func: Bool
    //let direct: Bool
	public var default_args: [String] = []
    public let call_class: String!
    public var call_target: String!
    
    public var options: [WrapFunctionOption]
	
	public var `throws` = false
    
    
    //let is_dispatch: Bool
    
    private enum CodingKeys: CodingKey {
        case name
        case args
        case returns
        //case is_callback
        //case swift_func
        case call_class
        case call_target
        //case is_dispatch
        //case direct
        case options
    }
    
    public var compare_string: String = ""
    public var function_pointer = ""
    public weak var wrap_class: WrapClass!
    
    
    public init(fromAst ast_func: PyAst_Function, callback: Bool = false) {
        
        name = ast_func.name
        args = []
        //print(ast_func,ast_func.name)
        //_args_ = ast_func.args.filter({$0.name != "self"}).enumerated().map(_buildWrapArg)
        _args_ = ast_func.args.filter({$0.name != "self"}).enumerated().map(_WrapArg.fromAst)
        
		default_args = ast_func.defaults.map(\.name)
        //_args_ = ast_func.args.enumerated().c
        
        //returns = .init(name: "", type: .void, other_type: "", idx: 0, arg_options: [.return_])
        
        //buildWrapArg(idx: 0, ast_func.r)
        
        //_return_ = objectArg(_name: "", _type: .void, _other_type: "", _idx: 0, _options: [.return_])
        //_return_ = buildWrapArgReturn( ast_func.returns )
        if let rtn = ast_func.returns {
            _return_ = _WrapArg.fromAst(index: 0, rtn)
        } else {
            _return_ = objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [.return_])
        }
        
        options = callback ? [.callback] : []
        
        call_class = nil
        //call_target = nil
        
        ast_func.decorator_list.forEach { deco in
            switch WrapFunctionDecoratorType(rawValue: deco.name) {
			case .throws:
				self.throws = true
            case .func_options:
                guard
                    let call = deco as? PyAst_Call
                else { break }
                call.keywords.enumerated().forEach { i, key in
                    switch WrapFunctionDecoratorType(rawValue: key.name) {
                    case .call_target:
                        //print(key.value)
//                        guard
//                            let dict = key.value as? PyAst_Dict,
//                            let _name = dict.values.first?.name
//                        else { break }
                        call_target = key.value.name
                    case .no_labels:
                        if let call = key.value as? PyAst_Dict {
                            
                            call.keys.enumerated().forEach { i, dkey in
                                if let index = _args_.firstIndex(where: { a in a.name == dkey.name}) {
                                    if let bool = Bool(call.values[i].name) {
                                        let _arg = _args_[index]
//                                        _args_[index].optional_name = bool ? "_ \(_arg.name)" : nil
                                        if bool {
                                            _args_[index].add_option(.no_label)
                                        }
                                        //_args_[index].optional_name = bool ? "_" : nil
                                        return
                                    }
                                    
                                    
                                }
                            }
                        } else {
                            for (i, _arg) in _args_.enumerated() {
                                
                                _args_[i].add_option(.no_label)
                            }
                        }
                    case .args_alias:
                        switch key.value {
                        case let d as PyAst_Dict:
                            d.keys.enumerated().forEach {i, dkey in
                                if let index = _args_.firstIndex(where: { a in a.name == dkey.name}) {
                                    _args_[index].optional_name = d.values[i].name
                                    _args_[index].add_option(.alias)
                                    return
                                }
                            }
                        default: fatalError()
                        }
                        guard let call = deco as? PyAst_Call else { break }
                        call.keywords.forEach { key in
                            if let index = _args_.firstIndex(where: { a in a.name == key.name}) {
                                _args_[index].optional_name = key.value.name
                                _args_[index].add_option(.alias)
                                return
                            }
                        }
                    default:
                        fatalError("[Error] func_option key <\(key.name)> is not supported")
                    }
                }
                //fatalError()
            
            case .call_target:
                guard
                    let call = deco as? PyAst_Call,
                    let _name = call.args.first?.name
                else { break }
                call_target = _name
                
            case .args_rename:
                guard let call = deco as? PyAst_Call else { break }
                call.keywords.forEach { key in
                    if let index = _args_.firstIndex(where: { a in a.name == key.name}) {
                        _args_[index].optional_name = key.value.name
                        return
                    }
                }
            case .args_alias:
                guard let call = deco as? PyAst_Call else { break }
                call.keywords.forEach { key in
                    if let index = _args_.firstIndex(where: { a in a.name == key.name}) {
                        _args_[index].optional_name = key.value.name
                        _args_[index].add_option(.alias)
                        return
                    }
                }
            case .no_labels:
                if let call = deco as? PyAst_Call {

                    call.keywords.forEach { key in
                        if let index = _args_.firstIndex(where: { a in a.name == key.name}) {
                            if let bool = Bool(key.value.name) {
                                //let _arg = _args_[index]
                                if bool {
                                    _args_[index].add_option(.no_label)
                                }
                                //_args_[index].optional_name = bool ? "_" : nil
                                return
                            }
                            
                            
                        }
                    }
                } else {
                    for (i, _arg) in _args_.enumerated() {
                        
                        _args_[i].add_option(.no_label)
                    }
                }
                
                break
                
                //fatalError()
            case .no_protocol:
                options.append(.no_protocol)
                
            default: break
            }
        }


    }
    
    init(name: String, args: [WrapArg], rtn: WrapArg!, options: [WrapFunctionOption]) {
        self.name = name
        self.args = args
        self._args_ = []//handleWrapArgTypes(args: args)
//        if rtn != nil {
//            self.returns = rtn
//        } else {
//            self.returns = WrapArg(name: "", type: .void, other_type: "", idx: 0, arg_options: [.return_])
//        }
        _return_ = objectArg()
        self.options = options
        self.call_class = nil
        self.call_target = nil
    }
    
   
    
    public func has_option(option: WrapFunctionOption) -> Bool {
        return options.contains(option)
    }
    
    public func has_options(options: [WrapFunctionOption]) -> Bool {
        var state = false
        
        for option in options {
            if self.options.contains(option) {
                state = true
            } else {
                return false
            }
            
        }
        return state
    }
    
}




public extension WrapFunction {

    
    var call_target_is_arg: Bool {
        let _args = args.map{$0.name}
        if let call_target = call_target {
            if _args.contains(call_target) {
                return true
            }
        }
        return false
        
    }

    var call_class_is_arg: Bool {
        let _args = args.map{$0.name}
        if let call_class = call_class {
            if _args.contains(call_class) {
                return true
            }
        }
        return false
    }

}
