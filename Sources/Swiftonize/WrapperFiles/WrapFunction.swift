//
//  WrapFunction.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//

import Foundation
import PythonSwiftCore
import PyAstParser

enum WrapFunctionOption: String, CaseIterable,Codable {
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
}

enum WrapFunctionDecoratorType: String, Codable {
    case direct_arg
    case args_rename
    case no_labels
}

class WrapFunctionDecorator: Codable {
    let type: WrapFunctionDecoratorType
}

public class WrapFunction {
    let name: String
    var args: [WrapArg]
    var _args_: [WrapArgProtocol]
    let returns: WrapArg
    let _return_: WrapArgProtocol
    //let is_callback: Bool
    //let swift_func: Bool
    //let direct: Bool
    let call_class: String!
    let call_target: String!
    
    var options: [WrapFunctionOption]
    
    
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
    
    var compare_string: String = ""
    var function_pointer = ""
    var wrap_class: WrapClass!
    
    
    public init(fromAst ast_func: PyAst_Function, callback: Bool = false) {
        name = ast_func.name
        args = []
        _args_ = ast_func.args.filter({$0.name != "self"}).enumerated().map(_buildWrapArg)
        //_args_ = ast_func.args.enumerated().c
        
        returns = .init(name: "", type: .void, other_type: "", idx: 0, arg_options: [.return_])
        
        //buildWrapArg(idx: 0, ast_func.r)
        
        //_return_ = objectArg(_name: "", _type: .void, _other_type: "", _idx: 0, _options: [.return_])
        _return_ = buildWrapArgReturn( ast_func.returns )
        
        options = callback ? [.callback] : []
        
        call_class = nil
        call_target = nil
        
        ast_func.decorator_list.forEach { deco in
            switch WrapFunctionDecoratorType(rawValue: deco.name) {
                
            case .args_rename:
                guard let call = deco as? PyAst_Call else { break }
                call.keywords.forEach { key in
                    if let index = _args_.firstIndex(where: { a in a.name == key.name}) {
                        _args_[index].optional_name = key.value.name
                        return
                    }
                }
            case .no_labels:
                if let call = deco as? PyAst_Call {

                    call.keywords.forEach { key in
                        if let index = _args_.firstIndex(where: { a in a.name == key.name}) {
                            if let bool = Bool(key.value.name) {
                                let _arg = _args_[index]
                                _args_[index].optional_name = bool ? "_ \(_arg.name)" : nil
                                return
                            }
                            
                            
                        }
                    }
                } else {
                    for (i, _arg) in _args_.enumerated() {
                        
                        _args_[i].optional_name = "_ \(_arg.name)"
                    }
                }
                
                break
                
                //fatalError()
            default: break
            }
        }
        print(name, _args_.map(\.swift_protocol_arg))
    }
    
    init(name: String, args: [WrapArg], rtn: WrapArg!, options: [WrapFunctionOption]) {
        self.name = name
        self.args = args
        self._args_ = handleWrapArgTypes(args: args)
        if rtn != nil {
            self.returns = rtn
        } else {
            self.returns = WrapArg(name: "", type: .void, other_type: "", idx: 0, arg_options: [.return_])
        }
        _return_ = handleWrapArgTypes(args: [returns]).first!
        self.options = options
        self.call_class = nil
        self.call_target = nil
    }
    
   
    
    func has_option(option: WrapFunctionOption) -> Bool {
        return options.contains(option)
    }
    
    func has_options(options: [WrapFunctionOption]) -> Bool {
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




extension WrapFunction {

    
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
