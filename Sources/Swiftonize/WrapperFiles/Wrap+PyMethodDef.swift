//
//  File.swift
//  
//
//  Created by MusicMaker on 11/04/2023.
//

import Foundation
import PythonSwiftCore

fileprivate extension WrapArgProtocol {
    
    //getClassPointer(other_type)
    func extractLine(_ class_pointer: String) -> String {
        if type == .callable {
            
            return "let _\(name) = \(name)"
        }
        if type == .object {
            return "let \(name): PyPointer = \(name) //object?"
        }
        if type == .other {
            if options.contains(where: {o in o == .list || o == .tuple}) {
                //let _arg = arg.options.contains(where: {o in o == .list || o == .tuple}) ? "[\(arg.other_type)]" : arg.type.swiftType
                //    \(arg.other_type)(object: $0)
                
                return """
                let _\(name) = try \(name).map {
                    guard let this = $0, PythonObject_TypeCheck(this, \(other_type ?? "other_Type_missing")PyType.pytype) else { throw PythonError.attribute }
                    return this.\(class_pointer)
                
                }
                """.newLineTabbed.newLineTabbed
                
            }
            //let _arg = arg.options.contains(where: {o in o == .list || o == .tuple}) ? "[\(arg.type.swiftType)]" : arg.type.swiftType
            
            return """
            guard PythonObject_TypeCheck(\(name), \(other_type!)PyType.pytype) else { throw PythonError.attribute }
            let _\(name) = \(name).\(class_pointer)
            """.replacingOccurrences(of: newLine, with: newLineTabTab)
        }
        let _arg = options.contains(where: {o in o == .list || o == .tuple}) ? "[\(type.swiftType)]" : type.swiftType
        return "let _\(name) = try \(_arg)(object: \(name)) //SwiftType"
    }
    
    func extractLine(many class_pointer: String) -> String {
        
        
        
        
        if type == .callable {
            
            return "let _\(name) = _args_[\(idx)]?.xINCREF"
        }
        if type == .object {
            return "let \(name) = _args_[\(idx)]!"
        }
        if type == .other {
            if options.contains(where: {o in o == .list || o == .tuple}) {
                //let _arg = arg.options.contains(where: {o in o == .list || o == .tuple}) ? "[\(arg.other_type)]" : arg.type.swiftType
                //    \(arg.other_type)(object: $0)
                return """
                    let _\(name) = try _args_[\(idx)]?.map {
                        guard let this = $0, PythonObject_TypeCheck(this, \(other_type!)PyType.pytype) else { throw PythonError.attribute }
                        return this.\(class_pointer)
                    }
                    """.newLineTabbed.newLineTabbed
            }
            return """
                guard let \(name): PyPointer = _args_[\(idx)], PythonObject_TypeCheck(\(name), \(other_type!)PyType.pytype) else { throw PythonError.attribute }
                let _\(name) = \(name).\(class_pointer)
                """.replacingOccurrences(of: newLine, with: newLineTabTab)
        }
        let _arg = options.contains(where: {o in o == .list || o == .tuple}) ? "[\(type.swiftType)]" : type.swiftType
        return "let _\(name) = try \(_arg)(object: _args_[\(idx)]!)"
    }
    
    
}




