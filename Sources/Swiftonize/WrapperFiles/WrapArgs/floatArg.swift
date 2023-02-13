import Foundation

class floatArg: _WrapArg, WrapArgProtocol {
    
    var name: String { _name }
        
    var type: PythonType { _type }
    
    var other_type: String { _other_type }
    
    var idx: Int { _idx }
    
    var options: [WrapArgOptions] { _options }

    var python_function_arg: String { "\(_name)" }
    
    var python_call_arg: String { "<PyObject*>\(_name)" }
    
    var cython_header_arg: String { "PyObject* \(_name)" }
    
    var c_header_arg: String { "PyObject* \(_name)" }
    
    var swift_protocol_arg: String { "\(_name): \(handleType(T: SWIFT_TYPES[_type.rawValue]!))" }
    
    var swift_send_func_arg: String { "_ \(_name): PythonPointer" }
    
    var swift_send_call_arg: String { "\(_name): \(handleSendCallType(T: _name))" }
    
    var swift_callback_func_arg: String { "\(_name): \(handleType(T: SWIFT_TYPES[_type.rawValue]!))" }
    
    var swift_callback_call_arg: String { elementConverterPythonType(element: _name, T: _type, AsFrom: .AsPythonType) }
    
    var conversion_needed: Bool { true }
        
    var decref_needed: Bool { true }
    
    func convert_return(arg: String) -> String { handleSendCallType2(T: arg) }
    
    func convert_return_send(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    var swift_callback_return_type: String { handleType(T: SWIFT_TYPES[_type.rawValue]!) }
    
    var swift_send_return_type: String { handleType(T: SWIFT_TYPES[_type.rawValue]!) }
    
    func swift_property_getter(arg: String) -> String { handleCallbackCallType2(T: arg) }
    
    func swift_property_setter(arg: String) -> String { handleSendCallType2(T: arg) }
    
}
