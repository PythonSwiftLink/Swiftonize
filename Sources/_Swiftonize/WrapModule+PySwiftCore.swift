//
//  WrapModule+PySwiftCore.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 18/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import WrapContainers

extension PyClassFunctions {
    
    var protocol_decl: MemberDeclListSyntax.Element {
        switch self {

        case .__hash__:
			return .init(decl: try! VariableDeclSyntax("var __hash__: Int { get }"))
        default:
            return .init(decl: function_header)
        }
    }
    
    var function_header: FunctionDeclSyntax {
        
        var sig: FunctionSignatureSyntax {
            var args: [String] = []
            var rtn: ReturnClauseSyntax? = nil
            switch self {
            case .__init__:
                break
            case .__repr__:
                rtn = "String".returnClause
            case .__str__:
                rtn = "String".returnClause
            case .__hash__:
                rtn = "Int".returnClause
            case .__set_name__:
                break
            case .__call__:
                break
            case .__iter__:
                break
            case .__buffer__:
                args = ["s: PyPointer", "buffer: UnsafeMutablePointer<Py_buffer>"]
                rtn = "Int32".returnClause
            }
//            switch self {
//            case .__len__:
//                args = .init([])
//                rtn = "Int".returnClause
//            case .__getitem__(_, _):
//                args = ["idx: Int"]
//                rtn = "PyPointer?".returnClause
//            case .__setitem__(_, _):
//                args = ["idx: Int", "newValue: PyPointer"]
//                rtn = "Bool".returnClause
//            case .__delitem__(_):
//                args = ["idx: Int"]
//                rtn = "Bool".returnClause
//            case .__missing__:
//                break
//            case .__reversed__:
//                break
//            case .__contains__:
//                break
//            }
            
            return .init(input: args.parameterClause, output: rtn)
        }
        
        
        return .init(identifier: .identifier(rawValue), signature: sig)
    }
}
    // Sequence

extension PySequenceFunctions_ {
    
	func callExpr(cls: String) -> ClosureExprSyntax {
        
        //return .init(signature: nil, statements: .init {
            switch self {
            case .__len__:
				return .init {}
//				return .init(stringLiteral: """
//				""")
            case .__getitem__(let key, let returns):
				return ExprSyntax(stringLiteral:
				"""
				{ _self_, idx -> PyPointer? in
				do {
					if let _self_ = _self_ {
						return try UnPackPySwiftObject(with: _self_, as: \(cls).self).__getitem__(idx: idx)
					}
				}
				catch _ {}
				
				return nil
				}
				""").as(ClosureExprSyntax.self)!
            case .__setitem__(let key, let value):
				return .init {}
            case .__delitem__(let key):
				return .init {}
            case .__missing__:
				return .init {}
            case .__reversed__:
				return .init {}
            case .__contains__:
				return .init {}
            }
       // })
    }
    
    var function_header: FunctionDeclSyntax {
        
        var sig: FunctionSignatureSyntax {
            var args: [String] = []
            var rtn: ReturnClauseSyntax? = nil
            switch self {
            case .__len__:
                args = .init([])
                rtn = "Int".returnClause
            case .__getitem__(_, _):
                args = ["idx: Int"]
				//fatalError()
                rtn = "PyPointer?".returnClause
            case .__setitem__(_, _):
                args = ["idx: Int", "newValue: PyPointer"]
                rtn = "Bool".returnClause
            case .__delitem__(_):
                args = ["idx: Int"]
                rtn = "Bool".returnClause
            case .__missing__:
                break
            case .__reversed__:
                break
            case .__contains__:
                break
            }
            
            return .init(input: args.parameterClause, output: rtn)
        }
        
        
        return .init(identifier: .identifier(name), signature: sig)
    }
}
    // numeric


