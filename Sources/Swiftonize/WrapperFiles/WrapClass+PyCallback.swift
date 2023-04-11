//
//  File.swift
//  
//
//  Created by MusicMaker on 08/04/2023.
//

import Foundation
import PythonSwiftCore
import PythonLib

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
            if a.options.contains(.alias) {
                return "\(a.optional_name ?? "") \(a.swift_callback_func_arg)"
            }
            return a.swift_callback_func_arg
        }).joined(separator: ", ")
    }
    
    var converted_args: [WrapArgProtocol] { _args_.filter { $0.type != .object || $0.other_type == nil } }
    
    var pre_converted_args: String {
        converted_args.map({ a in
            let name = a.name
            let is_optional = a.options.contains(.optional)
            if a.other_type == "Error" { return "let _\(name) = \(name)\(if: is_optional, "?").localizedDescription.pyPointer ?? .PyNone" }
            return "let _\(name) = \(name).pyPointer"
            
        }).joined(separator: newLine)
    }
        
    var defer_converted_args: String {
        """
        //defer {
            \(converted_args.filter({ $0.idx != 20}).map {"""
            //pyPrint(_\($0.name))
            //print("\(name) - \($0.name)", _Py_REFCNT(_\($0.name)))
            Py_DecRef( _\($0.name) )
            """}.joined(separator: newLineTab))
        //}
        """
    }
    var use_rtn: Bool { _return_.type != .void }
    
    var callback_function: String {
        
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
                            \(defer_converted_args)
                            """
        default: pycall =   """
                            \(pre_converted_args)
                            
                            let vector_callargs: [PythonPointer?] = [\(_args)]
                            \(return_string)vector_callargs.withUnsafeBufferPointer { PyObject_Vectorcall(_\(name), $0.baseAddress, \(arg_count), nil)
                            //let call_args: [PyConvertible] = [\(_args)]
                            //let rtn_ptr: PyPointer? = try? _\(name)._callAsFunction_(call_args)
                            }
                            \(defer_converted_args)
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
}

extension WrapClass {
    
    var pyCallbackClass: String {
        
        let is_nsobject = new_class
        
        let class_title = new_class ? title : "\(title)PyCallback"
        
        let cb_funcs = callback_functions
        let cls_attributes = cb_funcs.map({f in "private let _\(f.name): PythonPointer"}).joined(separator: newLineTab)
        let init_attributes = cb_funcs.map({f in "_\(f.name) = PyObject_GetAttr(callback, \"\(f.name)\")"}).joined(separator: newLineTabTab)
        
        let call_funcs = cb_funcs.map(\.callback_function).joined(separator: newLineTab)
        
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
