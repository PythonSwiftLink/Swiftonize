//
//  objectArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation

class objectArg: _WrapArg, WrapArgProtocol {

    var name: String { _name }
        
    var type: PythonType { _type }
    
    var other_type: String? { _other_type }
    
    var idx: Int { _idx }
    
    var options: [WrapArgOptions] { _options }
    
    func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }
    
    //var swift_protocol_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
    var swift_protocol_arg: String {
        //print("swift_protocol_arg - name: \(_name) type: \(type) other type: \(_other_type)  options: \(options)" )
        return "\(optional_name ?? _name): \(handleType(T: other_type != nil ? other_type! : "PythonPointer"))"
        
    }
    
    var swift_send_func_arg: String { "_ \(_name): \(handleType(T: "PythonPointer"))" }
    
    var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
    
    //var swift_callback_func_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
    var swift_callback_func_arg: String { "\(if: !options.contains(.alias),optional_name ?? _name,_name): \(handleType(T: other_type ?? "PythonPointer"))" }
    
    var swift_callback_call_arg: String { "\(_name)" }
    
    var conversion_needed: Bool { false }
    
    var decref_needed: Bool { false }
    
    func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
    
    func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
        
    var swift_callback_return_type: String { handleType(T: "PythonPointer") }
    
    var swift_send_return_type: String { handleType(T: "PythonPointer") }

    func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
    
    
    static var _new_: objectArg { .init(_name: "", _type: .object, _other_type: nil, _idx: 0, _options: [])}
}

extension objectArg: PySendExtactable {
    
    var extract_needed: Bool { true }
    
    func function_input(many: Bool) -> String {
        let _name = many ? "_args_[\(idx)]" : name
        return name
    }
    
    func extractLine(many: Bool, with t: (String?)->String?, for class_pointer: String) -> String? {
        many ? "let \(name) = _args_[\(idx)]!" : nil//"guard let \(name) = \(name) else { return PythonNone }"
    }
    
    var function_call_name: String? {
        "\(name): _\(name)"
    }
}

extension objectArg: PyCallbackExtactable {
    func cb_extractLine(many: Bool, for class_pointer: String) -> String? {
        nil
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
        "\(name)"
    }
    
    var callback_name: String? {
        nil
    }
    
    var argType: String {
        type.__swiftType__ ?? "None"
    }
    
    
}


extension objectArg: CustomStringConvertible {
    var description: String {
        argType
    }
    
}