extension WrapModule {
    
    
//    func generate(PyMethods cls: WrapClass) -> String {
//        
//        
//        
//        return """
//        fileprivate let PyMethods = PyMethodDefHandler(
//            
//        )
//        """
//    }
//    
//    func generate(MainFunctions cls: WrapClass) -> String {
//        var __repr__ = "nil"
//        var __str__  = "nil"
//        var __hash__ = "nil"
//        //var __init__ = "nil"
//
//
//        for f in cls.pyClassMehthods {
//            switch f {
//            case .__repr__:
//                __repr__ = """
//                { s in
//                    (s.getSwiftPointer() as \(cls.title)).__repr__().withCString(PyUnicode_FromString)
//                }
//                """.newLineTabbed
//            case .__str__:
//                __str__ = """
//                { s in
//                    (s.getSwiftPointer() as \(cls.title)).__str__().withCString(PyUnicode_FromString)
//                }
//                """.newLineTabbed
//            case .__hash__:
//                __hash__ = """
//                { s in
//                    (s.getSwiftPointer() as \(cls.title)).__hash__()
//                }
//                """.newLineTabbed
//            case .__set_name__:
//                ""
//
//            default: continue
//            }
//        }
//        var init_vars = ""
//        var kw_extract = ""
//        if let _init = cls.init_function {
//            let args = _init._args_
//            init_vars = args.map { a in
//                "var \(a.swift_protocol_arg)\(if: a.type != .object, "?") = nil"
//            }.joined(separator: newLineTabTab)
//
//        }
//        let init_nargs = cls.init_function?._args_.count ?? 0
//        var init_args = [String]()
//        var init_lines_kw = [String]()
//        var init_lines = [String]()
//
//        if let init_func = cls.init_function {
//            init_args = init_func._args_.map {a in "\(a.name): \(a.name)\(if: a.type != .object, "?")"}
//            init_lines_kw = init_func._args_.map { a in
//                return """
//                let _\(a.name) = PyDict_GetItem(kw, "\(a.name)")
//                """
//            }
//            init_lines = init_func._args_.map { a in
//                let is_object = a.type == .object
//                //                let extract = "PyTuple_GetItem(args, \(a.idx))"
//                //                return "let \(a.name): \(a.type.swiftType) = \(is_object ? extract : "init(\(extract)")"
//                return """
//                if nargs > \(a.idx) {
//                    \(a.name) = .init(PyTuple_GetItem(args, 0))
//                } else {
//                    if let _\(a.name) = PyDict_GetItem(kw, "\(a.name)") {
//                        \(a.name) = .init(_\(a.name))
//                    }
//                }
//                """.newLineTabbed
//            }
//        }
//
//        let __init__ = """
//        { s, args, kw -> Int32 in
//
//            print("Py_Init \(cls.title)")
//            \(if: !(cls.init_function?._args_.isEmpty ?? true), """
//
//            \(init_vars)
//
//            let nkwargs = (kw == nil) ? 0 : _PyDict_GET_SIZE(kw)
//            if nkwargs >= \(init_nargs) {
//                guard
//                    \(init_lines_kw.joined(separator: ",\n\t\t\t"))
//                else {
//                    PyErr_SetString(PyExc_IndexError, "args missing needed \(init_nargs)")
//                    return -1
//                }
//            } else {
//                let nargs = _PyTuple_GET_SIZE(args)
//
//                guard nkwargs + nargs >= \(init_nargs) else {
//                    PyErr_SetString(PyExc_IndexError, "args missing needed \(init_nargs)")
//                    return -1
//                }
//                \(init_lines.joined(separator: ",\n\t\t"))
//            }
//
//            """.addTabs())
//            setSwiftPointer(
//                s,
//                .init(\(init_args.joined(separator: ", ")))
//            )
//            return 0
//        }
//        """.addTabs()
//
//        let __dealloc__ = """
//        { s in
//            print("\(cls.title) dealloc", s.printString)
//            s.releaseSwiftPointer(\(cls.title).self)
//        }
//        """.newLineTabbed
//
//        let __new__ = """
//        { type, args, kw -> PyPointer in
//            print("\(cls.title) New")
//            return PySwiftObject_New(type)
//        }
//        """.newLineTabbed
//
//        return """
//        fileprivate func \(cls.title)_Py_Call(self: PythonPointer, args: PythonPointer, keys: PythonPointer) -> PythonPointer {
//            print("\(cls.title) call self", self.printString)
//            return .PyNone
//        }
//
//        fileprivate let \(cls.title)_PyFunctions = PyTypeFunctions(
//            tp_init: \(__init__),
//            tp_new: \(__new__),
//            tp_dealloc: \(__dealloc__),
//            tp_getattr: nil, // will overwrite the other GetSets if not nil,
//            tp_setattr: nil, // will overwrite the other GetSets if not nil,
//            tp_as_number: nil,
//            tp_as_sequence: nil,
//            tp_call: \(cls.title)_Py_Call,
//            tp_str: \(__str__),
//            tp_repr: \(__repr__)//,
//            //tp_hash: \(__hash__)
//        )
//
//        """
//    }
//
    
//    func generate(PyGetSets cls: WrapClass) -> String {
//        var _properties = cls.properties.filter { p in
//            p.property_type == .GetSet || p.property_type == .Getter
//        }
//        let cls_callbacks = cls.functions.first(where: {$0.has_option(option: .callback)}) != nil
//        if _properties.isEmpty && !cls_callbacks {
//            //return "fileprivate let \(cls.title)_PyGetSets = nil"
//            return ""
//        }
//        if cls_callbacks {
//            _properties.insert(.init(name: "callback_target", property_type: .GetSet, arg_type: .init(name: "", type: .object, other_type: "", idx: 0, arg_options: [])), at: 0)
//        }
//        
//        let properties = _properties.map { p -> String in
//            switch p.property_type {
//            case .Getter:
//                return generate(Getter: p, cls_title: cls.title)
//            case .GetSet:
//                return generate(GetSet: p, cls_title: cls.title)
//            default:
//                return ""
//            }
//        }.joined(separator: newLine)
//        
//        return """
//        \(properties)
//        
//        fileprivate let \(cls.title)_PyGetSets = PyGetSetDefHandler(
//            \(_properties.map { "\(cls.title)_\($0.name)"}.joined(separator: ",\n\t") )
//        )
//        """
//    }
//    
//    fileprivate func generate(GetSet prop: WrapClassProperty, cls_title: String) -> String {
//        let arg = prop.arg_type_new
//        let is_object = arg.type == .object
//        let call = "\(arg.swift_property_getter(arg: "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"))"
//        var setValue = is_object ? ".init(newValue)" : "newValue"
//        var callValue = is_object ? "PyPointer(\(call))" : call
//        if prop.name == "callback_target" {
//            callValue = "\(call)?.pycall.ptr"
//            setValue = ".init(callback: v)"
//        }
//        return """
//        fileprivate let \(cls_title)_\(prop.name) = PyGetSetDefWrap(
//            name: "\(prop.name)",
//            getter: {s,clossure in
//                if let v = \(callValue) {
//                    return v
//                }
//                return .PyNone
//            },
//            setter: { s,v,clossure in
//                let newValue = \(arg.swift_property_setter(arg: "v"))
//                (s.getSwiftPointer() as \(cls_title)).\(prop.name) = \(setValue)
//                return 0
//                // return 1 if error
//            }
//        )
//        """.replacingOccurrences(of: newLine, with: newLineTab)
//    }
//    
//    fileprivate func generate(Getter prop: WrapClassProperty, cls_title: String) -> String {
//        let arg = prop.arg_type_new
//        let is_object = arg.type == .object
//        let call = "\(arg.swift_property_getter(arg: "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"))"
//        let callValue = is_object ? "PyPointer(\(call))" : call
//        return """
//        fileprivate let \(cls_title)_\(prop.name) = PyGetSetDefWrap(
//            name: "\(prop.name)",
//            getter: { s,clossure in
//                if let v = \(callValue) {
//                    return v
//                }
//                return .PyNone
//            }
//        )
//        """.replacingOccurrences(of: newLine, with: newLineTab)
//    }
    
//    var module_functions: String {
//        //if functions.isEmpty { return "fileprivate let \(filename)_PyMethods = nil"}
//        if functions.isEmpty { return ""}
//        let funcs = functions.map({ f in
//            switch f._args_.count {
//            case 0:
//                return f.generate(PyMethod_noArgs: nil)
//            case 1:
//                return f.generate(PyMethod_oneArg: nil)
//            default:
//                return f.generate(PyMethod_withArgs: nil)
//                
//            }
//        }).map({$0.replacingOccurrences(of: newLine, with: newLineTab)}).joined(separator: ",\n\t")
//        
//        return """
//        public let \(filename)_PyMethods = PyMethodDefHandler(
//            \(funcs)
//        )
//        """
//    }
    
    
    
    
    
   
    
//    func generate(PySequenceMethods cls: WrapClass) -> String {
//        
//        var length = "length: nil"
//        var get_item = "get_item: nil"
//        var set_item = "set_item: nil"
//        if cls.pySequenceMethods.isEmpty { return "" }
//        for m in cls.pySequenceMethods {
//            switch m {
//                
//            case .__len__:
//                length = """
//                length: { s in
//                    return (s.getSwiftPointer() as \(cls.title)).__len__()
//                }
//                """.addTabs()
//            case .__getitem__(key: _, returns: _):
//                //let _key = key == .object ? "key" : ".init(key)"
//                get_item = """
//                get_item: { s, idx in
//                    do {
//                        return (s.getSwiftPointer() as \(cls.title)).__getitem__(idx: idx )
//                    }
//                    catch let err as PythonError {
//                        switch err {
//                        case .call: err.triggerError("__getitem__")
//                        default: err.triggerError("note")
//                        }
//                    }
//                    catch let other_error {
//                        other_error.pyExceptionError()
//                        }
//                    }
//                return nil
//                """.addTabs()
//            case .__setitem__(key: _, value: _):
//                //let _key = key == .object ? "key" : ".init(key)"
//                set_item = """
//                set_item: { s, idx, item in
//                    do {
//                        guard let item = item else { throw PythonError.call }
//                        (s.getSwiftPointer() as \(cls.title)).__setitem__(idx: idx, newValue: item )
//                        return 0
//                    }
//                
//                    catch let err as PythonError {
//                        switch err {
//                        case .call: err.triggerError("__setitem__")
//                        default: err.triggerError("note")
//                        }
//                    }
//                    catch let other_error {
//                        other_error.pyExceptionError()
//                        }
//                    }
//                    return 1
//                }
//                """.addTabs()
//            case .__delitem__(key: _):
//                continue
//            case .__missing__:
//                continue
//            case .__reversed__:
//                continue
//            case .__contains__:
//                continue
//            }
//        }
//"""
//let seq = PySequenceMethodsHandler(methods: .init(
//    length: { s in
//        return \(cls.title).__len__()
//    },
//    concat: { lhs, rhs in
//        return .PyNone
//    },
//    repeat_: { s, count in
//        return .PyNone
//    },
//    get_item: { s, idx in
//        return \(cls.title).__getitem__()
//    },
//    set_item: { s, idx, item in
//        return \(cls.title).__setitem__()
//    },
//    contains: { s, o in
//        return 1
//    },
//    inplace_concat: { lhs, rhs in
//        return .PyNone
//    },
//    inplace_repeat: { s, count in
//        return .PyNone
//    }
//)
//)
//"""
//        return """
//        let \(cls.title)_PySequenceMethods = PySequenceMethodsHandler(methods: .init(
//            \(length),
//            concat: nil,
//            repeat_: nil,
//            \(get_item),
//            \(set_item),
//            contains: nil,
//            inplace_concat: nil,
//            inplace_repeat: nil
//            )
//        )
//        """
//    }
//    private var pyModuleDef: String {
//        let methods = functions.isEmpty ? "nil" : "\(filename)_PyMethods"
//        
//        return """
//        
//        \(module_functions)
//        
//        fileprivate let \(filename)_module = PyModuleDefHandler(
//            name: "\(filename)",
//            methods: \(methods)
//        )
//        //fileprivate let py_module = \(filename)_module.module
//        """
//    }
//    
//    var generatePyModule: String {
//        
//        let pymod_addtypes = classes.map { cls -> String in
//            "PyModule_AddType(m, \(cls.title)PyType.pytype)"
//        }.joined(separator: newLineTabTab)
//        
//        return """
//        \(pyModuleDef)
//        
//        func PyInit_\(filename)() -> PyPointer? {
//        
//            if let m = PyModule_Create2(\(filename)_module.module, 3) {
//            
//                \(pymod_addtypes)
//            
//                return m
//            }
//            
//            return nil
//        }
//        """
//    }
}
