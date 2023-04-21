//
//  boolArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation

class boolArg: _WrapArg, WrapArgProtocol {
    
    var name: String { _name }
        
    var type: PythonType { .bool }
    
    var other_type: String? { _other_type }
    
    var idx: Int { _idx }
    
    var options: [WrapArgOptions] { _options }
    
    func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }
    
    var swift_protocol_arg: String { "\(_name): \(handleType(T: SWIFT_TYPES[_type.rawValue]!))" }
    
    var swift_send_func_arg: String { "_ \(_name): PythonPointer" }
    
    var swift_send_call_arg: String { "\(_name): \(_name).bool" }
    
    var swift_callback_func_arg: String { "\(_name): \(handleType(T: SWIFT_TYPES[_type.rawValue]!))" }
    
    var swift_callback_call_arg: String { "asPyBool(\(_name))" }
    
    var conversion_needed: Bool { true }
        
    var decref_needed: Bool { false }
    
    func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
    
    func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    var swift_callback_return_type: String { handleType(T: "Bool") }
    
    var swift_send_return_type: String { handleType(T: SWIFT_TYPES[_type.rawValue]!) }
    
    func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
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
    
    var function_call_name: String? {
        "\(name): _\(name)"
    }
    
    var extract_needed: Bool {
        false
    }
    
    
}

extension boolArg: PyCallbackExtactable {
    
    
    func cb_extractLine(many: Bool, for class_pointer: String) -> String? {
        "\(name).pyPointer"
    }
    
    var function_arg_name: String {
        if let optional_name = optional_name {
            if options.contains(.alias) {
                return "\(optional_name) \(name)"
            }
            return optional_name
        }
        return name
    }
    
    var call_arg_name: String {
        "_\(name)"
    }
    
    var callback_name: String? {
        nil
    }
    
    var argType: String {
        type.__swiftType__ ?? "String"
    }
}

extension boolArg: CustomStringConvertible {
    var description: String {
        argType
    }
    
}
