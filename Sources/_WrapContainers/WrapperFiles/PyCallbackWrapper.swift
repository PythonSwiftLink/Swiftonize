////
////  PyCallbackWrapper.swift
////  KivySwiftLink
////
////  Created by MusicMaker on 09/03/2022.
////
//
//import Foundation
//import zlib
//
func swiftTypeFromPythonType(T: PythonType) -> String? {
    switch T {
    case .object:
        return nil

//    case .str:
//        return "PyUnicode_AsUTF8"
    case .int, .int32, .int16, .int8, .long, .char, .short:
        return "PyLong_AsLong"
    case .uint, .uint32, .uint16, .uint8, .ulong, .uchar, .ushort:
        return "PyLong_AsUnsignedLong"
    case .longlong:
        return "PyLong_AsLongLong"
    case .ulonglong:
        return "PyLong_AsUnsignedLongLong"

    case .float, .float32, .double:
        return "PyFloat_AsDouble"
    

    default: return nil
    }
}
//
//
func swiftTypeAsPythonType(T: PythonType) -> String? {
    switch T {
    case .str:
        return "PyUnicode_FromString"
    case .int, .int32, .int16, .int8, .short, .char, .long:
        return "PyLong_FromLong"
    case .uint, .uint32, .uint16, .uint8, .ulong:
        return "PyLong_FromUnsignedLong"
    case .longlong:
        return "PyLong_FromLongLong"
    case .ulonglong:
        return "PyLong_FromUnsignedLongLong"
    case .float, .double:
        return "PyFloat_FromDouble"
    default: return nil
    }
    
}
//
func castIfNeededFromPythonType(T: PythonType) -> String? {
    switch T {
    case .int32:            return "Int32"
    case .int16, .short:    return "Int16"
    case .int8, .char:      return "Int8"
    
    case .uint32:           return "UInt32"
    case .uint16, .ushort:  return "UInt16"
    case .uint8, .uchar:    return "UInt8"
    
    case .float32:          return "Float"

    default: return nil
    }
}
//
func castIfNeededAsPythonType(T: PythonType) -> String? {
    switch T {
    case .int32, .int16, .int8, .short, .char:
        return "Int"
    case .uint32, .uint16, .uint8, .ushort, .uchar:
        return "UInt"
    case .float32:
        return "Double"
    default:
        return nil
    }
}
//
//
func elementConverterPythonType(element: String,T: PythonType, AsFrom: ElementConvertOptions) -> String {
    var subject = element
    var convertion: String? = nil
    var casting: String? = nil
    switch AsFrom {
    case .FromPythonType:
        convertion = swiftTypeFromPythonType(T: T)
        casting = castIfNeededFromPythonType(T: T)
        if let convertion = convertion {
            subject = "\(convertion)(\(subject))"
            if let casting = casting {
                if T == .str {
                    subject = "String(cString: \(subject))"
                } else {
                    subject = "\(casting)(\(subject))"
                }
            }
        }
        
    case .AsPythonType:
        convertion = swiftTypeAsPythonType(T: T)
        casting = castIfNeededAsPythonType(T: T)
        //print(".As - \(T.rawValue) - casting \(casting) convertion - \(convertion)")
        if let convertion = convertion {
            
            if let casting = casting {
                subject = "\(casting)(\(subject))"
            }
            subject = "\(convertion)(\(subject))"
        }
    }//switch end
    //print("\tsubject: \(subject), convertion: \(convertion), casting: \(casting)")
    return subject
}
//let DOT = "."
//let INDENT_SYM = tab
//
//func clossureWrapper(title: String, args: [String], code: String, tabs: Int, first: Bool) -> String {
//    let indent = String(repeating: INDENT_SYM, count: tabs)
//    var first_indent = indent
//    if first { first_indent = ""}
//    //tabs += 1
//    return """
//    \(first_indent)\(title){ (\(args.joined(separator: ", "))) in
//    \(INDENT_SYM)\(code)
//    \(indent)\(INDENT_SYM)}
//    """
//}
//
//func handleClossures(main_string: String, args_set: [(String, [String])]) -> String {
//    let set_count = args_set.count
//    if set_count == 0 { return main_string }
//    let end_tabs = String(repeating: INDENT_SYM, count: set_count)
//    let main_string = main_string.replacingOccurrences(of: "\n", with: "\n" + end_tabs )
//    var wrap = end_tabs + tab + main_string
//    for (t, args) in args_set.enumerated().reversed() {
//        wrap = clossureWrapper(title: args.0, args: args.1, code: wrap, tabs: t+1, first: t == 0)
//    }
//    return wrap
//}
