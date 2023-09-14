//
//  CodeLayouts.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 16/10/2021.
//
import SwiftyJSON
import Foundation


func generateCythonClass(module_name: String, cls: WrapClass, class_vars: String, dispatch_mode: Bool) -> String {
    if cls.swift_object_mode {
        return generateSwiftObjectClass(module_name: module_name, cls: cls, class_vars: class_vars, dispatch_mode: dispatch_mode)
    }
    return generateCythonClassNormal(cls: cls, class_vars: class_vars, dispatch_mode: dispatch_mode)
}


func generateCythonClassNormal(cls: WrapClass, class_vars: String, dispatch_mode: Bool) -> String {
    let _class = cls.title
    if dispatch_mode {
        let events = cls.dispatch_events.map{"\"on_\($0)\""}
        let string = """
        \(if: cls.singleton, "#cdef public void* \(_class)_voidptr")
        cdef public \(_class) \(_class)_shared
        #cdef list \(_class)_events = [\"on_\(cls.title)_default\", \(events.joined(separator: ", "))]

        cdef class \(_class)(EventDispatcher):
        \(class_vars)
            @staticmethod
            def shared():
                global \(_class)_shared
                if \(_class)_shared != None:
                    return \(_class)_shared
                return None

            def __init__(self,object callback_class):
                \(if: !cls.singleton, "self.callback_class = callback_class")
                global \(_class)_shared
                if \(_class)_shared == None:
                    \(_class)_shared = self
                \(if: cls.singleton,
                """
                #global \(_class)_voidptr
                #\t\t\(_class)_voidptr = <PythonObject>callback_class
                #\t\t\(_class)_voidptr = <PyObject*>callback_class
                """
                )
                
        """
        
        return string.replacingOccurrences(of: "    ", with: "\t")
    }
    
    
    return """
    #cdef public void* \(_class)_voidptr
    cdef public \(_class) \(_class)_shared

    cdef class \(_class)(object):
    \(class_vars)
        @staticmethod
        def shared():
            global \(_class)_shared
            if \(_class)_shared != None:
                return \(_class)_shared

        def __init__(self,callback_class: object = None):
            global \(_class)_shared
            if \(_class)_shared == None:
                \(_class)_shared = self
    
    """.replacingOccurrences(of: "    ", with: "\t")
}




func extendCythonClass(cls: WrapClass, options: [CythonClassOptionTypes]) -> String {
    
    var output: [String] = []
    
    for t in options {
        switch t {
        case .init_callstruct:
            let string = """
                cdef \(cls.title)Callbacks callbacks = [
                    \(cls.functions.filter{$0.has_option(option: .callback)}.map({"\t\(cls.title)_\($0.name)"}).joined(separator: ",\n\t\t"))
                    ]
                    set_\(cls.title)_Callback(callbacks\(if: !cls.singleton, ", <CythonClass>self"))
            """
            output.append(string)
        case .event_dispatch:
            
            output.append("")
        case .swift_functions:
            let func_string = cls.functions.filter{$0.has_option(option: .swift_func) && !$0.has_option(option: .callback)}.map{"self._\($0.name)_ = func_struct.\($0.name)"}.joined(separator: "\n\t\t")
            output.append("""
            cdef set_swift_functions(self, \(cls.title)SwiftFuncs func_struct ):
                    \(func_string)
                    print("set_swift_functions")

            """)
        
        }
    }
    
    return output.joined(separator: "\n\t")
}

