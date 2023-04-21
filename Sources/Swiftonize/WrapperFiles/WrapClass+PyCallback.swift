//
//  File.swift
//  
//
//  Created by MusicMaker on 08/04/2023.
//

import Foundation
import PythonSwiftCore
import PythonLib

class PythonCall {
    
    weak var _function: WrapFunction?
    var function: WrapFunction { _function! }
    var wrap_class: WrapClass { (_function?.wrap_class)! }
    var _return_: WrapArgProtocol { function._return_ }
    
    var name: String {
        if let function = _function {
            return function.name
        }
        return "py_function"
    }
    
    
    init(function: WrapFunction) {
        _function = function
    }
    
    var converted_args: [WrapArgProtocol] { function._args_.filter {!($0 is objectArg)} }
    
    private var pre_converted_args: String {
        converted_args.map({ a in
            guard let arg = a as? PyCallbackExtactable else { fatalError("\(a.name): \( a.type.rawValue)")}
            return "let _\(a.name): PyPointer? = " + (arg.cb_extractLine(many: converted_args.count > 1, for: wrap_class.getSwiftPointer) ?? "")
        }).joined(separator: newLine)
    }
    
    var convert_result: String {
        switch function._return_.type {
        case .void, .None:
            return ""
        default: return """
            """
        }
    }
    
    var filtered_cb_arg_names: [String] {
        function._args_.filter{ a -> Bool in
            if function.call_class_is_arg { if a.name == function.call_class { return false } }
            if function.call_target_is_arg { if a.name == function.call_target { return false } }
            return true
        }.map{a -> String in
            if a.other_type == "Error" { return "_\(a.name)"}
            if a.type == .object { return a.name }
            return "_\(a.name)"
        }
    }
    
    private var callback_func_args: String {
        function._args_.map({ a in
            if let extract = a as? PyCallbackExtactable {
                return extract.function_arg
            }
            if a.options.contains(.alias) {
                return "\(a.optional_name ?? "") \(a.swift_callback_func_arg)"
            }
            return a.swift_callback_func_arg
        }).joined(separator: ", ")
    }
    
    var decref_converted_args: String {
        """
        \(function._args_
        .filter({$0.decref_needed})
        .map({"Py_DecRef( _\($0.name) )"})
        .joined(separator: newLineTab))
        """
    }
    
    private var return_string: String { "let \(name)_result: PyPointer? = " }
    
    private var py_call: String {
        let _args = filtered_cb_arg_names.joined(separator: ", ")
        let arg_count = filtered_cb_arg_names.count
        switch arg_count {
        case 0: return  "\(return_string)\(_return_.convert_return(arg: "PyObject_CallNoArgs(_\(name))"))"
        case 1: return  """
                        \(pre_converted_args)
                        
                        \(return_string)PyObject_CallOneArg(_\(name), \(_args))
                        //\(return_string)try? _\(name)( \(_args))
                        \(decref_converted_args)
                        """
        default: return """
                        \(pre_converted_args)
                        
                        //let vector_callargs: [PythonPointer?] = [\(_args)]
                        \(return_string)[\(_args)].withUnsafeBufferPointer({ PyObject_Vectorcall(_\(name), $0.baseAddress, \(arg_count), nil) })
                        if \(name)_result == nil { PyErr_Print() }
                        \(decref_converted_args)
                        
                        """.replacingOccurrences(of: newLine, with: newLineTab)
        }
    }
    
    var return_result: String {
        switch _return_.type {
        case .void, .None:
            return ""
        default: return """
            """
        }
    }
    
