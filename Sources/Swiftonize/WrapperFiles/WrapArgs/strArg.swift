//
//  strArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation

class strArg: _WrapArg, WrapArgProtocol {
    
    var name: String { _name }
        
    var type: PythonType { _type }
    
    var other_type: String? { _other_type }
    
    var idx: Int { _idx }
    
    var options: [WrapArgOptions] { _options }
    
    func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }

    var python_function_arg: String {
        if _sequence {
            return "\(_name): list[str]"
        }
        return "\(_name): str"
    }
    
    var python_call_arg: String { "<PyObject*>\(_name)" }
    
    var cython_header_arg: String { "PyObject* \(_name)" }
    
    var c_header_arg: String { "PyObject* \(_name)" }
    
    var swift_protocol_arg: String { "\(_name): \(handleType(T: "String"))" }
    
    var swift_send_func_arg: String { "_ \(_name): PythonPointer" }
    
    var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
    
    var swift_callback_func_arg: String { "\(_name): \(handleType(T: "String"))" }
    
    var swift_callback_call_arg: String { handleCallbackCallType(T: _name) }
    
    var conversion_needed: Bool { true }
        
    var decref_needed: Bool { true }
    
    func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
    
    func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    var swift_callback_return_type: String { handleType(T: "String") }
    
    var swift_send_return_type: String { handleType(T: SWIFT_TYPES[_type.rawValue]!) }
    
    func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
    
    
}

extension strArg: PySendExtactable {
    
    var extract_needed: Bool { false }
    
    func function_input(many: Bool) -> String {
        let _name = many ? "_args_[\(idx)]" : name
        return """
        try pyCast(from: \(_name) )
        """
    }
    
    func extractLine(many: Bool, with t: (String?)->String?, for class_pointer: String) -> String? {
        _ = t(argType)
        let target = many ? "_args_[\(idx)]!" : "\(name)"
        return "let _\(name): \(argType) = try pyCast(from: \(target) )"
    }
    
    var function_call_name: String? {
        "\(name): _\(name)"
    }

}

extension strArg: PyCallbackExtactable {
    func cb_extractLine(many: Bool, for class_pointer: String) -> String? {
        let optional = options.contains(.optional)
        switch type {
        case .error:
            if optional { return "\(name)?.localizedDescription"}
            return "\(name).localizedDescription.pyPointer"
//        case .url:
//            if optional { return "\(name)?.path"}
//            return "\(name).path.pyPointer"
        default:
            if optional { return "\(name)"}
            return "\(name).pyPointer"
        }
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

extension strArg: CustomStringConvertible {
    var description: String { argType }
}