func extendCythonClassNew(cls: WrapClass, options: [CythonClassOptionTypes]) -> String {
//    if !cls.singleton {
//        return ""
//    }
    
    
    var output: [String] = []
    
    for t in options {
        switch t {
        case .init_callstruct:
            let string = """
                cdef \(cls.title)Callbacks callbacks = [
                    \(cls.functions.filter{$0.has_option(option: .callback)}.map({"\t\(cls.title)_\($0.name)"}).joined(separator: ",\n\t\t"))
                    ]
                    set_\(cls.title)_Callback(<PyObject*>callback_class\(if: !cls.singleton, ", <CythonClass>self"))
            """
            output.append(string)
        case .event_dispatch:
            
            output.append("")
        case .swift_functions:
            let func_string = cls.functions.filter{$0.has_option(option: .swift_func) && !$0.has_option(option: .callback)}.map{"self._\($0.name)_ = func_struct.\($0.name)"}.joined(separator: "\n\t\t")
            output.append("""
            cdef set_swift_functions(self, \(cls.title)SwiftFuncs func_struct ):
                    \(func_string)
                    print("set_swift_functions")

            """)
        
        }
    }
    
    return output.joined(separator: "\n\t")
}

func extendCythonClassTempNew(cls: WrapClass, options: [CythonClassOptionTypes]) -> String {
    
    var output: [String] = []
    
    for t in options {
        switch t {
        case .init_callstruct:
            if cls.callbacks_count == 0 || cls.swift_object_mode { continue }
            //set_\(cls.title)_Callback(<PyObject*>callback_class\(if: !cls.singleton, ", <CythonClass>self"))
            let string = """
                set_\(cls.title)_Callback(<PyObject*>callback_class\(if: !cls.singleton, ""))
            """
            output.append(string)
        case .event_dispatch:
            
            output.append("")
        case .swift_functions:
            let func_string = cls.functions.filter{$0.has_option(option: .swift_func) && !$0.has_option(option: .callback)}.map{"self._\($0.name)_ = func_struct.\($0.name)"}.joined(separator: "\n\t\t")
            output.append("""
            cdef set_swift_functions(self, \(cls.title)SwiftFuncs func_struct ):
                    \(func_string)
                    print("set_swift_functions")

            """)
        
        }
    }
    
    return output.joined(separator: "\n\t")
}


func generateSwiftObjectClass(module_name: String, cls: WrapClass, class_vars: String, dispatch_mode: Bool) -> String {
    let _class = cls.title
    
    
    return """
    
    cdef class \(_class):
        \(class_vars)
    
        cdef void* __ptr
    
        def __init__(self):
            self.__ptr = \(_class)_pyInitializer(<PyObject*>self)
        
        def __cinit__(self):
            ...
        
        def __dealloc__(self):
            \(_class)_pyDeinitializer(self.__ptr)
    
    """.replacingOccurrences(of: "    ", with: "\t")
}



func generateGlobalEnums(mod: WrapModule, options: [EnumGeneratorOptions]) -> String {
    var string: [String] = []
    for item in mod.custom_enums {
        if options.contains(.cython) {
            let keys = item.keys.map{ key in
                "\(key.key) = \(key.value)"}
            
            string.append("""
            cpdef enum py\(item.title):
                \(keys.joined(separator: newLineTab))
            """)
        }
        if options.contains(.cython_extern) {
            let keys = item.keys.map{ key in
                "\(key.key) = \(key.valueAsString)"}
            string.append("""
            ctypedef enum \(item.title):
                \(tab + keys.joined(separator: ",\(newLineTabTab)"))
            
            """)
        }
        if options.contains(.python) {
            if item.type != .object {
                let keys = item.keys.map{ key in
                    "\(key.key) = \(key.valueAsString)"}
                string.append("""
                class \(item.title)(IntEnum):#abc
                    \(keys.joined(separator: ",\(newLineTab)"))
                
                """)
            }
            
        }
        if options.contains(.c) {
            let keys = item.keys.map{ key in
                "\(key.key) = \(key.value)"}
//            string.append("""
//            typedef enum
//            {
//                \(keys.joined(separator: ",\(newLineTab)"))
//            } \(item.title);
//            """)
        }
        if options.contains(.swift) {
            if item.type != .object {
                let keys = item.keys.map{ key -> String in
                    if key.key == "default" {
                        return "case `default` = \(key.valueAsAny)"
                    }
                    return "case \(key.key) = \(key.valueAsAny)"
                        
                }
                string.append("""
                enum \(item.title): Int {
                    \(keys.joined(separator: "\(newLineTab)"))
                    }
                """)
            }
            
        }
    }
    
    
    if options.contains(.c) {
        return string.joined(separator: newLine)
    }
    return string.joined(separator: newLineTab)
}

