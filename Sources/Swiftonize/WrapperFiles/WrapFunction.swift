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

public class WrapFunction: Codable {
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
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.name) {
            name = try! container.decode(String.self, forKey: .name)
        } else {
            name = ""
        }
   
        if container.contains(.args) {
            let container_args = try container.decode([WrapArg].self, forKey: .args)
            args = container_args
            //_args_ = handleWrapArgTypes(args: container_args)
            _args_ = try container.decode([WrapArgsContainer].self, forKey: .args).map{$0.arg}
        } else {
            args = []
            _args_ = []
        }
        //try WrapArgsContainer.init(from: container.superDecoder(forKey: .args))
        
        if container.contains(.returns) {
            returns = try! container.decode(WrapArg.self, forKey: .returns)
            _return_ = try container.decode(WrapArgsContainer.self, forKey: .returns).arg
        } else {
            returns = WrapArg(name: "", type: .void, other_type: "", idx: 0, arg_options: [.return_])
            _return_ = objectArg()
        }
        if container.contains(.call_class) {
            call_class = try! container.decode(String.self, forKey: .call_class)
        } else {
            call_class = nil
        }
        if container.contains(.call_target) {
            call_target = try! container.decode(String.self, forKey: .call_target)
        } else {
            call_target = nil
        }
        
        
        if container.contains(.options) {
            options = try! container.decode([WrapFunctionOption].self, forKey: .options)
        } else {
            options = []
        }
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
    
    func set_args_cls(cls: WrapClass) {
        for arg in args {
            arg.cls = cls
        }
    }
    
    func get_callArg(name: String) -> WrapArg! {
        for arg in args {
            if arg.name == name {
                return arg
            }
        }
        return nil
    }
    
    func _get_callArg(name: String) -> WrapArgProtocol! {
        for arg in _args_ {
            if arg.name == name {
                return arg
            }
        }
        return nil
    }
    
    func call_args(cython_callback: Bool = false) -> [String] {
        var call_class = ""
        var call_target = ""
        if self.call_class != nil {call_class = self.call_class}
        if self.call_target != nil {call_target = self.call_target}
        var filtered_args = args
        if !wrap_class.singleton {
            if let first = filtered_args.first {
                if first.type == .CythonClass {
                    filtered_args.remove(at: 0)
                }
            }
        }
        let _args = filtered_args.filter{arg -> Bool in
            arg.name != call_target && arg.name != call_class
        }
        return _args.map {
            $0.convertPythonCallArg
        }.filter({$0 != ""})
    }
    
    var call_args_cython: [String] {
        var call_class = ""
        var call_target = ""
        if self.call_class != nil {call_class = self.call_class}
        if self.call_target != nil {call_target = self.call_target}
        let _args = args.filter{arg -> Bool in
            arg.name != call_target && arg.name != call_class
        }
        return _args.map {
            $0.convertPythonCallArg
        }.filter({$0 != ""})
    }
    
    var send_args: [String] {
        args.map {

            var send_options: [PythonSendArgTypes] = []
            if $0.has_option(.list) {send_options.append(.list)}
            return $0.convertPythonSendArg(options: send_options)
        }.filter({$0 != ""})
    }
    
    var send_args_py: [String] {
        var send_args = args.map { arg -> String in
            var send_options: [PythonSendArgTypes] = []
            if arg.has_option(.list) {send_options.append(.list)}
            if arg.type == .other {
                if let wrap_module = wrap_module_shared {
                    if let customcstruct = wrap_module.custom_structs.first(where: { (custom) -> Bool in
                        custom.title == arg.other_type
                    }) {
                        for sub in customcstruct.sub_classes {
                            switch sub {
                            case .Codable:
                                //return "json.dumps(\(arg.name).__dict__).encode()"
                                return "[j_\(arg.name), \(arg.name)_size]"
                            }
                        }
                    }
                    if wrap_module.enumNames.contains(arg.other_type) {
                        return "\(arg.name)"//.value[0]
                    }
                    
                }
                
            }
            return arg.convertPythonSendArg(options: send_options)
        }
        
        return send_args.filter({$0 != ""})
    }
    
    func export(options: [PythonTypeConvertOptions])  -> String {
        let send_self = has_option(option: .send_self)
        let singleton = self.wrap_class!.singleton
        if options.contains(.objc) {
            var func_args = args.map({ arg in
                arg.export(options: options)!
            })
            
//            if !singleton {
//                if has_option(option: .callback) || send_self {
//                    func_args.insert("const void* _Nonnull cls", at: 0)
//                }
//                //
//            }
//            if options.contains(.header) {
//                return func_args.joined(separator: " ")
//            } else {
                return func_args.joined(separator: ", ")
//            }
        }
        
        if options.contains(.pyx_extern) {
            
            var func_args = args.map({ arg in
                arg.export(options: options)!
            })
            
            
            
//            if !singleton {
//                if has_option(option: .callback) || send_self {
//                    func_args.insert("const void* cls", at: 0)
//                }
//            }
            
            return func_args.joined(separator: ", ")

        }
        
        
        if options.contains(.swift) {
            var func_args = args.map({ arg in
                arg.export(options: options)!
            })
            
//            if !singleton {
//                if has_option(option: .callback) || send_self{
//                    if options.contains(.protocols) {
//                        func_args.insert("cls: UnsafeRawPointer", at: 0)
//                    } else {
//                        func_args.insert("_ cls: UnsafeRawPointer", at: 0)
//                    }
//                }
//            }
            
            return func_args.joined(separator: ", ")
            
        }
        
        
        
        var _args: [WrapArg]
        
        if options.contains(.py_mode) {
            _args = args
        } else {
            _args = args
        }
        let filtered_args = args.filter { arg in
            if !singleton {
                return arg.type != .CythonClass
            }
            return true
        }
        var func_args = filtered_args.map({ arg in
            return arg.export(options: options)!
        })
        
        return func_args.joined(separator: ", ")
    }
    
}




extension WrapFunction {
    func convertReturnSend(rname: String, code: String) -> String {
        let rtype = returns.type
        
        switch rtype {
        case .str:
            if returns.has_option(.list) {
                return "[rtn_val.ptr[x].decode() for x in range(rtn_val.size)]"
            }
            return "\(code).decode()"
        case .data:
            if returns.has_option(.list) {
                return "[rtn_val.ptr[x].ptr[:rtn_val.ptr[x].size] for x in range(rtn_val.size)]"
            }
            return "rtn_val.ptr[:rtn_val.size]"
        case .jsondata:
            if returns.has_option(.list) {
                return "[json.loads(rtn_val.ptr[x].ptr[:rtn_val.ptr[x].size]) for x in range(rtn_val.size)]"
            }
            return "json.loads(rtn_val.ptr[:rtn_val.size])"
        case .object:
            if returns.has_option(.list) {
                return "[(<object>rtn_val.ptr[x]) for x in range(rtn_val.size)]"
            }
            return "<object>\(code)"
        default:
            if returns.has_option(.list) {
                return "[rtn_val.ptr[x] for x in range(rtn_val.size)]"
            }
            return code
        }
    }
    
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
