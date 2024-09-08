import Foundation

extension WrapModule {
//    
//    private func pyProtocolAddons(cls: WrapClass) -> [String] {
//        
//        var output = [String]()
//        
//        for f in cls.pySequenceMethods {
//            switch f {
//                
//            case .__len__:
//                output.append("func __len__() -> Int")
//            case .__getitem__(key: let key, returns: let returns):
//                output.append("func __getitem__(key: \(swiftTypeFromPythonType(T: key) ?? "PyPointer")) -> \(swiftTypeFromPythonType(T: returns) ?? "PyPointer")")
//            case .__setitem__(key: let key, value: let value):
//                output.append("func __setitem__(key: \(swiftTypeFromPythonType(T: key) ?? "PyPointer"), value: \(swiftTypeFromPythonType(T: value) ?? "PyPointer")) -> Int")
//            default: continue
//            }
//        }
//        
//        
//        
//        
//        return output
//    }
    
//    func pyProtocol(cls: WrapClass) ->  String {
//        
//        var init_function = ""
//        
//        if let _init = cls.init_function {
//            let init_args = _init._args_.map({ a in a.swift_protocol_arg }).joined(separator: ", ")
//            init_function = "init(\(init_args))"
//        }
//        
//        let user_functions = cls.functions.filter({!$0.has_option(option: .callback)}).map { function -> String in
//            
//            let swift_return = "\(if: function._return_.type != .void, "-> \(function._return_.swift_send_return_type)", "")"
//            let protocol_args = function._args_.map{$0.swift_protocol_arg}.joined(separator: ", ")
//            return """
//            func \(function.name)(\(protocol_args )) \(swift_return)
//            """
//        }.joined(separator: newLineTab)
//        
//        let pyseq_functions = cls.pySequenceMethods.map(\.protocol_string).joined(separator: newLineTab)
//        
//        return """
//        // Protocol to make target class match the functions in wrapper file
//        protocol \(cls.title)_PyProtocol {
//        
//            \(init_function)
//            \(user_functions)
//            \(pyseq_functions)
//        
//        }
//        """
//    }
    
//    var generateSwiftSendProtocol: String {
//        var protocol_strings: [String] = []
//        for cls in classes {
//            //guard !cls.swift_object_mode else { continue }
//            var cls_protocols: [String] = []
//            for function in cls.functions {
//                if !function.has_option(option: .callback) && !function.has_option(option: .swift_func) {
//                    //cls_protocols.append("- (\(pythonType2pyx(type: function.returns.type, options: [.objc])))\(function.name)\(function.export(options: [.objc, .header]));")
//                    //cls_protocols.append("- (\(function.returns.objc_type))\(function.name)\(function.export(options: [.objc, .header]));")
//                    let swift_return = "\(if: function._return_.type != .void, "-> \(function._return_.swift_send_return_type)", "")"
//                    //let func_args = function.args.map{"\($0.name): \($0.name)"}.joined(separator: ", ")
////                    cls_protocols.append("""
////                        func \(function.name)(\(function.export(options: [.use_names, .swift, .protocols]))) \(swift_return)
////                    """)
//                    let protocol_args = function._args_.map{$0.swift_protocol_arg}.joined(separator: ", ")
//                    cls_protocols.append("""
//                        func \(function.name)(\(protocol_args )) \(swift_return)
//                    """)
//                }
//            }
//            
//            //func set_\(cls.title)_Callback(_ callback: \(cls.title)Callbacks)
//            if cls.swift_object_mode {
//                var init_string = "//no init"
//                
//                if let _init = cls.init_function {
//                    
//                    let init_args = _init._args_.map({ a in a.swift_protocol_arg }).joined(separator: ", ")
//                    init_string = "\t"+"func init(\(init_args))"
//                    
//                } else {
//                    init_string = "\t"+"init()"
//                }
//                var py_addons: [String] = []
//
//                let protocol_string = """
//                protocol \(cls.title)_PyProtocol {
//                
//                \(init_string)
//                \(cls_protocols.joined(separator: newLine))
//                
//                }
//                
//                """
//                protocol_strings.append(protocol_string)
//            } else {
//                //var call_title = cls.title.titleCase()
//                //call_title.removeFirst()
//                let protocol_string = """
//                protocol \(cls.title)_Delegate {
//                    \(if: cls.callbacks_count > 0, "func set_\(cls.title)_Callback(callback: \(cls.title)PyCallback)")
//                \(cls_protocols.joined(separator: newLine))
//                }
//                
//                private var \(cls.title.lowercased()): \(cls.title)_Delegate!
//                
//                """
//                protocol_strings.append(protocol_string)
//            }
//            
//        }
//        return protocol_strings.joined(separator: newLine)
//    }
//    
//    var generateSwiftCallbackWrap: String {
//        var rtn_strings: [String] = []
//
//        for cls in classes {
//            var call_title = cls.title.titleCase()
//            call_title.removeFirst()
//            let callback_title = "\(call_title)Callback"
//
//            let functions = cls.functions.filter{$0.has_option(option: .callback)}
//            let call_pointers = functions.map{ f -> String in
//                let direct = f.options.contains(.direct)
//                return "\(if: direct, "let ", "private let _")\(f.name): \(f.function_pointer)"
//            }.joined(separator: newLineTab)
//            let set_call_pointers = functions.map{"\(if: $0.options.contains(.direct), "", "_")\($0.name) = callback.\($0.name)"}.joined(separator: newLineTabTab)
//            let call_funcs = functions.filter(
//                {!$0.options.contains(.direct)}).map{ f -> String in
//                    let _args = f.args.map{"\($0.swiftCallbackArgs)"}.joined(separator: ", ")
//                    //let start_arg = "\(if: !cls.singleton, "cls\(if: _args.count != 0, ", ")")"
//                    let start_arg = ""
//                    return """
//
//                    func \(f.name)(\(f.export(options: [.use_names, .swift, .protocols]))) {
//                            _\(f.name)(\(start_arg)\(_args))
//                        }
//                    """
//            }
//            rtn_strings.append("""
//            struct \(cls.title)PyCallback {
//                public let pycall: \(cls.title)Callbacks
//                \(call_pointers)
//
//                init(callback: \(cls.title)Callbacks){
//                    pycall = callback
//                    \(set_call_pointers)
//                }
//
//                \(call_funcs.joined(separator: newLineTab))
//            }
//
//            //var \(callback_title): \(cls.title)PyCallback!
//            """)
//        }
//        return rtn_strings.joined(separator: newLine)
//    }
    
//    var generateSwiftPythonObjectCallbackWrap: String {
//        var rtn_strings: [String] = []
//        
//        for cls in classes {
//            if cls.callbacks_count == 0 { continue }
//            var call_title = cls.title.titleCase()
//            call_title.removeFirst()
//            let callback_title = "\(call_title)Callback"
//            
//            let functions = cls.functions.filter{$0.has_option(option: .callback)}
//            let call_pointers = functions.map{ f -> String in
//                let direct = f.options.contains(.direct)
//                return "\(if: direct, "let ", "private let _")\(f.name): PythonPointer"
//            }.joined(separator: newLineTab)
//            let set_call_pointers = functions.compactMap{ f->String? in
//                if f.call_class_is_arg {
//                    //return "\(if: f.options.contains(.direct), "", "_")\(f.name) = PyUnicode_FromString(\"\(f.name)\")"
//                    return "\(if: f.options.contains(.direct), "", "_")\(f.name) = PyUnicode_FromString(\" name)\")"
//                }
//                if f.call_target_is_arg {
//                    return nil
//                }
//                
//                if let call_target = f.call_target {
//                    return "\(if: f.options.contains(.direct), "", "_")\(f.name) = pycall.\(call_target).\(f.name).ptr"
//                }
//                
//                //return "\(if: f.options.contains(.direct), "", "_")\(f.name) = pycall.\(f.name).ptr"
//                return "\(if: f.options.contains(.direct), "", "_")\(f.name) = PyObject_GetAttr(callback, \"\(f.name)\")"
//                
//            }.joined(separator: newLineTabTab)
//            let call_funcs = functions.filter(
//                {!$0.options.contains(.direct)}).map{ f -> String in
//                    let _args_ = f._args_.filter{ a -> Bool in
//                        if f.call_class_is_arg { if a.name == f.call_class { return false } }
//                        if f.call_target_is_arg { if a.name == f.call_target { return false } }
//                        return true
//                    }.map{a -> String in
//                        //TODO: if a.asObjectEnum != nil { return "\(a.name).rawValue" }
//                        //TODO: if a.has_option(.dispatch) { return "\(a.name).rawValue" }
//                        
//                        //if a.has_option(.memoryview) { return "\(a.name)_mem" }
//                        //if a.type == .data { return "\(a.name)_mem" }
//                        
//                        return a.name
//                    }
//                        
//                    let _args = _args_.joined(separator: ", ")
//                    //let start_arg = "\(if: !cls.singleton, "cls\(if: _args.count != 0, ", ")")"
//                    
////                    let converted_args = f.args.map{a -> String? in
////                        if a.type == .object { return nil}
////                        if a.asObjectEnum != nil { return nil }
////                        if a.has_option(.dispatch) { return nil }
////                        if a.has_option(.list) { return "\(a.name) = \(a.name).pythonList" }
////                        if a.has_option(.memoryview) { return nil }
////                        if a.type == .data { return nil }
////                        return "\(a.name) = \(elementConverterPythonType(element: a.name, T: a.type, AsFrom: .As))"
////
////                    }.compactMap{$0}
//                    
//                    let converted_args = f._args_.filter{$0.conversion_needed}.map{ a-> String in
//                        if a.type == .data {return "\(a.name) = \(a.name).memoryView()"}
//                        //if a.type == .str { fatalError("str was handled")}
//                        //if a.type == .jsondata { return "\(a.name) = \(a.swift_send_call_arg)"}
//                        return "\(a.name) = \(a.swift_callback_call_arg)"
//                    }
//                    
//                    
//                    //let memory_args = f.args.filter({$0.has_option(.memoryview) || $0.type == .data})
//                    //let memory_arg_count = memory_args.count
////                    let has_memory_args = memory_arg_count != 0
//                        
////                    let memory_vars = memory_args.map{ a -> String in
////                        "\(a.name)_mem = \(a.name).memoryView()"
////                    }.joined(separator: ", ")
////
////                    let buffer_releases = memory_args.map{ a -> String in
////                        return "PyBuffer_Release(&\(a.name)_buf)"
////                    }.joined(separator: "; ")
////
////                    let decrefs = f.args.filter({ $0.type != .object }).map{ a -> String in
////                        if a.has_option(.memoryview) { return "Py_DecRef(\( a.name)_mem)" }
////                        if a.type == .data { return "Py_DecRef(\( a.name)_mem)" }
////                        return "Py_DecRef(\( a.name))"
////                    }
//                    let decrefs = f._args_.filter{ $0.decref_needed }.map{ a->String in
//                        //if a.has_option(.memoryview) { return "Py_DecRef(\( a.name)_mem)" }
//                        //if a.type == .data { return "Py_DecRef(\( a.name)_mem)" }
//                        return "Py_DecRef(\( a.name))"
//                        
//                    }
//                    
//                    
//                    let decrefs_joined = decrefs.joined(separator: "; ")
//                    let joined_cargs = converted_args.joined(separator: ", ")
////                    let arg_set = f.args.map{a -> (String,[String])? in
////                        switch a.type {
////                        case .data:
////                            return ("\(a.name).withMemoryView",["\(a.name)_mem"])
////                        default:
////                            if a.has_option(.memoryview) { return ("\(a.name).withMemoryView",["\(a.name)_mem"]) }
////                            return nil
////                        }
////                    }.compactMap({$0})
//                    
//                    let use_rtn = f._return_.type != .void || f._return_.type != .None
//                    var return_string = ""
//                    
//                    if use_rtn {
//                        return_string = "let \(f.name)_result: \(f._return_.swift_callback_return_type) = "
//                    }
//                    
//                    var arg_count = _args_.count
//                    
//                    
//                    var pycall = ""
//                    if f.call_class_is_arg {
//                        arg_count += 1
//                        let target = f.call_class!
//                        switch f._args_.count {
//                        case 0: pycall = "\(return_string)PyObject_CallMethodCallNoArgs(\(target), _\(f.name))"
//                        case 1: pycall = "\(return_string)PyObject_CallMethodOneArg(\(target), _\(f.name), \(_args))"
//                        default: pycall = """
//                                        let vector_callargs: [PythonPointer?] = [\(target), \(_args)]
//                                        \(return_string)PyObject_VectorcallMethod(_\(f.name), vector_callargs, \(arg_count), nil)
//                                        """.replacingOccurrences(of: newLine, with: newLineTabTab)
//                        }
//                    } else if f.call_target_is_arg {
//                        arg_count += 1
//                        let target = f.call_target!
//                        switch f.args.count {
//                        case 0: pycall = "\(return_string)PyObject_CallNoArgs(\(target))"
//                        case 1: pycall = "\(return_string)PyObject_CallOneArg(\(target), \(_args))"
//                        default: pycall = """
//                                        let vector_callargs: [PythonPointer?] = [\(_args)]
//                                        \(return_string)PyObject_Vectorcall(\(target), vector_callargs, \(arg_count), nil)
//                                        """.replacingOccurrences(of: newLine, with: newLineTabTab)
//                        }
//                    } else {
//                        switch f._args_.count {
//                        case 0: pycall = "\(return_string)\(f._return_.convert_return(arg: "PyObject_CallNoArgs(_\(f.name))"))"
//                        case 1: pycall = "\(return_string)PyObject_CallOneArg(_\(f.name), \(_args))"
//                        default: pycall = """
//                                        let vector_callargs: [PythonPointer] = [\(_args)]
//                                        \(return_string)PyObject_Vectorcall(_\(f.name), vector_callargs, \(arg_count), nil)
//                                        """.replacingOccurrences(of: newLine, with: newLineTabTab)
//                        }
//                    }
//                    
//                    
//                    
//                    //pycall = handleClossures(main_string: pycall, args_set: arg_set)
//                    //\(if: has_memory_args, "\(buffer_releases)", "#removeline")
//                    //\(if: has_memory_args, "var ", "#removeline")\(memory_vars)
//                    let func_args = f._args_.map(\.swift_callback_func_arg).joined(separator: ", ")
//                    return """
//                    
//                        @inlinable
//                        func \(f.name)(\(func_args))\(if: use_rtn," -> \(f._return_.swift_callback_return_type)","") {
//                            var gil: PyGILState_STATE?
//                            if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }
//                            \(if: converted_args.count != 0, "let ", "#removeline")\(joined_cargs)
//                            \(pycall)
//                            \(if: converted_args.count != 0, "\(decrefs_joined)", "#removeline")
//                            if let gil = gil { PyGILState_Release(gil) }
//                            \(if: use_rtn, "return \(f.name)_result", "#removeline")
//                        }
//                    """.replacingOccurrences(of: "        #removeline\n", with: "")
//            }
//            rtn_strings.append("""
//            struct \(cls.title)PyCallback {
//                public let pycall: PythonObject
//                \(call_pointers)
//
//                init?(callback: PythonPointer){
//                    pycall = PythonObject(ptr: callback)
//                    \(set_call_pointers)
//                }
//                
//                \(call_funcs.joined(separator: newLineTab))
//            }
//
//            """)
//        }
//        return rtn_strings.joined(separator: newLine)
//    }
    var objectEnums: [CustomEnum] {
        custom_enums.filter{$0.type == .object}
    }
    