func generateEnums(cls: WrapClass, options: [EnumGeneratorOptions]) -> String {
    var string: [String] = []
    //for option in options {
    if options.contains(.dispatch_events) {
            if let dis_dec = cls.decorators.filter({$0.type=="EventDispatch"}).first {
                let events = (dis_dec.dict[0]["events"] as! [String])
                if options.contains(.cython) {
                    string.append("""
                    ctypedef enum \(cls.title)Event:
                        \t\(cls.title)_default
                        \(tab + events.joined(separator: newLineTabTab))
                        
                    """)
                }
                else if options.contains(.objc) {
//                    string.append("""
//                    typedef NS_ENUM(NSUInteger, \(cls.title)Events) {
//                        \(events.joined(separator: "," + newLineTab))
//                    };
//                    """)
                    
                    string.append("""
                    typedef enum { \(cls.title)_default\(if: events.count != 0, ",") \(events.joined(separator: "," + newLineTab)) } \(cls.title)Events;
                    """)
                }
                
                else if options.contains(.swift) {
                    let dispatch_event_title = "\(cls.title)DispatchEvent"
                    let dis_events = events.map{ e -> String in
                        "static let on_\(e) = \(dispatch_event_title)(rawValue: \"on_\(e)\")!"
                    }
                    string.append("""
                struct \(cls.title)DispatchEvent: RawRepresentable {
                    init?(rawValue: PythonPointer) {
                        self.rawValue = rawValue
                    }
                    
                    init?(rawValue: String) {
                        self.rawValue = PyUnicode_FromString(rawValue)!
                    }
                    
                    var rawValue: PythonPointer
                    
                    typealias RawValue = PythonPointer
                    
                    static let on_default = \(dispatch_event_title)(rawValue: \"on_default\")!
                    \(dis_events.joined(separator: newLineTab))
                }
                """)
                }
            }
            else {
                
            }
            
        }
    else {
        for Enum in wrap_module_shared.custom_enums.filter({$0.type != .object}) {
            let cases = Enum.keys.map{ e -> String in
                "static let \(e.key) = \(Enum.title)(rawValue: \"\(e.key)\")!"
            }
            string.append("""
        struct \(Enum.title): RawRepresentable {
            init?(rawValue: PythonPointer) {
                self.rawValue = rawValue
            }
            
            init?(rawValue: String) {
                self.rawValue = PyUnicode_FromString(rawValue)!
            }
            
            var rawValue: PythonPointer
            
            typealias RawValue = PythonPointer
            
            //static let on_default = \(Enum.title)(rawValue: \"on_default\")!
            \(cases.joined(separator: newLineTab))
        }
        """)
        }
    }
    //}
    return string.joined(separator: newLineTab)
}





func generateObjectEnums(mod: WrapModule, options: EnumGeneratorOptions) -> String {
    var output = [String]()
    let object_enums = mod.custom_enums.filter{$0.type == .object}
    switch options {
    case .cython_extern:
        break
    case .cython:
        break
    case .python:
        break

    case .swift:
        for Enum in object_enums {
                let cases = Enum.keys.map{ e -> String in
                    "static let \(e.key) = \(Enum.title)(rawValue: \"\(e.valueAsAny)\")!"
                }
            output.append( """
                struct \(Enum.title): RawRepresentable {
                    init?(rawValue: PythonPointer) {
                        self.rawValue = rawValue
                    }
                    
                    init?(rawValue: String) {
                        self.rawValue = PyUnicode_FromString(rawValue)!
                    }
                    
                    var rawValue: PythonPointer
                    
                    typealias RawValue = PythonPointer
                    
                    //static let on_default = \(Enum.title)(rawValue: \"on_default\")!
                    \(cases.joined(separator: newLineTab))
                }
                """)
                }
    default:
        break
    }
    return output.joined(separator: newLine)
}








