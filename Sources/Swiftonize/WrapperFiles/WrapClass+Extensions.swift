//
//  WrapClass+Extensions.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 26/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation


public extension WrapClass {
    
    
    var getSwiftPointer: String { "(s.getSwiftPointer() as \(title))" }
    
    var swift_string: String {
        """
        
        //
        // \(title)
        //
        \(if: wrapper_target_type == ._class,
        """
        
        fileprivate func setSwiftPointer(_ self: PyPointer  ,_ target: \(title)) {
            PySwiftObject_Cast(self).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
        }
        
        extension PySwiftObjectPointer {
            fileprivate func getSwiftPointer() -> \(title) {
                return Unmanaged.fromOpaque(
                    self!.pointee.swift_ptr
                ).takeUnretainedValue()
            }
        }
        
        extension PythonPointer {
            fileprivate func getSwiftPointer() -> \(title) {
                return Unmanaged.fromOpaque(
                    PySwiftObject_Cast(self).pointee.swift_ptr
                ).takeUnretainedValue()
            }
        }
        
        """,
        """
        fileprivate func setSwiftPointer(_ self: PyPointer  ,_ target: \(title)) {
            let ptr: UnsafeMutablePointer<\(title)> = .allocate(capacity: 1)
            ptr.pointee = target
            PySwiftObject_Cast(self).pointee.swift_ptr = .init(ptr)
        }
        extension PythonPointer {
            fileprivate func getSwiftPointer(_ target: inout \(title))  {
                let ptr = PySwiftObject_Cast(self).pointee.swift_ptr!
                target = ptr.assumingMemoryBound(to: \(title).self)
            }
        }
        """
        )
        \(PyGetSets)
        
        \(PyMethodDef_Output)
        
        \(PySequenceMethods_Output)
        
        \(PyBufferProcsHandler_Output)
        
        \(MainFunctions)
        
        
        let \(title)PyType = SwiftPyType(
            name: "\(title)",
            functions: \(title)_PyFunctions,
            methods: \(if: functions.filter({!$0.has_option(option: .callback)}).isEmpty, "nil", "\(title)_PyMethods"),
            getsets: \(if: properties.isEmpty && functions.first(where: {$0.has_option(option: .callback)}) == nil, "nil", "\(title)_PyGetSets"),
            sequence: \(if: pySequenceMethods.isEmpty, "nil" , "\(title)_PySequenceMethods" ),
            buffer: \(if: pyClassMehthods.contains(.__buffer__), "\(title)_PyBuffer", "nil")
        )
        
        
        
        // Swift Init
        func _create_py\(title)(_ data: \(title)) -> PythonObject {
            let new = PySwiftObject_New(\(title)PyType.pytype)
            setSwiftPointer(new, data)
            return .init(ptr: new, from_getter: true)
        }
        func create_py\(title)(_ data: \(title)) -> PyPointer {
            let new = PySwiftObject_New(\(title)PyType.pytype)
            setSwiftPointer(new, data)
            return new
        }
        
        \(pyProtocol)
        """
    }
    
    
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
        
        
        return """
        let \(title)_PyBuffer = PyBufferProcsHandler(
            _getBuffer: { s, buf, flags in
                if let buf = buf {
                    let _s = unsafeBitCast(s, to: PyPointer.self)
                    let result = \(getSwiftPointer).__buffer__(s: _s, buffer: buf)
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
    
    private var PyMethodDef_Output: String {
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
                    do {
                        return try (s.getSwiftPointer() as \(title)).__getitem__(idx: idx )\(if: rtn != .object, ".pyPointer")
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
                    return nil
                }
                """.addTabs()
                
            case .__setitem__(key: _, value: let value):
                
                let set_var = value == .object ? "" : "let item = try \(value.swiftType)(object: item)"
                