fileprivate extension WrapFunction {
    
    func getClassPointer(_ label: String? = nil) -> String {
        if let label = label {
            return "get\(label)Pointer()"
        }
        if let title = wrap_class?.title {
            return "get\(title)Pointer()"
        }
        
        return "getSwiftPointer()"
    }
    
    func generate(callableArg arg: WrapArgProtocol) -> String {
        
        if arg.options.contains(.optional) {
            
            return "\(arg.type.swiftType)?"
        }
        return arg.type.swiftType
    }
    
    func generate(callable arg: WrapArgProtocol ,cls_title: String? = nil) -> String {
        guard let callable = arg as? callableArg else { fatalError() }
        let callArgs = callable.callArgs
        let pointer_args = callArgs.map(\.swiftType).joined(separator: ", ")
        let func_args = callArgs.enumerated().map{i,_ in "_arg\(i)"}.joined(separator: ", ")
        let call_args = callArgs.enumerated().map{i,_ in "_arg\(i).pyPointer"}.joined(separator: ", ")
        return """
        let \(arg.name): ((\(pointer_args)) -> Void) = { \(func_args) in
            DispatchQueue.main.withGIL {
                PyObject_Vectorcall(_\(arg.name), [\(call_args)], \(callArgs.count), nil)
                Py_DecRef(_\(arg.name))
        
            }
        }
        """.newLineTabbed.newLineTabbed
    }
    
    private func funcCallArgHandler( _ a: WrapArgProtocol) -> String {
        
        if a.type == .callable {
            return "\(a.name): \(a.name)"
        }
        
        if let optional_name = a.optional_name {
            if optional_name.first == "_" {
                return a.type != .object ? "_\(a.name)" : "\(a.name)"
            }
            if a.options.contains(.alias) {
                return "\(optional_name): _\(a.name)"
            }
            return "_\(optional_name)"
        }
        if a.type == .other {
            return "\(a.name): _\(a.name)"
        }
        if a.type == .object {
            if _args_.count == 1 {
                return "\(a.name): \(a.name)"
            }
        }
        
        
        //return "\(a.name): _\(a.name)"
        return "\(a.name): try pyCast(from: \(a.name) )"
        
    }
    
    
    
    private func generate(extractLine arg: WrapArgProtocol, many: Bool = false) -> String {
        
        switch arg {
        case let extract as PySendExtactable:
            return extract.extractLine(many: many, with: {_ in nil}, for: getClassPointer(arg.other_type)) ?? "// error in extract"
        default: //return arg.extractLine(many: getClassPointer(arg.other_type))
            if many {
                return arg.extractLine(many: getClassPointer(arg.other_type))
            }
            return arg.extractLine(getClassPointer(arg.other_type))
        }
        
        if arg.type == .other {
            
            switch arg {
            case let extract as PySendExtactable:
                let handler: (String?)->String? = { _t in
                    
                    return nil
                }
                return extract.extractLine(many: many, with: handler, for: getClassPointer(arg.other_type)) ?? "// error in extract"
                
            default: return arg.extractLine(many: getClassPointer(arg.other_type))
            }
        }
        if many {
            return arg.extractLine(many: getClassPointer(arg.other_type))
        }
        return arg.extractLine(getClassPointer(arg.other_type))
    }
}



extension WrapFunction {
    
