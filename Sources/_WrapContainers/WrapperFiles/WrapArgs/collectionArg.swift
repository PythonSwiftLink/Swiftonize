//
//  objectArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public class collectionArg: _WrapArg, WrapArgProtocol {
    
    public var element: WrapArgProtocol
    
    public var name: String { _name }
        
    public var type: PythonType { _type }
    
    public var other_type: String? { _other_type }
    
    public var idx: Int { _idx }
    
    public var options: [WrapArgOptions] { _options }
    
    public func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }
    public var decref_needed: Bool { false }

//    //public var swift_protocol_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
//    public var swift_protocol_arg: String {
//        //print("swift_protocol_arg - name: \(_name) type: \(type) other type: \(_other_type)  options: \(options)" )
//        return "\(optional_name ?? _name): \(argType)"
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
    public init(name: String, type: PythonType, other_type: String?, idx: Int, options: [WrapArgOptions],element: WrapArgProtocol) {
        self.element = element
        super.init(_name: name, _type: type, _other_type: other_type, _idx: idx, _options: options)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    
}

extension collectionArg: PySendExtactable {
    
    public var extract_needed: Bool { (element as? PySendExtactable)?.extract_needed ?? false }
    
    func function_input(many: Bool) -> String {
        let _name = many ? "_args_[\(idx)]" : name
        if element.type == .other {
            return "_\(name)"
        }
        return """
        try pyCast(from: \(_name) )
        """.newLineTabbed.newLineTabbed
    }
    
    func extractLine(many: Bool, with t: (String?)->String?, for class_pointer: String) -> String? {
        let _t = t(argType) ?? "#WrongSequenceType"
        if many {
            //for option in options {
            
        
            
                switch type {
                case .list, .tuple, .sequence:
                    let optional = options.contains(.optional)
                    if optional {
                        if let other_type = other_type {
                            return """
                            let _\(name)_ = _args_[\(idx)]!
                            let _\(name) = _\(name)_.isNone ? nil : try _\(name)_.map {
                                guard let this = $0, PythonObject_TypeCheck(this, \(other_type)PyType.pytype) else { throw PythonError.attribute }
                                return this.\(class_pointer)
                            }
                            """.newLineTabbed.newLineTabbed
                        }
                        return nil
//                        return """
//                            let _\(name) = try pyCast(from: _args_[\(idx)] )
//                            """.newLineTabbed.newLineTabbed
                    }
                    if let other_type = other_type {
                        return """
                        let _\(name) = try _args_[\(idx)]!.map {
                            guard let this = $0, PythonObject_TypeCheck(this, \(other_type)PyType.pytype) else { throw PythonError.attribute }
                            return this.\(class_pointer)
                        }
                        """.newLineTabbed.newLineTabbed
                    }
                    return nil
                    return """
                        let _\(name) = try \(argType)(object: _args_[\(idx)]! )
                        """.newLineTabbed.newLineTabbed
                    
                default: break
                }
            //}
            return """
                guard let \(name): \(_t) = _args_[\(idx)], PythonObject_TypeCheck(\(name), \(other_type!)PyType.pytype) else { throw PythonError.attribute }
                let _\(name) = \(name).\(class_pointer)
                """.replacingOccurrences(of: newLine, with: newLineTabTab)
        } else {
            //for option in options {
            let optional = options.contains(.optional)
            
                switch type {
                case .list, .tuple, .sequence:
                    let optional = options.contains(.optional)
                    if optional {
                        let optional_addon = optional ? "\(name).isNone ? nil" : ""
                        return """
                        let _\(name): \(_t) = \(optional_addon) : try \(name).map {
                            guard let this = $0, PythonObject_TypeCheck(this, \(other_type ?? "other_Type_missing")PyType.pytype) else { throw PythonError.attribute }
                            return this.\(class_pointer)
                        
                        }
                        """.newLineTabbed.newLineTabbed
                    }
                    return """
                    let _\(name): \(argType) = try pyCast(from: \(name) )
                    """.newLineTabbed.newLineTabbed
                default: break
                }
            //}
            if let other_type = other_type {
                return """
                guard PythonObject_TypeCheck(\(name), \(other_type)PyType.pytype) else { throw PythonError.attribute }
                let _\(name) = \(name).\(class_pointer)
                """.replacingOccurrences(of: newLine, with: newLineTabTab)
            }
            return """
            let _\(name) = try \(argType)(object: _args_[\(idx)]! )
            """.newLineTabbed.newLineTabbed
        }
        //return nil
    }
    
    public var function_call_name: String? {
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


extension collectionArg: PyCallbackExtactable {
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
        "[\(element.type.__swiftType__ ?? (element.other_type ?? ""))]"
    }
}
extension collectionArg: CustomStringConvertible {
    public var description: String {
        argType
    }
    
}