    var objectEnumNames: [String] {
        objectEnums.map{$0.title}
    }
    
    func objectEnums(has e: String) throws -> Bool {
        objectEnumNames.contains(e)
    }
    
    func objectEnums(has t: String, out: @escaping (CustomEnum)->Void ) {
        for e in custom_enums {
            if e.title == t {
                out(e)
                return
            }
        }
    }
    
    func objectEnums(has t: String, out: @escaping (CustomEnum)->WrapArgProtocol ) -> WrapArgProtocol? {
        for e in custom_enums {
            if e.title == t {
                
                return out(e)
            }
        }
        return nil
    }
    
    func objectEnums(has t: String) -> CustomEnum? {
        for e in custom_enums {
            if e.title == t {
                return e
            }
        }
        return nil
    }
    
    var enumNames: [String] {
        let enum_names = wrap_module_shared.custom_enums.map {e in
            e.title
        }
        return enum_names
    }
    
//    func generateSendFunctions(cls: WrapClass, objc: Bool, header: Bool) -> String {
//        var send_strings: [String] = []
//        var send_options: [PythonTypeConvertOptions] = [.use_names]
//        var return_options: [PythonTypeConvertOptions] = []
//        if header {send_options.append(.header); send_options.append(.pyx_extern)}
//        if objc {
//            send_options.append(.objc)
//            return_options.append(.objc)
//        }
////        else {
////            send_options.append(.py_mode)
////        }
//
//
//        //for cls in classes {
//
//            for function in cls.functions {
//                if !function.has_option(option: .callback) && !function.has_option(option: .swift_func) {
//                    //let func_return_options = return_options
////                    if function.returns.has_option(.list) {
////                        func_return_options.append(.is_list)
////                    }
//                    //let return_type = "\(pythonType2pyx(type: function.returns.type, options: return_options))"
//
////                    let send_args = function.args.map{ arg -> String in
////                        //if arg.asObject { return "PythonObject \(arg.name)" }
////                        if arg.asObject { return "PythonPointer \(arg.name)" }
////                        return arg.export(options: send_options)
////                    }.joined(separator: ", ")
//                    let send_args = function._args_.map{ $0.swiftType }.joined(separator: ", ")
//                    //let return_type2 = function.returns.convertPythonType(options: func_return_options)
//                    let return_type2 = function._return_.type != .void ? "PyObject*" : "void"
//                    var func_string: String
//                    if cls.swift_object_mode {
//                        func_string = "\(return_type2) \(cls.title)_\(function.name)(void* __ptr\(if: function._args_.count > 0, ", \(send_args)"))"
//                    } else {
//                        func_string = "\(return_type2) \(cls.title)_\(function.name)(\(send_args))"
//                    }
//
//                    if objc { func_string.append(";") }
//
//                    send_strings.append(func_string)
//                }
//            }
//        //}
//        if objc {
//            return send_strings.joined(separator: newLine)
//        } else {
//            return send_strings.joined(separator: "\n\t")
//        }
//
//    }
//
    
//    func generateGlobalSendFunctions(mod: WrapModule, objc: Bool, header: Bool) -> String {
//        var send_strings: [String] = []
//        var send_options: [PythonTypeConvertOptions] = [.use_names]
//        var return_options: [PythonTypeConvertOptions] = []
//        if header {send_options.append(.header); send_options.append(.pyx_extern)}
//        if objc {
//            send_options.append(.objc)
//            return_options.append(.objc)
//        }
////        else {
////            send_options.append(.py_mode)
////        }
//        
//        
//        //for cls in classes {
//            
//            for function in mod.functions {
//                if function.has_option(option: .swift_func) {
//      
//                    let send_args = function._args_.map{ $0.c_header_arg }.joined(separator: ", ")
//                    //let return_type2 = function.returns.convertPythonType(options: func_return_options)
//                    let return_type2 = function._return_.type != .void ? "PyObject*" : "void"
//                    var func_string: String
////                    if cls.swift_object_mode {
////                        func_string = "\(return_type2) \(cls.title)_\(function.name)(void* __ptr\(if: function._args_.count > 0, ", \(send_args)"))"
////                    } else {
//                        func_string = "\(return_type2) \(mod.filename)_\(function.name)(\(send_args))"
////                    }
//                    
//                    if objc { func_string.append(";") }
//                    
//                    send_strings.append(func_string)
//                }
//            }
//        //}
//        if objc {
//            return send_strings.joined(separator: newLine)
//        } else {
//            return send_strings.joined(separator: "\n\t")
//        }
//        
//    }
//    
//    func generatePyxClassFunctions(cls: WrapClass) -> String {
//        var output: [String] = []
//
//        //for cls in classes {
//
//            //for function in cls.functions.filter({!$0.has_option(option: .property)}) {
//
//        for function in cls.functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .property) && !$0.has_option(option: .cfunc)}) {
//                //if !function.has_option(option: .callback) {
//
//                    let return_type = function.returns.type
//                    var rtn: String
//                    if return_type == .void {rtn = "None"} else {rtn = PurePythonTypeConverter(type: return_type)}
//                    let py_return = "\(if: function.returns.has_option(.list),"list[\(rtn)]",rtn)"
//            output.append("\t"+"def \(function.name)(self, \(function.export(options: [.py_mode]))) -> \(py_return): #\(function.options.map{$0.rawValue}.joined(separator: ", "))")
//                    //handle list args
//                    let list_args = function.args.filter{$0.has_option(.list) && !$0.has_option(.codable)}
//
//                    for list_arg in list_args {
//                        if list_arg.type == .str {
//                            output.append(list_arg.strlistFunctionLine)
//                        } else {
//                            output.append(list_arg.listFunctionLine)
//                        }
//
//                    }
//                    //output.append(contentsOf: list_args.map{listFunctionLine(wrap_arg: $0)})
//
//                    let jsondata_args = function.args.filter{$0.type == .jsondata}
//                    for json in jsondata_args {
//                        output.append("\t\tcdef bytes j_\(json.name) = json.dumps(\(json.name)).encode()")
//                        //output.append("\t\tcdef const unsigned char* __\(json.name) = _\(json.name)")
//                        output.append("\t\tcdef long \(json.name)_size = len(j_\(json.name))")
//                    }
//                    let data_args = function.args.filter{$0.type == .data}
//                    output.append(contentsOf: data_args.map{"\t\tcdef long \($0.name)_size = len(\($0.name))"})
//                    let codable_args = function.args.filter { (arg) -> Bool in arg.has_option(.codable)}
//                    output.append(contentsOf: codable_args.map({ (arg) -> String in
//                        """
//                                cdef bytes j_\(arg.name) = json.dumps(\(arg.name).__dict__).encode()
//                                cdef long \(arg.name)_size = len(j_\(arg.name))
//                        """
//                    }))
//
//            output.append("\t\t" + generateFunctionCode(title: cls.title, function: function, cls: cls))
//                    for arg in list_args {
//                        if arg.type == .str {
//    //                        output.append("""
//    //                        for x in range(\(arg.name)_size)
//    //                        """)
//                        }
//                        output.append("\t\tfree(\(arg.name)_array)")
//                    }
//                    output.append("")
//                }
//            //}
//        //}
//        return output.joined(separator: newLine)
//    }
    
    
    
    
    
    
    
    

    
    
