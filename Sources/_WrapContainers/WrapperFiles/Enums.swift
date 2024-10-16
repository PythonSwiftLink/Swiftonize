//
//  Enums.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 28/12/2021.
//

import Foundation
import PySwiftCore
//import PythonTypeAlias

public enum PythonTypeConvertOptions {
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

public enum PythonSendArgTypes {
    case list
    case data
}

public enum OtherType {
    case error
    case url
    case swift_type(name: String, delegate: Bool)
}

public enum PythonType: String, CaseIterable,Codable {
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
    case array
    case Array
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
    
    public var __swiftType__: String? {
        switch self {
        case .url, .error:
            return rawValue
        case .other:
            return nil
        //case .callable:
        
        default:
            return __SWIFT_TYPES__[self]
        }
    }
    
    public var swiftType: String {
        //swiftTypeFromPythonType(T: self) ?? "PyPointer"
        
        switch self {
        case .url, .error:
            return rawValue
        case .other:
            return rawValue
        default:
            return __SWIFT_TYPES__[self] ?? "PyPointer"
        }
//        if self == .object {
//            return "PyPointer"
//        }
//        return SWIFT_TYPES[self.rawValue] ?? "PyPointer"
    }
}
public extension PythonType {
    
    var annotation: TypeAnnotationSyntax {
        
        return .init(type: syntaxType)
    }
    
    var syntaxType: TypeSyntax {
        var T: Any = Void.self
        
        switch self {
        case .int:
            T = Int.self
        case .long:
            T = Int.self
        case .ulong:
            T = UInt.self
        case .uint:
            T = UInt.self
        case .int32:
            T = Int32.self
        case .uint32:
            T = UInt32.self
        case .int8:
            T = Int8.self
        case .char:
            T = Int8.self
        case .uint8:
            T = UInt8.self
        case .uchar:
            T = UInt8.self
        case .ushort:
            T = UInt16.self
        case .short:
            T = Int16.self
        case .int16:
            T = Int16.self
        case .uint16:
            T = UInt16.self
        case .longlong:
            T = Int64.self
        case .ulonglong:
            T = UInt64.self
        case .float:
            T = Double.self
        case .double:
            T = Double.self
        case .float32:
            T = Float.self
        case .str:
            T = String.self
        case .bytes:
            T = String.self
        case .data:
            T = Data.self
        case .json:
            T = String.self
        case .jsondata:
            T = Data.self
        case .list:
            break
        case .sequence:
            break
        case .Array, .array:
            break
        case .memoryview:
            T = "PyPointer"
        case .tuple:
            break
        case .byte_tuple:
            break
            //case .object:
            //    T = PythonObject.self
        case .object:
            T = "PyPointer"
        case .bool:
            T = Bool.self
        case .void:
            T = Void.self
        case .None:
            T = Void.self
        case .CythonClass:
            T = PythonPointer.self
        case .callable:
            T = "PyPointer"
        case .url:
            T = URL.self
        case .error:
            T = Error.self
        case .optional: break
        case .other:
            break
        }
        
        return .init(stringLiteral: String(describing: T))
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

public enum CythonClassOptionTypes {
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

public enum WrapperTargetType: String {
    case _struct = "struct"
    case _class = "class"
}


enum WrapperClassOptions: String {
    case py_init
    case debug_mode
    case type
    case target
    case service_mode
    case new
    case unretained
	case pytype
}

import SwiftSyntax
import SwiftSyntaxBuilder

public enum WrapClassBase: String {
    case NSObject
    case SwiftBase
    case SwiftObject
	
	
	case Iterable
	case Iterator
	case Collection
	
    case MutableMapping
	case Mapping
	
    case Sequence
	case MutableSequence
	
	case Set
	case MutableSet
	
	case Buffer
	case Bytes
	
	case AsyncIterable
	case AsyncIterator
	case AsyncGenerator
	
    case Number
	
	case Str = "String"
	case Float
	case Int
	case Hashable
	case Callable
}
