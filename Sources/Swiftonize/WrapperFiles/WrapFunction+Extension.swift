//
//  WrapFunction+Extension.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 26/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation


public extension WrapFunction {
    
    private func generate(callableArg arg: WrapArgProtocol) -> String {

        if arg.options.contains(.optional) {
            
            return "\(arg.type.swiftType)?"
        }
        return arg.type.swiftType
    }
    
    private func generate(callable arg: WrapArgProtocol ,cls_title: String? = nil) -> String {
        guard let callable = arg as? callableArg else { fatalError() }
        let callArgs = callable.callArgs
        let pointer_args = callArgs.map(\.swiftType).joined(separator: ", ")
        let func_args = callArgs.enumerated().map{i,_ in "_arg\(i)"}.joined(separator: ", ")
        let call_args = callArgs.enumerated().map{i,_ in "_arg\(i).pyPointer"}.joined(separator: ", ")
        return """
        let \(arg.name): ((\(pointer_args)) -> Void) = { \(func_args) in
            DispatchQueue.main.withGIL {
                PyObject_Vectorcall(_\(arg.name), [\(call_args)], \(callArgs.count), nil)
            }
        }
        """.newLineTabbed
    }
    
    private func funcCallArgHandler( _ a: WrapArgProtocol) -> String {
        if let optional_name = a.optional_name {
            if optional_name.first == "_" {
                return a.type == .other ? "_\(a.name)" : a.name
            }
        }
        if a.type == .other {
            return "\(a.name): _\(a.name)"
        }
        return "\(a.name): \(a.name)"
    }
    
    func generate(PyMethod_withArgs cls_title: String?) -> String {

        let arg_extract = _args_.map { generate(extractLine: $0, many: true) }.joined(separator: "\n\t\t")
        
        let completion_handlers = _args_.compactMap { a in
            if a.type == .callable {
                return generate(callable: a)
            }
            return nil
        }.joined(separator: newLineTab)
        
        let args = _args_.map(funcCallArgHandler).joined(separator: ", ")
        var cls_call = ""
        if let cls_title = cls_title {
            cls_call = "(s.getSwiftPointer() as \(cls_title))."
        }
        let rtn_type = _return_.type
        let use_rtn = !(rtn_type == .void || rtn_type == .None)
        let result = use_rtn ? "let __result__ = " : ""
        let rtn = use_rtn ? "__result__.pyPointer" : ".PyNone"
        
        return """
        .init(withArgs: "\(name)") { s, _args_, nargs in
            do {
                guard nargs > \(_args_.count - 1), let _args_ = _args_ else { throw PythonError.call }
                \(arg_extract)
                \(completion_handlers)
                \(result)\(cls_call)\(name)(\(args))
                return \(rtn)
            }
            catch let err as PythonError {
                switch err {
                case .call: err.triggerError("wanted \(_args_.count) got \\(nargs)")
                default: err.triggerError("\(name)")
                }
                
            }
            catch let other_error {
                other_error.pyExceptionError()
            }
            return nil
        }
        """

    }
    
    private func generate(extractLine arg: WrapArgProtocol, many: Bool = false) -> String {
        
        if many {
            
            if arg.type == .callable {
                
                return "let _\(arg.name) = _args_[\(arg.idx)]"
            }
            if arg.type == .object {
                return "let \(arg.name) = _args_[\(arg.idx)]"
            }
            if arg.type == .other {
                return """
                let \(arg.name) = _args_[\(arg.idx)]
                guard PythonObject_TypeCheck(\(arg.name), \(arg.other_type)PyType.pytype) else { throw PythonError.attribute }
                let _\(arg.name) = \(arg.name).getSwiftPointer() as \(arg.other_type)
                """.replacingOccurrences(of: newLine, with: newLineTabTab)
            }
            let _arg = arg.options.contains(where: {o in o == .list || o == .tuple}) ? "[\(arg.type.swiftType)]" : arg.type.swiftType
            return "let \(arg.name) = try \(_arg)(object: _args_[\(arg.idx)])"
        }
        if arg.type == .callable {
            
            return "let _\(arg.name) = \(arg.name)"
        }
        if arg.type == .object {
            return "let \(arg.name) = \(arg.name)"
        }
        if arg.type == .other {
            return """
            guard PythonObject_TypeCheck(\(arg.name), \(arg.other_type)PyType.pytype) else { throw PythonError.attribute }
            let _\(arg.name) = \(arg.name).getSwiftPointer() as \(arg.other_type)
            """.replacingOccurrences(of: newLine, with: newLineTabTab)
        }
        let _arg = arg.options.contains(where: {o in o == .list || o == .tuple}) ? "[\(arg.type.swiftType)]" : arg.type.swiftType
        return "let \(arg.name) = try \(_arg)(object: \(arg.name))"
        
    }
    

    
    func generate(PyMethod_oneArg cls_title: String?) -> String {
        let arg = _args_[0]
        let is_object = arg.type == .object
        let is_other = arg.type == .other
        var _arg = funcCallArgHandler(arg)
        let arg_extract = arg.type != .object ? generate(extractLine: arg) : ""
       // let arg_extract = generate(extractLine: arg, many: false)

        
        var cls_call = ""
        if let cls_title = cls_title {
            cls_call = "(s.getSwiftPointer() as \(cls_title))."
        }
        let rtn_type = _return_.type
        let use_rtn = !(rtn_type == .void || rtn_type == .None)
        let result = use_rtn ? "let __result__ = " : ""
        let rtn = use_rtn ? "__result__.pyPointer" : ".PyNone"
        return """
        .init(oneArg: "\(name)") { s, \(arg.name) in
            do {
                \(arg_extract)
                \(result)\(cls_call)\(name)(\(_arg))
                return \(rtn)
            }
            catch let err as PythonError {
                err.triggerError("\(name)")
            }
            catch let other_error {
                other_error.pyExceptionError()
            }
            return nil
        }
        """
    }
    
    
    func generate(PyMethod_noArgs cls_title: String?) -> String {
        var cls_call = ""
        if let cls_title = cls_title {
            cls_call = "(s.getSwiftPointer() as \(cls_title))."
        }
        let rtn_type = _return_.type
        let use_rtn = !(rtn_type == .void || rtn_type == .None)
        let result = use_rtn ? "let __result__ = " : ""
        let rtn = use_rtn ? "__result__.pyPointer" : ".PyNone"
        return """
        .init(noArgs: "\(name)") { s, arg in
            \(result)\(cls_call)\(name)()
            return \(rtn)
        }
        """
    }
}