//func generateDispatchFunctions(cls: WrapClass, objc: Bool) {
//    let decoder = JSONDecoder()
//    
//    //for event in cls.dispatch_events {
//    var dispatch_args: JSON = []
//    var dis_arg_count = 0
//    if !cls.singleton {
//        dispatch_args.arrayObject!.append([
//            "name": "cls",
//            "type": "CythonClass",
//            "idx": 0
//        ])
//        dis_arg_count += 1
//    }
//    dispatch_args.arrayObject!.append(contentsOf: [
//        [
//            "name":"event",
//            "type":"object",
//            "other_type": "\(cls.title)DispatchEvent",
//            "options": ["enum_", "dispatch"],
//            "idx": dis_arg_count
//        ],
//        [
//            "name":"*largs",
//            "type":"object",
//            "options": ["data","json"],
//            "idx": dis_arg_count + 1
//        ],
//        [
//            "name":"**kwargs",
//            "type":"object",
//            "options": ["data","json"],
//            "idx": dis_arg_count + 2
//        ]])
//        
//        let dispatch_function: JSON = [
//            "name":"dispatch",
//            "args": dispatch_args,
//            //"swift_func": false,
//            "options": ["callback","dispatch"],
//            "returns": [
//                "name": "void",
//                "type": "void",
//                "idx": 0,
//                "options": ["return_"],
//            ]
//        ]
//        
//        
//        let function = try! decoder.decode(WrapFunction.self, from: dispatch_function.rawData())
//    function.wrap_class = cls
//    function.set_args_cls(cls: cls)
//        cls.functions.insert(function, at: 0)
//    //}
// 
//}






enum functionCodeType {
    case normal
    case python
    case cython
    case objc
    case send
    case call
    case dispatch
}



//func generateGlobalFunctionCode(title: String, function: WrapFunction) -> String {
//    var output: [String] = []
// 
//            if function.returns.type != .void {
// 
//                output.append("return <object>\(title)_\(function.name)(\(function._args_.map{$0.python_call_arg}.joined(separator: ", ")))")
//            } else {
//                output.append("\(title)_\(function.name)(\(function._args_.map{$0.python_call_arg}.joined(separator: ", ")))")
//            }
//
//    return output.joined(separator: "\n\t")
//}

func generateSwiftClassCode(module_name: String, cls: WrapClass, class_vars: String, dispatch_mode: Bool) -> String {
    let _class = cls.title
    
    
    return """
    class \(_class) {

        init() {
    
        }
        def __init__(self):
            self.__ptr = \(_class)_initializer(<PyObject*>self)
        
        def __cinit__(self):
            ...
        
        def __dealloc__(self):
            free(self.__ptr)
    }
    """.replacingOccurrences(of: "    ", with: "\t")
}









