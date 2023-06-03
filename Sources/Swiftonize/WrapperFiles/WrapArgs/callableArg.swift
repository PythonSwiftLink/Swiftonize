
import Foundation
import PyAstParser
import SwiftSyntax
import SwiftSyntaxBuilder

class callableArg: _WrapArg, WrapArgProtocol {
    
    var callArgs: [WrapArgProtocol] = []
    var _return: WrapArgProtocol?
    
    init(_name: String, _idx: Int, _options: [WrapArgOptions], args: [WrapArgProtocol], rtn: WrapArgProtocol? = nil) {
        callArgs = args
        _return = rtn
        super.init(_name: _name, _type: .callable, _other_type: "", _idx: _idx, _options: _options)
    }
    
    init(_name: String, _idx: Int, ast: PyAstObject) {
        //callArgs = []
 
        switch ast.type {
        case .Tuple:
            let tuple = ast as! PyAst_Tuple
            let telts = tuple.elts
            guard telts.count > 0 else { break }
            switch telts[0] {
            case let _tuple as PyAst_Tuple:
                callArgs = _tuple.elts.enumerated().map { i, a in _WrapArg._fromAst(index: i, a, name: "__arg\(i)__") }
            case let _list as PyAst_List:
                callArgs = _list.elts.enumerated().map { i, a in _WrapArg._fromAst(index: i, a, name: "__arg\(i)__") }
            default: fatalError("\(telts[0])")
            }
            
            if telts.count > 1 {
               _return = _WrapArg._fromAst(index: 0, telts[1], name: "returns")
            }
        case .List:
            let list = ast as! PyAst_List
            let telts = list.elts
            guard telts.count > 0 else { break }
            switch telts[0] {
            case let _tuple as PyAst_Tuple:
                callArgs = _tuple.elts.enumerated().map { i, a in _WrapArg._fromAst(index: i, a, name: "__arg\(i)__") }
            case let _list as PyAst_List:
                callArgs = _list.elts.enumerated().map { i, a in _WrapArg._fromAst(index: i, a, name: "__arg\(i)__") }
//            case let sub as PyAst_Subscript:
//                callArgs = s
            default:
                
                let wrong_ast = telts[0]
                fatalError("callable: wrong layout!!")
            }
            
            if telts.count > 1 {
                _return = _WrapArg._fromAst(index: 0, telts[1], name: "returns")
            }
        default: fatalError()
        }
        
        super.init(_name: _name, _type: .callable, _other_type: "", _idx: _idx, _options: [])
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    var name: String { _name }
    
    var type: PythonType { _type }
    
    var other_type: String? { _other_type }
    
    var idx: Int { _idx }
    
    var options: [WrapArgOptions] { _options }
    
    func add_option(_ option: WrapArgOptions) {
        _options.append(option)
    }
    
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
    
    var typeSyntax: TypeSyntax {
        
        let args: TupleTypeElementListSyntax = .init {
            for arg in callArgs {
                TupleTypeElementSyntax(type: arg.typeSyntax)
            }
        }
        
        var r: TypeSyntaxProtocol
        if let _return = _return {
            r = _return.typeSyntax
        } else {
            r = SimpleTypeIdentifierSyntax(stringLiteral: "Void")
        }
        let t = FunctionTypeSyntax(
            leftParen: .leftParen,
            arguments: args,
            rightParen: .rightParen,
            returnType: r
        )
        
        return .init(t)
    }
    
    var typeExpr: TypeExprSyntax {
        .init(type: typeSyntax)
        
    }
    
    var typeAnnotation: TypeAnnotation { type.annotation }
    
    var exprSyntax: ExprSyntax {
        .init(stringLiteral: PythonCall(
            callable: name,
            args: callArgs,
            rtn: _return!).closureDecl
            .formatted().description)
    }
    
    func callTupleElement(many: Bool) -> TupleExprElement {
        return .init(
            label: label,
            expression: exprSyntax
        )
    }
    
    func extractDecl(many: Bool) -> VariableDecl? {
        if many {
            return .init(stringLiteral: "let _\(name) = _args_[\(idx)]!")
        }
        return .init(stringLiteral: "let _\(name) = \(name)")
    }
}



extension callableArg: PyCallbackExtactable {
    func cb_extractLine(many: Bool, for class_pointer: String) -> String? {
        let extracts = callArgs.compactMap({a in
            let _a = a as? PyCallbackExtactable
            guard let ext = _a?.cb_extractLine(many: many, for: class_pointer) else { return nil }
            return "let _\(a.name): PyPointer? = \(ext)"
        }).joined(separator: newLineTabTab)
        let decrefs = callArgs.filter(\.decref_needed).map({"Py_DecRef(_\($0.name))"}).joined(separator: newLineTabTab)
        let func_args = callArgs.map(\.name).joined(separator: ", ")
        let call_args = callArgs.map({"_\($0.name)"}).joined(separator: ", ")
        let rtn_convert =  _return?.type != .None ? (_return?.__swiftType__ ?? "") : ""
        return """
        let \(name): \(argType) = { \(func_args) in
            DispatchQueue.main.async {
                let gil = PyGILState_Ensure()
                \(extracts)
                let \(name)_result = [\(call_args)].withUnsafeBufferPointer { PyObject_Vectorcall(_\(name) ,$0.baseAddress ,\(callArgs.count) ,nil) }
                Py_DecRef(_\(name))
                \(decrefs)
                \(rtn_convert)
                Py_DecRef(\(name)_result)
                PyGILState_Release(gil)
                \(if: _return?.type != .None, "return \(name)_result")
            }
        }
        """//.newLineTabbed.newLineTabbed
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
        let cargs = callArgs.map { ($0 as? PyCallbackExtactable)?.argType ?? $0.__swiftType__ }.joined(separator: ", ")
        //return "( \(__swiftType__) )"
        return "( (\(cargs))->\(_return?.swiftType ?? "Void") )"
    }

    
    
}