    func generate(PyMethod_noArgs cls_title: String?) -> String {
        var cls_call = ""
        if let cls_title = cls_title {
            cls_call = "s.\(getClassPointer(cls_title))."
        }
        let rtn_type = _return_.type
        let use_rtn = (rtn_type != .void && rtn_type != .None)
        let result = use_rtn ? "let __result__ = " : ""
        let rtn = use_rtn ? "__result__.pyPointer" : "PythonNone"
        //print("generate(PyMethod_noArgs)",name, use_rtn, rtn_type)
        return """
        .init(noArgs: "\(name)") { s, arg in
            guard let s = s else { return PythonNone }
            \(result)\(cls_call)\(name)()
            return \(rtn)
        }
        """
    }
    
    
    func generate(PyMethod_oneArg cls_title: String?) -> String {
        let arg = _args_[0]
        let is_object = arg.type == .object
        let is_other = arg.type == .other
        var _arg: String {
//            let cast = arg is optionalArg ? "optionalPyCast" : "pyCast"
//            if arg is optionalArg {
//                return "try \(cast)(from: \(arg.name))"
//            }
//
//            return funcCallArgHandler(arg)
            generate(callArg: false, arg: arg)
        }
        //let arg_extract = arg.type != .object ? generate(extractLine: arg) : ""
        // let arg_extract = generate(extractLine: arg, many: false)
        let arg_extract = _args_.filter({($0 as? PySendExtactable)?.extract_needed ?? false}).map { generate(extractLine: $0, many: false) }.joined(separator: "\n\t\t")
        
        var cls_call = ""
        if let cls_title = cls_title {
            cls_call = "s.\(getClassPointer(cls_title))."
        }
        let fname = call_target ?? name
        let rtn_type = _return_.type
        let use_rtn = (rtn_type != .void && rtn_type != .None )
        let result = use_rtn ? "let __result__ = " : ""
        let rtn = use_rtn ? (_return_ is optionalArg ? "optionalPyPointer(__result__)" : "__result__.pyPointer") : "PythonNone"
        return """
        .init(oneArg: "\(name)") { s, \(arg.name) in
            do {
                guard let s = s, let \(arg.name) = \(arg.name) else { return PythonNone }
                \(arg_extract)
                \(result)\(cls_call)\(fname)(\(_arg))
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
    
    func generate(callArg many: Bool, arg: WrapArgProtocol) -> String {
        
        let cast = arg is optionalArg ? "optionalPyCast" : "pyCast"
        //if arg is optionalArg {
        let _name = (arg.optional_name ?? arg.name)
        let arg_name = many ? "_args_[\(arg.idx)]" : "\(_name)"
        
        
        
        if arg.optional_name?.first == "_" {
            if let send_arg = arg as? PySendExtactable {
                return "\(send_arg.function_input(many: many))"
            }
            if arg.type == .callable {
                return "\(arg.name)"
            }
            if (arg.type == .other) {
                return " _\(arg.name)"
            }
            
            
            return "try \(cast)(from: \(arg_name) )"
        }
        
        if let send_arg = arg as? PySendExtactable {
            return "\(_name): \(send_arg.function_input(many: many))"
            
        }
        
        if (arg.type == .other) {
            return "\(_name): _\(arg.name)"
        }
        if (arg.type == .callable) {
            return "\(_name): \(arg.name)"
        }
        
        return "\(_name): try \(cast)(from: \(arg_name) )"
        //}
        
       
    }
    
    func generate(PyMethod_withArgs cls_title: String?) -> String {
        
//        let arg_extract = _args_.filter({$0 is callableArg || $0 is otherArg}).map { generate(extractLine: $0, many: true) }.joined(separator: "\n\t\t")
        let arg_extract = _args_
            .filter({(($0 as? PySendExtactable)?.extract_needed ?? true)})
            .compactMap({ generate(extractLine: $0, many: true) }).joined(separator: "\n\t\t")
        //let arg_extracts = _args_.compactMap({$0 as? PySendExtactable}).map {$0.extractLine(many: true, with: {_ in nil}, for: <#T##String#>)}
        let completion_handlers = _args_.compactMap({ ($0 as? callableArg)?.cb_extractLine(many: true, for: "") }).joined(separator: newLineTab)
//        let completion_handlers = _args_.compactMap { a in
//            //if a.type == .callable {
//                //return generate(callable: a)
//
//            //}
//            if let callable = a as? callableArg {
//                return callable.cb_extractLine(many: true, for: "")
//            }
//            return nil
//        }.joined(separator: newLineTab)
        
//        let args = _args_.map({ arg in
//
//
//
//            let cast = arg is optionalArg ? "optionalPyCast" : "pyCast"
//            //if arg is optionalArg {
//            let _name = (arg.optional_name ?? arg.name)
//
//
//
//
//            if arg.optional_name?.first == "_" {
//                if let send_arg = arg as? PySendExtactable {
//                    return "\(send_arg.function_input(many: true))"
//                }
//                if arg.type == .callable {
//                    return "\(arg.name)"
//                }
//                if (arg.type == .other) {
//                    return " _\(arg.name)"
//                }
//
//
//                return "try \(cast)(from: _args_[\(arg.idx)] )"
//            }
//
//            if let send_arg = arg as? PySendExtactable {
//                return "\(_name): \(send_arg.function_input(many: true))"
//
//            }
//
//            if (arg.type == .other) {
//                return "\(_name): _\(arg.name)"
//            }
//            if (arg.type == .callable) {
//                return "\(_name): \(arg.name)"
//            }
//
//            return "\(_name): try \(cast)(from: _args_[\(arg.idx)] )"
//            //}
//
//            return funcCallArgHandler(arg)
//        }).joined(separator: ", ")
        let args = _args_.map { generate(callArg: true, arg: $0) }.joined(separator: ", ")
        var cls_call = ""
        if let cls_title = cls_title {
            cls_call = "s.\(getClassPointer(cls_title))."
        }
        let rtn_type = _return_.type
        let use_rtn = !(rtn_type == .void || rtn_type == .None)
        let result = use_rtn ? "let __result__ = " : ""
        let rtn = use_rtn ? "__result__.pyPointer" : "PythonNone"
        
        return """
        .init(withArgs: "\(name)") { s, _args_, nargs in
            do {
                guard nargs > \(_args_.count - 1), let _args_ = _args_, let s = s else { throw PythonError.call }
                \(arg_extract)
                \(completion_handlers)
                \(result)\(cls_call)\(call_target ?? name)(\(args))
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
}


extension WrapClass {
    
    var PyMethodDef_Output: String {
        let funcs = functions.filter { !$0.has_option(option: .callback) }
        if funcs.isEmpty { return ""}
        let _funcs = funcs.map { f in
            switch f._args_.count {
            case 0:
                return f.generate(PyMethod_noArgs: title)
            case 1:
                return f.generate(PyMethod_oneArg: title)
            default:
                return f.generate(PyMethod_withArgs: title)
                
            }
        }.map({$0.replacingOccurrences(of: newLine, with: newLineTab)}).joined(separator: ",\n\t")
        return """
        fileprivate let \(title)_PyMethods = PyMethodDefHandler(
            \(_funcs)
        )
        """
    }
    
}