enum handlerFunctionCodeType {
    case normal
    case python
    case cython
    case init_delegate
    case objc_h
    case objc_m
    case swift
    case protocols
    case send
    case callback
}
//
//func generateGlobalSwiftFunctions(mod: WrapModule) -> String {
//    var output: [String] = []
//    
//    for function in mod.functions {
//       //let send_self = function.has_option(option: .send_self)
////                    let swift_return = "\(if: function.returns.type != .void, "-> \(function.returns.swift_type)", "")"
//       let swift_return = "\(if: function._return_.type != .void, "-> PythonPointer", "")"
////                    var func_args = function.args.map{ arg -> String in
////                        let as_object = arg.has_option(.py_object)
////                        //if as_object {return "\(arg.name): PythonObject"}
////                        return "\(arg.name): \(arg.swiftCallArgs)"
////                    }
//       let func_args = function._args_.map{a in a.swift_send_call_arg}
//       let _func_args = func_args.joined(separator: ", ")
//       var codelines: [String] = []
//       if (function.args.first(where: { (arg) -> Bool in arg.has_option(.codable) }) != nil) {
//           codelines.append("let decoder = JSONDecoder()")
//           //let wrap_module = try! decoder.decode(WrapModule.self, from: data!)
//       }
//       for arg in function.args {
//           if arg.has_option(.codable) {
//               codelines.append("let \(arg.other_type!.titleCase()) = try! decoder.decode(\(if: arg.has_option(.list), "[\(arg.other_type!)]", arg.other_type!).self, from: \(arg.name).data)")
//           }
//       }
//       if codelines.count != 0 {codelines.append("")}
////                    let header_args = function.args.map{ arg -> String in
////                        //if arg.asObject { return "_ \(arg.name): PythonObject" }
////                        if arg.asObject { return "_ \(arg.name): PythonPointer" }
////                        if arg.type == .other {
////                            if wrap_module_shared.enumNames.contains(arg.other_type) {
////                                return "_ \(arg.name): Int"
////                            }
////                        }
////                        return "_ \(arg.name): \(arg.convertPythonType(options: [.swift]))"
////                    }.joined(separator: ", ")
//       let h_args_count = function._args_.count
//       let header_args = function._args_.map{a in a.swift_send_func_arg}.joined(separator: ", ")
//
//           output.append("""
//           //\(function.name)
//           @_silgen_name(\"\(mod.filename)_\(function.name)\")
//           func \(mod.filename)_\(function.name)(\(header_args)) \(swift_return) {
//               \(codelines.joined(separator: newLineTab))\(if: function._return_.type != .void, "return ")\(function._return_.convert_return_send(arg: "\(function.name)(\(_func_args))"))
//           }
//           """)
//                   
//    }
//    return output.joined(separator: newLine)
//}