                set_item = """
                set_item: { s, idx, item in
                    do {
                        \(set_var)
                        try (s.getSwiftPointer() as \(title)).__setitem__(idx: idx, newValue: item )
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
    
    private var pyProtocol: String {
        
        var _init_function = ""
        
        if let _init = init_function {
            let init_args = _init._args_.map({ a in a.swift_protocol_arg }).joined(separator: ", ")
            _init_function = "init(\(init_args))"
        }
        
        let user_functions = functions.filter({!$0.has_option(option: .callback)}).map { function -> String in
            
            let swift_return = "\(if: function._return_.type != .void, "-> \(function._return_.swift_send_return_type)", "")"
            let protocol_args = function._args_.map{$0.swift_protocol_arg}.joined(separator: ", ")
            return """
            func \(function.name)(\(protocol_args )) \(swift_return)
            """
        }.joined(separator: newLineTab)
        
        let pyseq_functions = pySequenceMethods.map(\.protocol_string).joined(separator: newLineTab)
        
        let __funcs__ = pyClassMehthods.filter({$0 != .__init__}).map{ f in
            wrapper_target_type == ._class ? f.protocol_string : "mutating \(f.protocol_string)"
        }.joined(separator: newLineTab)
        
        let callbacks = callbacks_count > 0 ? "var py_callback: \(title)PyCallback? { get set }" : ""
        
        return """
        // Protocol to make target class match the functions in wrapper file
        protocol \(title)_PyProtocol {
        
            \(_init_function)
            \(user_functions)
            \(pyseq_functions)
            \(__funcs__)
            \(callbacks)
        }
        """
    }
    
    private var PyGetSets: String {
        var _properties = properties.filter { p in
            p.property_type == .GetSet || p.property_type == .Getter
        }
        let cls_callbacks = functions.first(where: {$0.has_option(option: .callback)}) != nil
        if _properties.isEmpty && !cls_callbacks {
            //return "fileprivate let \(cls.title)_PyGetSets = nil"
            return ""
        }
        if cls_callbacks {
            _properties.insert(.init(name: "py_callback", property_type: .GetSet, arg_type: .init(name: "", type: .object, other_type: "", idx: 0, arg_options: [])), at: 0)
        }
        
        let properties = _properties.map { p -> String in
            switch p.property_type {
            case .Getter:
                return generate(Getter: p, cls_title: title)
            case .GetSet:
                return generate(GetSet: p, cls_title: title)
            default:
                return ""
            }
        }.joined(separator: newLine)
        
        return """
        \(properties)
        
