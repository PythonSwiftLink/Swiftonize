//
//  WrapClass+Extensions.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 26/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import WrapContainers


public extension WrapClass {
    
    
    //var getSwiftPointer: String { "(s.getSwiftPointer() as \(title))" }
    var getSwiftPointer: String { "s?.get\(title)Pointer()" }
    
    
    
    
//    var swift_string: String {
//        """
//        
//        //
//        // \(title)
//        //
//        \(if: wrapper_target_type == ._class,
//        """
//        
//        fileprivate func set\(title)Pointer(_ self: PyPointer?  ,_ target: \(title)) {
//            PySwiftObject_Cast(self).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
//        }
//        
//        extension PySwiftObjectPointer {
//            //            fileprivate func getSwiftPointer() -> \(title) {
//            //                return Unmanaged.fromOpaque(
//            //                    self!.pointee.swift_ptr
//            //                ).takeUnretainedValue()
//            //            }
//            fileprivate func get\(title)Pointer() -> \(title) {
//                return Unmanaged.fromOpaque(
//                    self!.pointee.swift_ptr
//                ).takeUnretainedValue()
//            }
//        }
//        
//        extension PythonPointer {
//            //fileprivate func getSwiftPointer() -> \(title) {
//            //    return Unmanaged.fromOpaque(
//            //        PySwiftObject_Cast(self).pointee.swift_ptr
//            //    ).takeUnretainedValue()
//            //}
//            fileprivate func get\(title)Pointer() -> \(title) {
//                //return Unmanaged.fromOpaque(
//                //    PySwiftObject_Cast(self).pointee.swift_ptr
//                //).takeUnretainedValue()
//                guard
//                    let cast = unsafeBitCast(self, to: PySwiftObjectPointer.self), let swift_ptr = cast.pointee.swift_ptr
//                else { fatalError() }
//                return Unmanaged.fromOpaque(
//                    swift_ptr
//                ).takeUnretainedValue()
//            }
//        }
//        
//        """,
//        """
//        fileprivate func set\(title)Pointer(_ self: PyPointer?  ,_ target: \(title)) {
//            let ptr: UnsafeMutablePointer<\(title)> = .allocate(capacity: 1)
//            ptr.pointee = target
//            PySwiftObject_Cast(self).pointee.swift_ptr = .init(ptr)
//        }
//        extension PythonPointer {
//            fileprivate func getSwiftPointer(_ target: inout \(title))  {
//                let ptr = PySwiftObject_Cast(self).pointee.swift_ptr!
//                target = ptr.assumingMemoryBound(to: \(title).self)
//            }
//        }
//        """
//        )
//        \(PyGetSets)
//        
//        \(PyMethodDef_Output)
//        
//        \(PySequenceMethods_Output)
//        
//        \(PyBufferProcsHandler_Output)
//        
//        \(MainFunctions)
//        
//        
//        let \(title)PyType = SwiftPyType(
//            name: "\(_title)",
//            functions: \(title)_PyFunctions,
//            methods: \(if: functions.filter({!$0.has_option(option: .callback)}).isEmpty, "nil", "\(title)_PyMethods"),
//            getsets: \(if: properties.isEmpty && functions.first(where: {$0.has_option(option: .callback)}) == nil, "nil", "\(title)_PyGetSets"),
//            sequence: \(if: pySequenceMethods.isEmpty, "nil" , "\(title)_PySequenceMethods" ),
//            buffer: \(if: pyClassMehthods.contains(.__buffer__), "\(title)_PyBuffer", "nil")
//        )
//        
//        
//        
//        // Swift Init
//        func _create_py\(title)(_ data: \(title)) -> PythonObject {
//            let new = PySwiftObject_New(\(title)PyType.pytype)
//            //setSwiftPointer(new, data)
//            set\(title)Pointer(new, data)
//            return .init(ptr: new, from_getter: true)
//        }
//        func create_py\(title)(_ data: \(title)) -> PyPointer {
//            let new = PySwiftObject_New(\(title)PyType.pytype)
//            //setSwiftPointer(new, data)
//            set\(title)Pointer(new, data)
//            return new!
//        }
//        \(if: callbacks_count != 0, pyCallbackClass)
//        \(_pyProtocol)
//        """
//    }
    
    
    private var PyBufferProcs: String {
        return """
        let Whatever_Buffer = PyBufferProcsHandler(
            getBuffer: { s, buf, flags in
                if buf == nil {
                }
                var pybuf = Py_buffer()
                let __result__ = \(getSwiftPointer).__buffer__
                PyBuffer_FillInfo(&pybuf, nil, buffer, size , 0, PyBUF_WRITE)
            },
            releaseBuffer: { s, buf in
            
            }
        )
        """
    }
    
