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
    
    var other_type: String { _other_type }
    
    var idx: Int { _idx }
    
    var options: [WrapArgOptions] { _options }

    var python_function_arg: String { "\(_name): object" }
    
    var python_call_arg: String { "<PyObject*>\(_name)" }
    
    var cython_header_arg: String { "PyObject* \(_name)" }
    
    var c_header_arg: String { "PyObject* \(_name)" }
    
    var swift_protocol_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
    
    var swift_send_func_arg: String { "_ \(_name): \(handleType(T: "PythonPointer"))" }
    
    var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
    
    var swift_callback_func_arg: String { "\(_name): \(handleType(T: "PythonPointer"))" }
    
    var swift_callback_call_arg: String { "\(_name)" }
    
    var conversion_needed: Bool { false }
    
    var decref_needed: Bool { false }
    
    func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
    
    func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
        
    var swift_callback_return_type: String { handleType(T: "PythonPointer") }
    
    var swift_send_return_type: String { handleType(T: "PythonPointer") }

    func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
    
}