//func generateHandlerFuncs(cls: WrapClass, options: [handlerFunctionCodeType]) -> String {
//    var output: [String] = []
//    let objc_m = options.contains(.objc_m)
//    let singleton = cls.singleton
//    
//    if options.contains(.objc_h) {
//        for option in options {
//            switch option {
//            case .init_delegate:
//                if cls.swift_object_mode {
//                    output.append("void \(cls.title)_pyInitializer(id<\(cls.title)_Delegate> _Nonnull callback);")
//                    
//                    
//                } else {
//                    output.append("void Init\(cls.title)_Delegate(id<\(cls.title)_Delegate> _Nonnull callback);")
//                }
//                
//            case .callback:
//                continue
//            default:
//                //output.append("void set_\(cls.title)_Callback(struct \(cls.title)Callbacks callback\(if: !cls.singleton, ", CythonClass cython_class"));")
//                if cls.swift_object_mode {
//                    output.append("void* \(cls.title)_pyInitializer(PyObject* py_cls);")
//                    output.append("void \(cls.title)_pyDeinitializer(void* __ptr);")
//                } else {
//                    if cls.callbacks_count == 0 { continue }
//                    output.append("void set_\(cls.title)_Callback(PyObject* callback\(if: !cls.singleton, ", CythonClass cython_class"));")
//                }
//            }
//        }
//    }
//
//    if options.contains(.swift) {
//        for option in options {
//            switch option {
//            case .init_delegate:
////                output.append("""
////                func Init\(cls.title)_Delegate(delegate: \(cls.title)_Delegate) {
////                    \(cls.title.lowercased()) = delegate
////                    print("setting \(cls.title) delegate \\(String(describing: \(cls.title.lowercased())))")
////                }
////                """)
//                if cls.swift_object_mode {
//                    let has_cb = cls.functions.filter({$0.has_option(option: .callback)}).count > 0
//                    //let has_init = cls.init_function != nil
//                    var init_args = ""
//                    var header_args = ""
//                    
//                    if let init_func = cls.init_function {
//                        init_args = init_func._args_.map({ a in
//                            a.swift_send_call_arg
//                        }).joined(separator: ", ")
//                        
//                        if init_func.has_option(option: .send_self) {
//                            init_args = "py_cls: py_cls" + init_args
//                        }
//                        if init_func._args_.count > 0 {
//                            init_args.append(", ")
//                            header_args = ", " + init_func._args_.map{a in a.swift_send_func_arg}.joined(separator: ", ")
//                        }
//                        
//                        
//                    }
//                    
//                    output.append("""
//                    @_silgen_name(\"\(cls.title)_pyInitializer\")
//                    func \(cls.title)_pyInitializer(_ py_cls: PythonPointer\(header_args)) -> UnsafeMutableRawPointer {
//                        let new_cls = \(cls.title)(\(init_args))
//                        \(if: has_cb, "new_cls.py_call = \(cls.title)PyCallback(callback: py_cls)")
//                        return Unmanaged.passRetained(new_cls).toOpaque()
//                    }
//                    """)
//                    output.append("""
//                    @_silgen_name(\"\(cls.title)_pyDeinitializer\")
//                    func \(cls.title)_pyDeinitializer(_ __ptr: UnsafeMutableRawPointer) {
//                        let unmanaged_ptr = Unmanaged<\(cls.title)>.fromOpaque(__ptr)
//                        unmanaged_ptr.release()
//                    }
//                    """)
//                    //output.append("void \(cls.title)_pyDeinitializer(void* __ptr);")
//                } else {
//                    output.append("""
//                    func Init\(cls.title)_Delegate(delegate: \(cls.title)_Delegate) {
//                        \(cls.title.lowercased()) = delegate
//                        print("setting \(cls.title) delegate \\(String(describing: \(cls.title.lowercased())))")
//                    }
//                    """)
//                }
//                
//            case .callback:
//                if cls.swift_object_mode { continue }
//                //let call_args = cls.functions.filter{!$0.has_option(option: .callback) && !$0.has_option(option: .swift_func) && !$0.has_option(option: .dispatch)}.map{"\($0.name): \(cls.title)_\($0.name)"}.joined(separator: ", ")
//                var call_title = cls.title//.titleCase()
//                call_title.removeFirst()
//                output.append("""
//                @_silgen_name(\"set_\(cls.title)_Callback\")
//                func set_\(cls.title)_Callback(_ callback: PythonPointer\(if: !cls.singleton, ", _ cython_class: CythonClass")) {
//                    print("setting callback \\(String(describing: \(cls.title.lowercased())))")
//                    \(cls.title.lowercased()).set_\(cls.title)_Callback(callback: \(cls.title)PyCallback(callback: callback)\(if: !cls.singleton, ", cython_class: cython_class"))
//                    
//                }
//                """)
//                
//            case .send:
//                //output.append("\(generateSendFunctions(module: self , objc: true))")
//                //\(call_title)Callback = \(cls.title)PyCallback(callback: callback\(if: !cls.singleton, "cython_class: cython_class"))
//                //let calls = \(cls.title)Sends(\(call_args))
//                for function in cls.functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .swift_func)}) {
//                    //let send_self = function.has_option(option: .send_self)
////                    let swift_return = "\(if: function.returns.type != .void, "-> \(function.returns.swift_type)", "")"
//                    let swift_return = "\(if: function._return_.type != .void, "-> PythonPointer", "")"
////                    var func_args = function.args.map{ arg -> String in
////                        let as_object = arg.has_option(.py_object)
////                        //if as_object {return "\(arg.name): PythonObject"}
////                        return "\(arg.name): \(arg.swiftCallArgs)"
////                    }
//                    let func_args = function._args_.map{a in a.swift_send_call_arg}
//                    let _func_args = func_args.joined(separator: ", ")
//                    var codelines: [String] = []
//                    if (function.args.first(where: { (arg) -> Bool in arg.has_option(.codable) }) != nil) {
//                        codelines.append("let decoder = JSONDecoder()")
//                        //let wrap_module = try! decoder.decode(WrapModule.self, from: data!)
//                    }
//                    for arg in function.args {
//                        if arg.has_option(.codable) {
//                            codelines.append("let \(arg.other_type!.titleCase()) = try! decoder.decode(\(if: arg.has_option(.list), "[\(arg.other_type!)]", arg.other_type!).self, from: \(arg.name).data)")
//                        }
//                    }
//                    if codelines.count != 0 {codelines.append("")}
////                    let header_args = function.args.map{ arg -> String in
////                        //if arg.asObject { return "_ \(arg.name): PythonObject" }
////                        if arg.asObject { return "_ \(arg.name): PythonPointer" }
////                        if arg.type == .other {
////                            if wrap_module_shared.enumNames.contains(arg.other_type) {
////                                return "_ \(arg.name): Int"
////                            }
////                        }
////                        return "_ \(arg.name): \(arg.convertPythonType(options: [.swift]))"
////                    }.joined(separator: ", ")
//                    let h_args_count = function._args_.count
//                    let header_args = function._args_.map{a in a.swift_send_func_arg}.joined(separator: ", ")
//                    if cls.swift_object_mode {
//                        output.append("""
//                        //\(function.name)
//                        @_silgen_name(\"\(cls.title)_\(function.name)\")
//                        func \(cls.title)_\(function.name)(_ __ptr: UnsafeMutableRawPointer\(if: h_args_count > 0, ", \(header_args)")) \(swift_return) {
//                            let \(cls.title.lowercased()) = Unmanaged<\(cls.title)>.fromOpaque(__ptr).takeUnretainedValue()
//                            \(codelines.joined(separator: newLineTab))\(if: function._return_.type != .void, "return ")\(function._return_.convert_return_send(arg: "\(cls.title.lowercased()).\(function.name)(\(_func_args))"))
//                        }
//                        """)
//                    } else {
//                        output.append("""
//                        //\(function.name)
//                        @_silgen_name(\"\(cls.title)_\(function.name)\")
//                        func \(cls.title)_\(function.name)(\(header_args)) \(swift_return) {
//                            \(codelines.joined(separator: newLineTab))\(if: function._return_.type != .void, "return ")\(function._return_.convert_return_send(arg: "\(cls.title.lowercased()).\(function.name)(\(_func_args))"))
//                        }
//                        """)
//                    }
//                }
//                
//                
//            default:
//                continue
//            }
//        }
//    }
//    return output.joined(separator: newLine)
//}


