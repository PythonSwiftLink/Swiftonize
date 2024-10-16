//
//  dataArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

public class dataArg: _WrapArg, WrapArgProtocol {
    
    public var name: String { _name }
        
    public var type: PythonType { _type }
    
    public var other_type: String? { _other_type }
    
    public var idx: Int { _idx }
    
    public var options: [WrapArgOptions] { _options }
    
    public func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }

    public var decref_needed: Bool { true }
//    public var python_function_arg: String { "\(_name): object" }
//    
//    public var python_call_arg: String { "<PyObject*>\(_name)" }
//    
//    public var cython_header_arg: String { "PyObject* \(_name)" }
//    
//    public var c_header_arg: String { "PyObject* \(_name)" }
//    
//    public var swift_protocol_arg: String { "\(_name): \(handleType(T: "Data"))" }
//    
//    public var swift_send_func_arg: String { "_ \(_name): PythonPointer" }
//    
//    public var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
//    
//    public var swift_callback_func_arg: String { "\(_name): \(handleType(T: SWIFT_TYPES[_type.rawValue]!))" }
//    
//    public var swift_callback_call_arg: String { "" }
//    
//    public var conversion_needed: Bool { true } // do require conversion but special handler for that is implemented
//        
//
    public func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
//    
//    public func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
//    
//    public var swift_callback_return_type: String { handleType(T: "Data") }
//    
//    public var swift_send_return_type: String { handleType(T: SWIFT_TYPES[_type.rawValue]!) }
//    
//    public func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
//    
//    public func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
//    
    
}