    func generateStruct(options: [StructTypeOptions]) -> String {
        var output: [String] = []
        var ending = ""
        let objc = options.contains(.objc)
        let swift_mode = options.contains(.swift_functions)
        if swift_mode {
            if !classes.contains(where: { cls -> Bool in
                cls.has_swift_functions
            }) {
                return "//abc"
            }
        }
        let callback_mode = options.contains(.callbacks)
        if swift_mode {ending = "SwiftFuncs"}
        else if callback_mode {ending = "Callbacks"}
        else if options.contains(.swift) {ending = "Sends"}
        
        for cls in classes {
            var struct_args: [String] = []
            for function in cls.functions {
                if callback_mode {
                    if function.has_option(option: .callback) {
                        let arg = "\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                        struct_args.append(arg)
                    }
                }
                
                else if swift_mode {
                    if function.has_option(option: .swift_func) && !function.has_option(option: .callback) {
                        let arg = "\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                        struct_args.append(arg)
                    }
                }
                if options.contains(.swift) {
                    if !function.has_option(option: .callback) {
                        let arg = "\(function.function_pointer)\(if: objc, " _Nonnull") \(function.name)"
                        struct_args.append(arg)
                    }
                }
                
            }
            
            if options.contains(.swift) {
                if objc {
                    output.append(
                        """
                        typedef struct \(cls.title)\(ending) {
                            \(struct_args.joined(separator: ";\n\t"));
                        } \(cls.title)\(ending);
                        """
                    )
                } else {
                    output.append(
                        """
                        ctypedef struct \(cls.title)\(ending):
                            \t\(struct_args.joined(separator: newLineTabTab))
                        """
                    )
                }
                
            } else {
                if objc {
                    output.append(
                        """
                        typedef struct \(cls.title)\(ending) {
                            \(struct_args.joined(separator: ";\n\t"));
                        } \(cls.title)\(ending);
                        """
                    )
                } else {
                    output.append(
                    """
                    ctypedef struct \(cls.title)\(ending):
                        \t\(struct_args.joined(separator: newLineTabTab))
                    """
                    )
                }
            }
            
            
        }
        return output.joined(separator: newLineTab) + newLine
    }

//    func generateCallbackFunctions(options: [PythonTypeConvertOptions]) -> String {
//        var output: [String] = []
//        //let objc = options.contains(.objc)
//        //let header = options.contains(.header)
//        for cls in classes {
//            
//            for function in cls.functions {
//                
//                if function.has_option(option: .callback) {
//                    if options.contains(.objc) {
//                        output.append(functionGenerator(wraptitle: cls.title, function: function, options: options))
//    //                    output.append("""
//    //                    //\(pythonType2pyx(type: function.returns.type, options: options)) \(cls.title)_\(function.name)(\(function.export(options: options));
//    //                    """)
//                    } else {
//                        //var send_options = options
//                        //send_options.append(.header)
//                        output.append(functionGenerator(wraptitle: cls.title, function: function, options: options))
//                    }
//                    
//                }
//            }
//        }
//        return output.joined(separator: newLine + newLine)
//    }
    
    func generateFunctionPointers(objc: Bool, options: [FunctionPointersOptions]) -> String {
        var tdef = ""
        if objc { tdef = "typedef" } else { tdef = "ctypedef"}
        var output: [String] = []
        
        var excluded_state = "false"
        if options.contains(.excluded_callbacks) {excluded_state = "true"}
        
        for cls in classes {
            for (_,function) in cls.pointer_compare_dict.sorted(by: { $0.1["name"]! < $1.1["name"]! }).filter({$0.1["excluded_callbacks"] != excluded_state}) {
                //let function = cls.pointer_compare_dict[key]!
                var key_value: String
                if objc {key_value = "objc_string"} else {key_value = "pyx_string"}
                var pointer_string = "\(tdef) \("void") (*\(function["name"]!))(\(function[key_value]!))"
                if objc {pointer_string.append(";")}
                output.append(pointer_string)
            }
        }
        if objc {
            return output.joined(separator: newLine)
        } else {
            return output.joined(separator: newLineTab)
        }
    }
    
    
}



