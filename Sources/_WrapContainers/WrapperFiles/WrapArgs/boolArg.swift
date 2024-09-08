//
//  boolArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public class boolArg: _WrapArg, WrapArgProtocol {
    
    public var name: String { _name }
        
    public var type: PythonType { .bool }
    
    public var other_type: String? { _other_type }
    
    public var idx: Int { _idx }
    
    public var options: [WrapArgOptions] { _options }
    
    public func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }
    public var decref_needed: Bool { false }

//    public var swift_protocol_arg: String { "\(_name): \(handleType(T: SWIFT_TYPES[_type.rawValue]!))" }
//    
//    public var swift_send_func_arg: String { "_ \(_name): PythonPointer" }
//    
//    public var swift_send_call_arg: String { "\(_name): \(_name).bool" }
//    
//    public var swift_callback_func_arg: String { "\(_name): \(handleType(T: SWIFT_TYPES[_type.rawValue]!))" }
//    
//    public var swift_callback_call_arg: String { "asPyBool(\(_name))" }
//    
//    public var conversion_needed: Bool { true }
//        
//
    public func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
//
//    public func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
//    
//    public var swift_callback_return_type: String { handleType(T: "Bool") }
//    
//    public var swift_send_return_type: String { handleType(T: SWIFT_TYPES[_type.rawValue]!) }
//    
//    public func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
//    
//    public func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
//    
    
}

extension boolArg: PySendExtactable {
    func function_input(many: Bool) -> String {
        let _name = many ? "_args_[\(idx)]" : name
        return """
        try pyCast(from: \(_name) )
        """
    }
    
    func extractLine(many: Bool, with t: (String?)->String?, for class_pointer: String) -> String? {
        //guard let wrapped = wrapped as? PySendExtactable else { return nil }
        let _t = t(argType) ?? argType
        let target = many ? "_args_[\(idx)]" : "\(name)"
        if options.contains(.optional) {
            return "let _\(name): \(_t) = try optionalPyCast(from: \(target) )"
        }
        return "let _\(name): \(argType) = try pyCast(from: \(target) )"
    }
    
    public var function_call_name: String? {
        "\(name): _\(name)"
    }
    
    public var extract_needed: Bool {
        false
    }
    
    
}

extension boolArg: PyCallbackExtactable {
    
    
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
        type.__swiftType__ ?? "String"
    }
}

extension boolArg: CustomStringConvertible {
    public var description: String {
        argType
    }
    
}