    private var PyBufferProcsHandler_Output: String {
        guard pyClassMehthods.contains(.__buffer__) else { return "" }
        """
        if let cb = UnPackPySwiftObject(with: s, as: CameraBase.self).py_callback { return cb._pycall.xINCREF }
        """
        return """
        let \(title)_PyBuffer = PyBufferProcsHandler(
            _getBuffer: { s, buf, flags in
                if let buf = buf {
                    let _s = unsafeBitCast(s, to: PyPointer.self)
                    let result = UnPackPySwiftObject(with: s, as: \(title).self).__buffer__(s: _s, buffer: buf)
                    if result != -1 {
                        _s.incref()
                    }
                    return result
                }
                PyErr_SetString(PyExc_ValueError, "view in getbuffer is nil")
                return -1
                
            },
            _releaseBuffer: { s, buf in
                
            }
        )
        """
    }
    
    
    
    private var PySequenceMethods_Output: String {
        if pySequenceMethods.isEmpty { return "" }
        
        var length = "length: nil"
        var get_item = "get_item: nil"
        var set_item = "set_item: nil"
        
        for m in pySequenceMethods {
            switch m {
                
            case .__len__:
                length = """
                length: { s in
                    return \(getSwiftPointer).__len__()
                }
                """.addTabs()
            case .__getitem__(key: _, returns: let rtn):
                get_item = """
                get_item: { s, idx in
                    UnPackPySwiftObject(with: s, as: \(title).self).__getitem__(idx: idx)\(if: rtn != .object, ".pyPointer")
                }
                """.addTabs()
//                get_item = """
//                get_item: { s, idx in
//                    do {
//                        //return try \(getSwiftPointer).__getitem__(idx: idx )\(if: rtn != .object, ".pyPointer")
//                        guard let s = s else { throw PythonError.index }
//                        return try UnPackPyPointer(with: \(title)PyType.pytype, from: s, as: \(title).self).__getitem__(idx: idx )\(if: rtn != .object, ".pyPointer")
//                    }
//                    catch let err as PythonError {
//                        switch err {
//                        case .call: err.triggerError("__getitem__")
//                        default: err.triggerError("note")
//                        }
//                    }
//                    catch let other_error {
//                        other_error.pyExceptionError()
//                    }
//                    return nil
//                }
//                """.addTabs()
                
            case .__setitem__(key: _, value: let value):
                
                let set_var = value == .object ? "" : "let item = try \(value.swiftType)(object: item)"
                
                set_item = """
                set_item: { s, idx, item in
                    do {
                        \(set_var)
                        try \(getSwiftPointer).__setitem__(idx: idx, newValue: item )
                        return 0
                    }
                
                    catch let err as PythonError {
                        switch err {
                        case .call: err.triggerError("__getitem__")
                        default: err.triggerError("note")
                        }
                    }
                    catch let other_error {
                        other_error.pyExceptionError()
                    }
                    return 1
                }
                """.addTabs()
                
            case .__delitem__(key: _):
                continue
            case .__missing__:
                continue
            case .__reversed__:
                continue
            case .__contains__:
                continue
            }
        }
        
        return """
        let \(title)_PySequenceMethods = PySequenceMethodsHandler(methods: .init(
            \(length),
            concat: nil,
            repeat_: nil,
            \(get_item),
            \(set_item),
            contains: nil,
            inplace_concat: nil,
            inplace_repeat: nil
            )
        )
        """
        /*
         let seq = PySequenceMethodsHandler(methods: .init(
         length: { s in
         return \(title).__len__()
         },
         concat: { lhs, rhs in
         return .PyNone
         },
         repeat_: { s, count in
         return .PyNone
         },
         get_item: { s, idx in
         return \(title).__getitem__()
         },
         set_item: { s, idx, item in
         return \(title).__setitem__()
         },
         contains: { s, o in
         return 1
         },
         inplace_concat: { lhs, rhs in
         return .PyNone
         },
         inplace_repeat: { s, count in
         return .PyNone
         }
         )
         )
         */
    }
    private var _pyProtocol: String {
        pyProtocol?.formatted().description ?? ""
    }
    
    var pyProtocol: ProtocolDeclSyntax? {
        
        let _user_functions = functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .no_protocol)})
        let clsMethods = pyClassMehthods.filter({$0 != .__init__})
        if  !(callbacks_count == 0 && !new_class) && _user_functions.isEmpty &&
                clsMethods.isEmpty && pySequenceMethods.isEmpty && init_function == nil { return nil }
        
        let protocolList = MemberDeclListSyntax {
            
            //.init {
                for f in _user_functions {
                    f.function_header
                }
                for f in self.pySequenceMethods {
                    f.function_header
                }
            for f in self.pyClassMehthods {
                f.protocol_decl
            }
            //}
        }
		let _protocol = ProtocolDeclSyntax(
			modifiers: [.init(name: .keyword(.public))],
			protocolKeyword: .keyword(.protocol),
			name: .identifier("\(title)_PyProtocol")) {
				protocolList
			}