        fileprivate let \(title)_PyGetSets = PyGetSetDefHandler(
            \(_properties.map { "\(title)_\($0.name)"}.joined(separator: ",\n\t") )
        )
        """
    }
    
    private func generate(GetSet prop: WrapClassProperty, cls_title: String) -> String {
        let arg = prop.arg_type_new
        let is_object = arg.type == .object
        let optional = arg.options.contains(.optional)
        let prop_name = optional ? "\(prop.name)?" : prop.name
        let target = "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"
        let call = "\(arg.swift_property_getter(arg: target))"
        var setValue = optional ? "try? \(arg.type.swiftType)(object: v)" :  (is_object ? "v" : "\(arg.type.swiftType)(v)")
        var callValue = target//is_object ? "\(call)" : call
        if prop.name == "py_callback" {
            callValue = "\(call)?.pycall.ptr"
            setValue = "\(title)PyCallback(callback: v)"
        }
        let getter_extract = optional ? "guard let v = \(target) else { return .PyNone }" : "let v = \(callValue)"
        //        if prop.arg_type_new.type == .str {
        //            callValue = "\(call).pyPointer"
        //        }
        return """
        fileprivate let \(cls_title)_\(prop.name) = PyGetSetDefWrap(
            pySwift: "\(prop.name)",
            getter: {s,clossure in
                \(getter_extract)
                return v.pyPointer
            },
            setter: { s,v,clossure in
                guard let newValue = \(setValue) else { return 1 }
                (s.getSwiftPointer() as \(cls_title)).\(prop.name) = newValue
                return 0
            }
        )
        """.replacingOccurrences(of: newLine, with: newLineTab)
    }
    
    private func generate(Getter prop: WrapClassProperty, cls_title: String) -> String {
        let arg = prop.arg_type_new
        let is_object = arg.type == .object
        let optional = arg.options.contains(.optional)
        let target = "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"
        let call = "\(arg.swift_property_getter(arg: "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"))"
        let callValue = target//is_object ? "PyPointer(\(call))" : call
        
        let getter_extract = optional ? "guard let v = \(target) else { return .PyNone }" : "let v = \(callValue)"
        return """
        fileprivate let \(cls_title)_\(prop.name) = PyGetSetDefWrap(
            pySwift: "\(prop.name)",
            getter: { s,clossure in
                \(getter_extract)
                return v.pyPointer
            }
        )
        """.replacingOccurrences(of: newLine, with: newLineTab)
    }
    
    private var MainFunctions: String {
        var __repr__ = "nil"
        var __str__  = "nil"
        var __hash__ = "nil"
        //var __init__ = "nil"
        
        
        for f in pyClassMehthods {
            switch f {
            case .__repr__:
                __repr__ = """
                { s in
                    \(getSwiftPointer).__repr__().withCString(PyUnicode_FromString)
                }
                """.newLineTabbed
            case .__str__:
                __str__ = """
                { s in
                    \(getSwiftPointer).__str__().withCString(PyUnicode_FromString)
                }
                """.newLineTabbed
            case .__hash__:
                __hash__ = """
                { s in
                    \(getSwiftPointer).__hash__()
                }
                """.newLineTabbed
            case .__set_name__:
                ""
                
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
                    \(a.name) = try \(a.swiftType)(object: PyTuple_GetItem(_args_, 0))
                } else {
                    if let _\(a.name) = PyDict_GetItem(kw, "\(a.name)") {
                        \(a.name) = try \(a.swiftType)(object: _\(a.name))
                    } else { throw PythonError.attribute }
                }
                """.newLineTabbed.addTabs()
            }
        }
        
        let init_call: String
        
        if ignore_init {
            init_call = """
            PyErr_SetString(PyExc_NotImplementedError,"\(title) can only be inited from swift")
            return -1
            """
        } else {
            init_call = """
            setSwiftPointer(s,
                \(title)(\(init_args.joined(separator: ", ")))
            )
            return 0
            """
        }
        
        let __init__ = """
            { s, _args_, kw -> Int32 in
            
            \(if: debug_mode, "print(\"Py_Init \(title)\")")
            \(if: !(init_function?._args_.isEmpty ?? true) && !ignore_init, """
            
            
            do {
                \(init_vars)
                let nkwargs = (kw == nil) ? 0 : _PyDict_GET_SIZE(kw)
                if nkwargs >= \(init_nargs) {
                    guard
                        \(init_lines_kw.joined(separator: ",\n\t\t"))
                        
                    else {
                        PyErr_SetString(PyExc_IndexError, "args missing needed \(init_nargs)")
                        return -1
                    }
                    \(init_lines_kw_post.joined(separator: newLineTabTab))
                } else {
                    let nargs = _PyTuple_GET_SIZE(_args_)
                
                    guard nkwargs + nargs >= \(init_nargs) else {
                        PyErr_SetString(PyExc_IndexError, "args missing needed \(init_nargs)")
                        return -1
                    }
                    \(init_lines.joined(separator: newLineTabTab))
                }
                \(init_call.newLineTabbed.addTabs())
            }
            catch let err {
            
            }
            """.addTabs(),
            init_call.newLineTabbed.addTabs()
            )
            return 1
        }
        """.addTabs()
        
        let __dealloc__ = """
        { s in
            \(if: debug_mode, "print(\"\(title) dealloc\", s.printString)")
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
        { type, args, kw -> PyPointer in
            \(if: debug_mode, "print(\"\(title) New\")")
            return PySwiftObject_New(type)
        }
        """.newLineTabbed
        
        return """
        fileprivate func \(title)_Py_Call(self: PythonPointer, args: PythonPointer, keys: PythonPointer) -> PythonPointer {
            print("\(title) call self", self.printString)
            return .PyNone
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
