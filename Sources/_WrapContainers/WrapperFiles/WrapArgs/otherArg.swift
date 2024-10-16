//
//  objectArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public class otherArg: _WrapArg, WrapArgProtocol {

    public var name: String { _name }
        
    public var type: PythonType { _type }
    
    public var other_type: String? { _other_type }
    
    public var idx: Int { _idx }
    
    public var options: [WrapArgOptions] { _options }
    
    public func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }
    public var decref_needed: Bool { true }

//    //public var swift_protocol_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
//    public var swift_protocol_arg: String {
//        //print("swift_protocol_arg - name: \(_name) type: \(type) other type: \(_other_type)  options: \(options)" )
//        return "\(optional_name ?? _name): \(handleType(T: other_type != nil ? other_type! : "PythonPointer"))"
//        
//    }
//    
//    public var swift_send_func_arg: String { "_ \(_name): \(handleType(T: "PythonPointer"))" }
//    
//    public var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
//    
//    //public var swift_callback_func_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
//    public var swift_callback_func_arg: String { "\(if: !options.contains(.alias),optional_name ?? _name,_name): \(handleType(T: other_type ?? "PythonPointer"))" }
//    
//    public var swift_callback_call_arg: String { "\(_name)" }
//    
//    public var conversion_needed: Bool { true }
//    
//
    public func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
//    
//    public func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
//        
//    public var swift_callback_return_type: String { handleType(T: "PythonPointer") }
//    
//    public var swift_send_return_type: String { handleType(T: "PythonPointer") }
//
//    public func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
//    
//    public func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
//    
    
}

extension otherArg: PySendExtactable {
    
    var extract_needed: Bool { true }
    
    func function_input(many: Bool) -> String {
        //let _name = many ? "_args_[\(idx)]" : name
        return """
        _\(name)
        """
    }
    
    func extractLine(many: Bool, with t: (String?)->String?, for class_pointer: String) -> String? {
        if many {
            for option in options {
                switch option {
                case .list, .tuple, .sequence: return """
                    let _\(name) = try _args_[\(idx)]?.sequence.map {
                        guard let this = $0, PythonObject_TypeCheck(this, \(other_type!)PyType.pytype) else { throw PythonError.attribute }
                        return this.\(class_pointer)
                    }
                    """.newLineTabbed.newLineTabbed
                default: continue
                }
            }
            return """
                guard let \(name): PyPointer = _args_[\(idx)], PythonObject_TypeCheck(\(name), \(other_type!)PyType.pytype) else { throw PythonError.attribute }
                let _\(name) = \(name).\(class_pointer)
                """.replacingOccurrences(of: newLine, with: newLineTabTab)
        } else {
            for option in options {
                switch option {
                case .list, .tuple, .sequence:
                    
                    return """
                    let _\(name): \(swiftType) = try \(name).sequence.map {
                        guard let this = $0, PythonObject_TypeCheck(this, \(other_type ?? "other_Type_missing")PyType.pytype) else { throw PythonError.attribute }
                        return this.\(class_pointer)
                    
                    }
                    """.newLineTabbed.newLineTabbed
                default: continue
                }
            }
            return """
                guard PythonObject_TypeCheck(\(name), \(other_type!)PyType.pytype) else { throw PythonError.attribute }
                let _\(name) = \(name).\(class_pointer)
                """.replacingOccurrences(of: newLine, with: newLineTabTab)
        }
        return nil
    }
    
    var function_call_name: String? {
        if let optional_name = optional_name {
            if options.contains(.alias) {
                return "\(optional_name): _\(name)"
            }
            if optional_name.first == "_" {
                return type != .object ? "_\(name)" : "\(name)"
            }
            return "_\(optional_name)"
        }
        return "\(name): _\(name)"
        
    }
    
}


extension otherArg: PyCallbackExtactable {
    public func cb_extractLine(many: Bool, for class_pointer: String) -> String? {
        "\(name).pyPointer"
    }
    
    public var function_arg_name: String {
        if let optional_name = optional_name {
            if options.contains(.alias) {
                return "\(optional_name) \(name)"
            }
            return optional_name
        }
        return name
    }
    
    public var call_arg_name: String {
        "_\(name)"
    }
    
    public var callback_name: String? {
        nil
    }
    
    public var argType: String {
        other_type ?? (type.__swiftType__ ?? "String")
    }
    
    
}

extension otherArg: CustomStringConvertible {
    public var description: String { argType }
}
