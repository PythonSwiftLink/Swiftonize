//
//  strArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public class strArg: _WrapArg, WrapArgProtocol {
    
    public var name: String { _name }
        
    public var type: PythonType { _type }
    
    public var other_type: String? { _other_type }
    
    public var idx: Int { _idx }
    
    public var options: [WrapArgOptions] { _options }
    
    public func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }

    public var python_function_arg: String {
        if _sequence {
            return "\(_name): list[str]"
        }
        return "\(_name): str"
    }
    public var decref_needed: Bool { true }

//    public var python_call_arg: String { "<PyObject*>\(_name)" }
//    
//    public var cython_header_arg: String { "PyObject* \(_name)" }
//    
//    public var c_header_arg: String { "PyObject* \(_name)" }
//    
//    public var swift_protocol_arg: String { "\(_name): \(handleType(T: "String"))" }
//    
//    public var swift_send_func_arg: String { "_ \(_name): PythonPointer" }
//    
//    public var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
//    
//    public var swift_callback_func_arg: String { "\(_name): \(handleType(T: "String"))" }
//    
//    public var swift_callback_call_arg: String { handleCallbackCallType(T: _name) }
//    
//    public var conversion_needed: Bool { true }
//        
//
    public func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
//    
//    public func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
//    
//    public var swift_callback_return_type: String { handleType(T: "String") }
//    
//    public var swift_send_return_type: String { handleType(T: SWIFT_TYPES[_type.rawValue]!) }
//    
//    public func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
//    
//    public func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
//    
    override public init(_name: String, _type: PythonType, _other_type: String?, _idx: Int, _options: [WrapArgOptions]) {
        super.init(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: [])
    }
    
    required public init?<S>(_ node: S) where S : SyntaxProtocol {
        let n = node.description
        super.init(_name: n, _type: .str, _other_type: nil, _idx: 0, _options: [])
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    
}

extension strArg: PySendExtactable {
    
    public var extract_needed: Bool { false }
    
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
    
    public var function_call_name: String? {
        "\(name): _\(name)"
    }

}

extension strArg: PyCallbackExtactable {
    public func cb_extractLine(many: Bool, for class_pointer: String) -> String? {
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

extension strArg: CustomStringConvertible {
    public var description: String { argType }
}

//extension strArg: IdentifiedDeclSyntax {
//	public var name: SwiftSyntax.TokenSyntax {
//		get {
//			.identifier(name)
//		}
//		set(newValue) {
//			<#code#>
//		}
//	}
//	
//
//    public var identifier: SwiftSyntax.TokenSyntax {
//        .identifier(argType)
//    }
//    
//    public func withIdentifier(_ newChild: SwiftSyntax.TokenSyntax?) -> Self {
//        self
//    }
//    
//    public var _syntaxNode: SwiftSyntax.Syntax {
//        .init(identifier)
//    }
//    
//    static public var structure: SwiftSyntax.SyntaxNodeStructure {
//        .choices([])
//    }
//    
//    public func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
//        nil
//    }
//}
//


