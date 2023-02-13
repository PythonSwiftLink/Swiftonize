//
//  Enums.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 28/12/2021.
//

import Foundation

enum PythonTypeConvertOptions {
    case objc
    case header
    case c_type
    case swift
    case pyx_extern
    //case is_list
    case py_mode
    case use_names
    case dispatch
    case protocols
    case call
    case send
    case ignore_list
    case cython_class
    case callback
}

enum PythonSendArgTypes {
    case list
    case data
}


enum PythonType: String, CaseIterable,Codable {
    case int
    case long
    case ulong
    case uint
    case int32
    case uint32
    case int8
    case char
    case uint8
    case uchar
    case ushort
    case short
    case int16
    case uint16
    case longlong
    case ulonglong
    case float
    case double
    case float32
    case str
    case bytes
    case data
    case json
    case jsondata
    case list
    case sequence
    case memoryview
    case tuple
    case byte_tuple
    case object
    case bool
    case void
    case None
    case CythonClass
    case callable
    case other
    case optional = "Optional"
    case error = "Error"
    case url = "URL"
    
    var swiftType: String {
        //swiftTypeFromPythonType(T: self) ?? "PyPointer"
        
        switch self {
        case .object:
            return "PyPointer"
        case .url, .error:
            return rawValue
        default:
            return SWIFT_TYPES[self.rawValue] ?? "PyPointer"
        }
//        if self == .object {
//            return "PyPointer"
//        }
//        return SWIFT_TYPES[self.rawValue] ?? "PyPointer"
    }
}

//enum PythonTypeNew: PyStringEnum, CaseIterable {
//    case int
//    case long
//    case ulong
//    case uint
//    case int32
//    case uint32
//    case int8
//    case char
//    case uint8
//    case uchar
//    case ushort
//    case short
//    case int16
//    case uint16
//    case longlong
//    case ulonglong
//    case float
//    case double
//    case float32
//    case str
//    case bytes
//    case data
//    case json
//    case jsondata
//    case list
//    case sequence
//    case memoryview
//    case tuple
//    case byte_tuple
//    case object
//    case bool
//    case void
//    case None
//    case CythonClass
//    case other
//}

enum pyx_types: String {
    case int32
    case uint32
}

enum CythonClassOptionTypes {
    case init_callstruct
    case event_dispatch
    case swift_functions
}

enum EnumGeneratorOptions {
    case cython_extern
    case cython
    case python
    case c
    case objc
    case dispatch_events
    case swift
}

enum FunctionPointersOptions {
    case exclude_swift_func
    case exclude_callback
    case excluded_callbacks
    case excluded_callbacks_only
}

enum StructTypeOptions {
    case python
    case pyx
    case objc
    case c
    case swift
    case callbacks
    case event_dispatch
    case swift_functions
}

enum EnumTypeOptions {
    case python
    case c
    case swift
}

enum SendFunctionOptions {
    case objc
    case python
}

enum WrapperTargetType: String {
    case _struct = "struct"
    case _class = "class"
}


enum WrapperClassOptions: String {
    case py_init
    case debug_mode
    case type
    case target
    case service_mode
}