    var function_string: String {
   
        let func_name = function.call_target ?? function.name
        let callback_func_args = function.callback_func_args
        let use_rtn = function.use_rtn
        return """
        //@inlinable
        //\(name)
        func \(func_name)(\(callback_func_args)) \(if: use_rtn, " -> \(_return_.swiftType) "){
            
            var gil: PyGILState_STATE?
            if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }
            \(py_call)
            \(convert_result)
            defer { Py_DecRef( \(name)_result ) }
            if let gil = gil { PyGILState_Release(gil) }
            \(return_result)
        }
        """.newLineTabbed
        
    }
    
    
    
    
}
extension WrapFunction {
    var pythonCall: PythonCall { .init(function: self) }
}

fileprivate extension WrapFunction {
    
    var filtered_cb_arg_names: [String] {
        _args_.filter{ a -> Bool in
            if call_class_is_arg { if a.name == call_class { return false } }
            if call_target_is_arg { if a.name == call_target { return false } }
            return true
        }.map{a -> String in
            if a.other_type == "Error" { return "_\(a.name)"}
            if a.type == .object { return a.name }
            return "_\(a.name)"
        }
    }
    var callback_func_args: String {
        _args_.map({ a in
            if let extract = a as? PyCallbackExtactable {
                return extract.function_arg
            }
            if a.options.contains(.alias) {
                return "\(a.optional_name ?? "") \(a.swift_callback_func_arg)"
            }
            return a.swift_callback_func_arg
        }).joined(separator: ", ")
    }
    
    //var converted_args: [WrapArgProtocol] { _args_.filter { $0.type != .object || $0.other_type == nil } }
    var converted_args: [WrapArgProtocol] { _args_.filter {!($0 is objectArg)} }
    
    var _pre_converted_args: String {
        converted_args.map({ a in
            let name = a.name
            let optional = a.type == .optional
            var src: String {
                
                if a.other_type == "Error" { return "\(name)\(a.swiftType).localizedDescription" }
                return name
            }
            
            if a is optionalArg {
                
                return "let _\(name) = if \(name) == nil ? .PyNone : \(src).pyPointer"
            }
            return "let _\(name) = \(src).pyPointer"
            
            
            
        }).joined(separator: newLine)
    }
    
    var pre_converted_args: String {
        converted_args.map({ a in
            guard let arg = a as? PyCallbackExtactable else { fatalError("\(a.name): \( a.type.rawValue)")}
            return "let _\(a.name): PyPointer? = " + (arg.cb_extractLine(many: converted_args.count > 1, for: wrap_class.getSwiftPointer) ?? "")
        }).joined(separator: newLine)
    }
        
    var decref_converted_args: String {
        """
        \(_args_
        .filter({$0.decref_needed})
        .map({"Py_DecRef( _\($0.name) )"})
        .joined(separator: newLineTab))
        """
    }
    
    var use_rtn: Bool { _return_.type != .void || _return_.type != .None}
    
    var _callback_function: String {
        
        let use_rtn = use_rtn
        let return_string = "let \(name)_result: \(_return_.type == .void ? "PyPointer?" : _return_.swift_callback_return_type) = "
        
        let filtered_cb_arg_names = filtered_cb_arg_names
        
        var arg_count = filtered_cb_arg_names.count
        
        let _args = filtered_cb_arg_names.joined(separator: ", ")
        
        
        var pycall = ""
        switch arg_count {
        case 0: pycall = "\(return_string)\(_return_.convert_return(arg: "PyObject_CallNoArgs(_\(name))"))"
        case 1: pycall =    """
                            \(pre_converted_args)
                            
                            //\(return_string)PyObject_CallOneArg(_\(name), \(_args))
                            \(return_string)try? _\(name)( \(_args))
                            \(decref_converted_args)
                            """
        default: pycall =   """
                            \(pre_converted_args)
                            
                            let vector_callargs: [PythonPointer?] = [\(_args)]
                            \(return_string)vector_callargs.withUnsafeBufferPointer { PyObject_Vectorcall(_\(name), $0.baseAddress, \(arg_count), nil)
                            //let call_args: [PyConvertible] = [\(_args)]
                            //let rtn_ptr: PyPointer? = try? _\(name)._callAsFunction_(call_args)
                            }
                            \(decref_converted_args)
                            """.replacingOccurrences(of: newLine, with: newLineTab)
        }
        
        return """
            //@inlinable
            //\(name)
            func \(call_target ?? name)(\(callback_func_args)) \(if: use_rtn, " -> \(_return_.swiftType)"){
                var gil: PyGILState_STATE?
                if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }
                //print("\(name)", _Py_REFCNT(_\(name)))
                \(pycall)
                //defer { Py_DecRef( \(name)_result ) }
                if let gil = gil { PyGILState_Release(gil) }
                \(if: use_rtn, "return try ")
            }
            """.newLineTabbed
    }
    
    var callback_function: String {
        
        let use_rtn = use_rtn
        //let return_string = "let \(name)_result: \(_return_.type == .void ? "PyPointer?" : _return_.swift_callback_return_type) = "
        
        let return_string = "let \(name)_result: PyPointer? = "
        
        let filtered_cb_arg_names = filtered_cb_arg_names
        
        var arg_count = filtered_cb_arg_names.count
        
        let _args = filtered_cb_arg_names.joined(separator: ", ")
        
        var convert_result: String {
            switch _return_.type {
            case .void, .None:
                return ""
            default: return """
            """
            }
        }
        
        var return_result: String {
            switch _return_.type {
            case .void, .None:
                return ""
            default: return """
            """
            }
        }
        
        var pycall = ""
        switch arg_count {
        case 0: pycall = "\(return_string)\(_return_.convert_return(arg: "PyObject_CallNoArgs(_\(name))"))"
        case 1: pycall =    """
                            \(pre_converted_args)
                            
                            \(return_string)PyObject_CallOneArg(_\(name), \(_args))
                            //\(return_string)try? _\(name)( \(_args))
                            \(decref_converted_args)
                            """
        default: pycall =   """
                            \(pre_converted_args)
                            
                            //let vector_callargs: [PythonPointer?] = [\(_args)]
                            \(return_string)[\(_args)].withUnsafeBufferPointer({ PyObject_Vectorcall(_\(name), $0.baseAddress, \(arg_count), nil) })
                            if \(name)_result == nil { PyErr_Print() }
                            \(decref_converted_args)
                            
                            """.replacingOccurrences(of: newLine, with: newLineTab)
        }
        
        return """
            //@inlinable
            //\(name)
            func \(call_target ?? name)(\(callback_func_args)) \(if: use_rtn, " -> \(_return_.swiftType)"){
                
                var gil: PyGILState_STATE?
                if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }
                //print("\(call_target ?? name)(\(callback_func_args)) - main:",RunLoop.current == RunLoop.main)
                \(pycall)
                \(convert_result)
                defer { Py_DecRef( \(name)_result ) }
                if let gil = gil { PyGILState_Release(gil) }
                \(return_result)
            }
            """.newLineTabbed
    }
    
}

extension WrapClass {
    
    var pyCallbackClass: String {
        
        let is_nsobject = new_class
        
        let class_title = new_class ? title : "\(title)PyCallback"
        
        let cb_funcs = callback_functions
        let cls_attributes = cb_funcs.map({f in "private let _\(f.name): PythonPointer"}).joined(separator: newLineTab)
        let init_attributes = cb_funcs.map({f in "_\(f.name) = PyObject_GetAttr(callback, \"\(f.name)\")"}).joined(separator: newLineTabTab)
        
        let call_funcs = cb_funcs.map(\.pythonCall.function_string).joined(separator: newLineTab)
        
        return """
        class \(class_title)\(if: is_nsobject, ": NSObject") {
        
            public var _pycall: PythonObject
            \(cls_attributes)
        
            init(callback: PyPointer) {
                _pycall = .init(ptr: callback)
                \(init_attributes)
                \(if: is_nsobject, "super.init()")
            }
            
            \(call_funcs)
        }
        """
    }
    
}
