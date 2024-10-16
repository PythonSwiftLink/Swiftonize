//
//  Converters.swift
//  KivySwiftLink2
//
//  Created by MusicMaker on 15/10/2021.
//

import Foundation
import PySwiftCore
//import PythonTypeAlias
//import PythonKit
public let tab = "\t"
public let tabNewLine = "\t\n"
public let newLine = "\n"
public let newLineTab = "\n\t"
public let newLineTabTab = "\n\t\t"

//class PythonPointer {}

let TYPE_SIZES: [String:Int] = [
    "PythonCallback": 0,
    "CythonClass": MemoryLayout<UnsafeRawPointer>.size,
    "int": MemoryLayout<CLong>.size,
    "long": MemoryLayout<CLong>.size,
    "ulong": MemoryLayout<CUnsignedLong>.size,
    "uint": MemoryLayout<CUnsignedLong>.size,
    "int32": MemoryLayout<CInt>.size,
    "uint32": MemoryLayout<CUnsignedInt>.size,
    "int8": MemoryLayout<CChar>.size,
    "char": MemoryLayout<CChar>.size,
    "uint8": MemoryLayout<CUnsignedChar>.size,
    "uchar": MemoryLayout<CUnsignedChar>.size,
    "short": MemoryLayout<CShort>.size,
    "ushort": MemoryLayout<CUnsignedShort>.size,
    "int16": MemoryLayout<CShort>.size,
    "uint16": MemoryLayout<CUnsignedShort>.size,
    "longlong": MemoryLayout<CLongLong>.size,
    "ulonglong": MemoryLayout<CUnsignedLongLong>.size,
    "float": MemoryLayout<CDouble>.size,
    "double": MemoryLayout<CDouble>.size,
    "float32": MemoryLayout<CFloat>.size,
    "object": MemoryLayout<UnsafeRawPointer>.size,
    "data": MemoryLayout<CUnsignedChar>.size,
    "bytes": MemoryLayout<CChar>.size,
    "jsondata": MemoryLayout<CUnsignedChar>.size,
    "json": MemoryLayout<CChar>.size,
    "bool": MemoryLayout<CBool>.size,
    "str": MemoryLayout<CChar>.size,
    "void": MemoryLayout<Void>.size,
    "callable": MemoryLayout<PythonPointer>.size,
    "Optional": MemoryLayout<PythonPointer>.size
    
]

let PYCALL_TYPES = [
    "PythonCallback": "PythonCallback",
    "int": "Int",
    "long": "Int",
    "ulong": "UInt",
    "uint": "UInt",
    "int32": "Int32",
    "uint32": "UInt32",
    "int8": "Int8",
    "char": "Int8",
    "short": "Int16",
    "uint8": "UInt8",
    "uchar": "UInt8",
    "ushort": "UInt16",
    "int16": "Int16",
    "uint16": "UInt16",
    "longlong": "Int64",
    "ulonglong": "UInt64",
    "float": "Double",
    "double": "Double",
    "float32": "Float",
    //"object": "PythonObject",
    "object": "PyObject*",
    "data": "Data",
    "bytes": "PythonBytes",
    "jsondata": "PythonJsonData",
    "str": "PythonString"
]

let __SWIFT_TYPES__: [PythonType:String] = [
    .int: "Int",
    .long: "Int",
    .ulong: "UInt",
    .uint: "UInt",
    .int32: "Int32",
    .uint32: "UInt32",
    .int8: "Int8",
    .char: "Int8",
    .short: "Int16",
    .uint8: "UInt8",
    .uchar: "UInt8",
    .ushort: "UInt16",
    .int16: "Int16",
    .uint16: "UInt16",
    .longlong: "Int64",
    .ulonglong: "UInt64",
    .float: "Double",
    .double: "Double",
    .float32: "Float",
    //"object": "PythonObject",
    .object: "PyPointer",
    .data: "Data",
    .jsondata: "PythonPointer",
    .json: "PythonPointer",
    .bytes: "PythonPointer",
    .str: "String",
    .bool: "Bool",
    .void: "Void",
    
]

let SWIFT_TYPES = [
    "PythonCallback": "PythonCallback",
    "int": "Int",
    "long": "Int",
    "ulong": "UInt",
    "uint": "UInt",
    "int32": "Int32",
    "uint32": "UInt32",
    "int8": "Int8",
    "char": "Int8",
    "short": "Int16",
    "uint8": "UInt8",
    "uchar": "UInt8",
    "ushort": "UInt16",
    "int16": "Int16",
    "uint16": "UInt16",
    "longlong": "Int64",
    "ulonglong": "UInt64",
    "float": "Double",
    "double": "Double",
    "float32": "Float",
    //"object": "PythonObject",
    "object": "PythonPointer",
    "data": "Data",
    "jsondata": "PythonPointer",
    "json": "PythonPointer",
    "bytes": "PythonPointer",
    "str": "String",
    "bool": "Bool",
    "void": "Void"
]