//        let _protocol = ProtocolDeclSyntax(
//			modifiers: [.init(name: .keyword(.public))],
//			protocolKeyword: .keyword(.protocol),
//            identifier: .identifier("\(title)_PyProtocol"),
//			members: protocolList//.init(members: protocolList)
//        )
        return _protocol
    }
    
//    private var __pyProtocol: String {
//        let _user_functions = functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .no_protocol)})
//        let clsMethods = pyClassMehthods.filter({$0 != .__init__})
//        if  !(callbacks_count == 0 && !new_class) && _user_functions.isEmpty &&
//            clsMethods.isEmpty && pySequenceMethods.isEmpty && init_function == nil { return "" }
////        print("\(title) pyProtocol:", !(callbacks_count == 0 && !new_class), callbacks_count, _user_functions.count, clsMethods.count, pySequenceMethods.count, init_function)
//        
//        var _init_function = ""
//        
//        if let _init = init_function {
//            let init_args = _init._args_.map({ a in a.swift_protocol_arg }).joined(separator: ", ")
//            _init_function = "init(\(init_args))"
//        }
//        
//        let user_functions = _user_functions.map { function -> String in
//            let rtype = function._return_.type
//            let ertn = (function._return_ as? PyCallbackExtactable)?.argType ?? rtype.__swiftType__
//            let swift_return = "\(if: rtype != .void && rtype != .None, "-> \(function._return_)", "")"
//            let protocol_args = function._args_.map{$0.swift_protocol_arg}.joined(separator: ", ")
//            return """
//            func \(function.name)(\(protocol_args )) \(swift_return) // func 
//            """
//        }.joined(separator: newLineTab)
//        
//        let pyseq_functions = pySequenceMethods.map(\.protocol_string).joined(separator: newLineTab)
//        
//        let __funcs__ = clsMethods.map{ f in
//            wrapper_target_type == ._class ? f.protocol_string : "mutating \(f.protocol_string)"
//        }.joined(separator: newLineTab)
//        
//        let callbacks = callbacks_count > 0 && !new_class ? "var py_callback: \(title)PyCallback? { get set }" : ""
//        
//        
//            
//        
//        return """
//        // Protocol to make target class match the functions in wrapper file
//        protocol \(title)_PyProtocol {
//        
//            \(_init_function)
//            \(user_functions)
//            \(pyseq_functions)
//            \(__funcs__)
//            \(callbacks)
//        }
//        """
//    }
//    
    
    
    
    
    private var MainFunctions: String {
        var __repr__ = "nil"
        var __str__  = "nil"
        var __hash__ = "nil"
        //var __init__ = "nil"
        
        
        for f in pyClassMehthods {
            switch f {
            case .__repr__:
                __repr__ = """
                { s in \(getSwiftPointer).__repr__().withCString(PyUnicode_FromString) }
                """.newLineTabbed
            case .__str__:
                __str__ = """
                { s in \(getSwiftPointer).__str__().withCString(PyUnicode_FromString) }
                """.newLineTabbed
            case .__hash__:
                __hash__ = """
                { s in \(getSwiftPointer).__hash__() }
                """.newLineTabbed
            default: continue
            }
        }
        var init_vars = ""
        var kw_extract = ""
        if let _init = init_function {
            let args = _init._args_
            init_vars = args.map { a in
                "var \(a.name): \(a.swiftType)"//\(if: a.type != .object, "?") = nil"
            }.joined(separator: newLineTab)
            
        }
        let init_nargs = init_function?._args_.count ?? 0
        var init_args = [String]()
        var init_lines_kw = [String]()
        var init_lines_kw_post = [String]()
        var init_lines = [String]()
        
        if let init_func = init_function {
            init_args = init_func._args_.map {a in "\(a.name): \(a.name)"}
            init_lines_kw = init_func._args_.map { a in
                return """
                let _\(a.name) = PyDict_GetItem(kw, "\(a.name)")
                """
            }
            init_lines_kw_post = init_func._args_.map { a in
                "\(a.name) = try .init(object: _\(a.name))"
            }
            init_lines = init_func._args_.map { a in
                let is_object = a.type == .object
                //                let extract = "PyTuple_GetItem(args, \(a.idx))"
                //                return "let \(a.name): \(a.type.swiftType) = \(is_object ? extract : "init(\(extract)")"
                return """
                if nargs > \(a.idx) {
                    \(a.name) = try PyTuple_GetItem(_args_, \(a.idx))
                } else {
                    if let _\(a.name) = PyDict_GetItem(kw, "\(a.name)") {
                        \(if: a.type == .object, "\(a.name) = _\(a.name)", "\(a.name) = try \(a.swiftType)(object: _\(a.name))")
                    } else { throw PythonError.attribute }
                }
                """.newLineTabbed.addTabs()
//                return """
//                if nargs > \(a.idx) {
//                    \(if: a.type == .object, "\(a.name) = PyTuple_GetItem(_args_, \(a.idx))", "\(a.name) = try \(a.swiftType)(object: PyTuple_GetItem(_args_, \(a.idx)))")
//                } else {
//                    if let _\(a.name) = PyDict_GetItem(kw, "\(a.name)") {
//                        \(if: a.type == .object, "\(a.name) = _\(a.name)", "\(a.name) = try \(a.swiftType)(object: _\(a.name))")
//                    } else { throw PythonError.attribute }
//                }
//                """.newLineTabbed.addTabs()
            }
        }
        
        let init_call: String
        
        if ignore_init {
            init_call = """
            PyErr_SetString(PyExc_NotImplementedError,"\(title) can only be inited from swift")
            return -1
            """
        } else {
            let init_call_args = (init_function?._args_ ?? []).filter({
                $0.options.contains(.optional) || $0.type == .object
            })
            let call_args = init_call_args.count > 0 ? ", \(init_call_args.filter({$0 is objectArg}).map { "let \($0.name) = \($0.name)" }.joined(separator: ", "))" : ""
            
            init_call = {
                if !new_class { return """
                    if let this = s {
                        set\(title)Pointer(this, \(title)(\(init_args.joined(separator: ", "))) )
                        return 0
                    }
                    """
                } else { return """
                    if let this = s {
                        set\(title)Pointer(this, \(title)(callback: callback))
                        return 0
                    }
                    """
                }
            }()
        }
        
        let __init__ = """
            { s, _args_, kw -> Int32 in
            
            \(if: debug_mode, "print(\"Py_Init \(title)\")")
            \(if: !(init_function?._args_.isEmpty ?? true) && !ignore_init, """
            
            do {
                \(init_vars)
                let nkwargs = (kw == nil) ? 0 : PyDict_Size(kw)
                if nkwargs >= \(init_nargs) {
                    guard
                        \(init_lines_kw.joined(separator: ",\n\t\t"))
                        
                    else {
                        PyErr_SetString(PyExc_IndexError, "args missing needed \(init_nargs)")
                        return -1
                    }
                    \(init_lines_kw_post.joined(separator: newLineTabTab))
                } else {
                    let nargs = PyTuple_Size(_args_)
                
                    guard nkwargs + nargs >= \(init_nargs) else {
                        PyErr_SetString(PyExc_IndexError, "args missing needed \(init_nargs)")
                        return -1
                    }
                    \(init_lines.joined(separator: newLineTab))
                }
                \(init_call.newLineTabbed)
            }
            catch let err {
            
            }
            """.addTabs(),
            init_call.newLineTabbed.addTabs()
            )
            \(if: !self.ignore_init, "return 1")
        }
        """.addTabs()
        
        let __dealloc__ = """
        { s in
            \(if: debug_mode, "print(\"\(title) dealloc\", s)")
            //s.releaseSwiftPointer(\(title).self)
            \(if: wrapper_target_type == ._class,
            """
            if let ptr = PySwiftObject_Cast(s).pointee.swift_ptr {
                    Unmanaged<\(title)>.fromOpaque(ptr).release()
                }
            """,
            """
            if let ptr = PySwiftObject_Cast(s).pointee.swift_ptr {
                    ptr.deallocate()
                }
            """
            )
        }
        """.newLineTabbed
        
        let __new__ = """
        { type, args, kw -> PyPointer? in
            \(if: debug_mode, "print(\"\(title) New\")")
            return PySwiftObject_New(type)
        }
        """.newLineTabbed
        
        return """
        fileprivate func \(title)_Py_Call(self: PythonPointer?, args: PythonPointer?, keys: PythonPointer?) -> PythonPointer? {
            print("\(title) call self", self ?? "nil")
            return .None
        }
        
        fileprivate let \(title)_PyFunctions = PyTypeFunctions(
            tp_init: \(__init__),
            tp_new: \(__new__),
            tp_dealloc: \(__dealloc__),
            tp_getattr: nil, // will overwrite the other GetSets if not nil,
            tp_setattr: nil, // will overwrite the other GetSets if not nil,
            tp_as_number: nil,
            tp_as_sequence: nil,
            tp_call: \(title)_Py_Call,
            tp_str: \(__str__),
            tp_repr: \(__repr__)//,
            //tp_hash: \(__hash__),
            //tp_as_buffer: nil
        )
                
        """
    }
    
}