func createSetSwiftFunctions(cls: WrapClass) {
//    var json = JSON()
//    var function: JSON = [
//        "name": "set_SwiftFunctions"
//    ]
}

func createRecipe(title: String) -> String{
    """
    from kivy_ios.toolchain import CythonRecipe

    class \(title)(CythonRecipe):
        version = "master"
        url = "src"
        library = "lib\(title).a"
        depends = ["python3", "hostpython3"]

        # Frameworks you used
        pbx_frameworks = []

        def install(self):
            self.install_python_package(
                # Put the extension name here
                name=self.so_filename("\(title)"), is_dir=False)

    recipe = \(title)()
    """
}

func createSetupPy(title: String) -> String {
    """
    from distutils.core import setup, Extension

    setup(name='\(title)',
          version='1.0',
          ext_modules=[
              Extension('\(title)', # Put the name of your extension here
                        ['\(title).c'],
                        libraries=[],
                        library_dirs=[],
                        extra_compile_args=['-w'],
                        )
          ]
        )
    """
}

func createSetupPy_Module(title: String, files: [String]) -> String {
    let extensions = files.map{ f -> String in
        """
        Extension('\(title).\(f)', # Put the name of your extension here
                ['\(f).c'],
                libraries=[],
                library_dirs=[],
                extra_compile_args=['-w'],
                )
        """
    }
    return """
    from distutils.core import setup, Extension

    setup(name='\(title)',
        version='1.0',
        ext_modules=[
        \(extensions.joined(separator: ",\n\t\t"))
        ])
    """
}







func _createSetupPy(title: String) -> String {
    """
    from distutils.core import setup, Extension

    setup(name='\(title)',
          version='1.0',
          ext_modules=[
              Extension('\(title)', # Put the name of your extension here
                        ['\(title).c', '_\(title).m'],
                        libraries=[],
                        library_dirs=[],
                        extra_compile_args=['-ObjC','-w'],
                        )
          ]
        )
    """
}
