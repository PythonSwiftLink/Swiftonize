//
//  objectArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public class optionalArg: _WrapArg, WrapArgProtocol {
    
    public var wrapped: WrapArgProtocol
    
    public var name: String { _name }
        
    public var type: PythonType { _type }
    
    public var other_type: String? { _other_type }
    
    public var idx: Int { _idx }
    
    public var options: [WrapArgOptions] { _options }
    
    public func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }
    
    public var decref_needed: Bool { true }
//    //var swift_protocol_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
//    public var swift_protocol_arg: String {
//        //print("swift_protocol_arg - name: \(_name) type: \(type) other type: \(_other_type)  options: \(options)" )
//        //return "\(optional_name ?? _name): \(handleType(T: other_type != nil ? other_type! : "PythonPointer"))"
//        return "\(optional_name ?? _name): \(argType)"
//    }
//    
//    public var swift_send_func_arg: String { "_ \(_name): \(handleType(T: "PythonPointer"))" }
//    
//    public var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
//    
//    //var swift_callback_func_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
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
    public init(name: String, type: PythonType, other_type: String?, idx: Int, options: [WrapArgOptions],wrapped: WrapArgProtocol) {
        wrapped.add_option(.optional)
        (wrapped as! _WrapArg).setIndex(idx)
        self.wrapped = wrapped
        super.init(_name: name, _type: type, _other_type: other_type, _idx: idx, _options: options)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    
}

extension optionalArg: PySendExtactable {
    
    var extract_needed: Bool { (wrapped as? PySendExtactable)?.extract_needed ?? false }

    func function_input(many: Bool) -> String {
        
        if let _wrapped = wrapped as? PySendExtactable { return _wrapped.function_input(many: many)}
        let _name = many ? "_args_[\(idx)]" : name
        
        return """
        try optionalPyCast(from: \(_name) )
        """
    }
    
    func extractLine(many: Bool, with t: (String?)->String?, for class_pointer: String) -> String? {
        guard let wrapped = wrapped as? PySendExtactable else { return nil }
        let handler: (String?)->String? = { _t in
            guard let _t = _t else { return nil }
            return "\(_t)?"
        }
        
        
        if let line = wrapped.extractLine(many: many, with: handler, for: class_pointer) {
            return line
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

extension optionalArg: PyCallbackExtactable {
    
    public var argType: String {
        "\((wrapped as? PyCallbackExtactable)?.argType ?? wrapped.__swiftType__)?"
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
        ""
    }
    
    public var callback_name: String? {
        nil
    }
    
    public func cb_extractLine(many: Bool, for class_pointer: String) -> String? {
        let name = (self.name == type.rawValue) ? class_pointer : name
        if type == .error { return "optionalPyPointer(\(name)?.localizedDescription)"}
        return "optionalPyPointer(\(name))"

    }
    
}


extension optionalArg: CustomStringConvertible {
    public var description: String { argType }
}