let MALLOC_TYPES = [
    "PythonCallback": "PythonCallback",
    "int": "int",
    "long": "long",
    "ulong": "unsigned ",
    "uint": "UInt",
    "int32": "Int32",
    "uint32": "UInt32",
    "int8": "Int8",
    "char": "Int8",
    "short": "Int16",
    "uint8": "UInt8",
    "uchar": "UInt8",
    "ushort": "UInt16",
    "int16": "Int16",
    "uint16": "UInt16",
    "longlong": "Int64",
    "ulonglong": "UInt64",
    "float": "Double",
    "double": "Double",
    "float32": "Float",
    //"object": "PythonObject",
    "object": "PythonPointer",
    "data": "PythonData",
    "jsondata": "PythonJsonData",
    "json": "PythonJsonString",
    "bytes": "PythonBytes",
    "str": "PythonString",
    "bool": "Bool"
]

class CythonClass {}

enum PythonObjectAsSwiftTypeOptions {
    case pre
    case post
    case header
    case protocols
    case callback
}

func PythonObjectAsSwiftType(arg: WrapArg, option: PythonObjectAsSwiftTypeOptions) -> String {
    let name = arg.name
    let sequence = arg.has_option(.sequence)
    let list = arg.has_option(.list)
    let memoryview = arg.has_option(.memoryview)
    let as_object = arg.has_option(.py_object)
    var T: Any = Void.self
    var otherT = ""
    
    if option == .pre {
        //if as_object { return "PythonObject"}
        if as_object { return "PythonPointer"}
    }
    
    switch arg.type {
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
        T = Array<Any>.self
    case .sequence:
        T = Array<Any>.self
    case .Array, .array:
        T = Array<Any>.self
    case .memoryview:
        T = PythonPointer.self
    case .tuple:
        T = Array<Any>.self
    case .byte_tuple:
        T = Array<Any>.self
    //case .object:
    //    T = PythonObject.self
    case .object:
        T = PythonPointer.self
    case .bool:
        T = Bool.self
    case .void:
        T = Void.self
    case .None:
        T = Void.self
    case .CythonClass:
        T = CythonClass.self
    case .callable:
        T = PythonPointer.self
        otherT = "callable"
    case .url:
        T = URL.self
        otherT = "URL"
    case .error:
        T = Error.self
        otherT = "Error"
    case .optional: break
    case .other:
        otherT = arg.other_type!
    }
    
    if option == .callback {
        if arg.type == .data { return "inout \(String(describing: T))" }
        if arg.has_option(.memoryview) { return "inout [\(String(describing: T))]" }
    }
    if arg.type == .other {
        if sequence { return "[\(arg.other_type!)]" }
        return arg.other_type!
    }
    if sequence { return "[\(String(describing: T))]" }
    if list { return "[\(String(describing: T))]" }
    if memoryview { return "[\(String(describing: T))]" }
    return String(describing: T)
}


let TYPEDEF_BASETYPES: [String:String] = [:]


func get_typedef_types() -> [String: String]  {
    var types = TYPEDEF_BASETYPES
    
    for type in PythonType.allCases {
        switch type {
        case .list, .void:
            continue
        default:
            //types.append((type.rawValue,convertPythonListType(type: type.rawValue)))
            types[type.rawValue] = convertPythonListType_(type: type, options: [.c_type])
        }
        
    }
    
    
    return types
}



func PurePythonTypeConverter(type: PythonType) -> String{
    
    switch type {
    case .int, .int16, .int8 ,.short, .int32, .long, .longlong, .uint, .uint8, .uint16, .ushort, .uint32, .ulong, .ulonglong:
        return "int"
    case .float, .float32, .double:
        return "float"
        
    case .bytes, .char, .data, .uchar:
        return "bytes"
        
    case .str:
        return "str"
    
    case .json, .jsondata, .object:
        return "object"
    
    case .void:
        return "None"
    case .optional:
        return "?"
    
    case .byte_tuple:
        return ""
    case .callable:
        return "object"
        
    case .CythonClass:
        return type.rawValue

    case .bool, .tuple, .list, .None, .other, .sequence, .memoryview, .array, .Array:
        return type.rawValue
    
    case .url, .error:
        return "str"
    }
}







func convertPythonListType_(type: PythonType, options: [PythonTypeConvertOptions]) -> String {
    if options.contains(.objc) {
//        return "PythonList_\(SWIFT_TYPES[type]!) _Nonnull"
        return "PythonList_\(SWIFT_TYPES[type.rawValue]!)"
    }
    
    return "PythonList_\(SWIFT_TYPES[type.rawValue]!)"
}




//if list {return "\(name)_array, \(name)_size"}
//if list {return "\(name)_array"}






public extension String.StringInterpolation {
    mutating func appendInterpolation(if condition: @autoclosure () -> Bool, _ literal: StringLiteralType) {
        guard condition() else { return }
        appendLiteral(literal)
    }
    
    mutating func appendInterpolation(if condition: @autoclosure () -> Bool) {
        guard condition() else { return }
        appendLiteral("")
    }
    
    mutating func appendInterpolation(if condition: @autoclosure () -> Bool, _ literal: StringLiteralType,_ else_literal: StringLiteralType) {
        if condition() { appendLiteral(literal) } else { appendLiteral(else_literal) }
    }
}
