//
//  File.swift
//  
//
//  Created by MusicMaker on 08/04/2023.
//

import Foundation
import PySwiftCore
////import PythonLib
import SwiftSyntax
import SwiftParser
import SwiftSyntaxBuilder 
import WrapContainers

class PythonCall {
	required init?<S>(_ node: S) where S : SwiftSyntax.SyntaxProtocol {
		fatalError()
	}
	
	var _syntaxNode: SwiftSyntax.Syntax {
		functionDecl._syntaxNode
	}
	
	static var structure: SwiftSyntax.SyntaxNodeStructure { fatalError() }
	
	func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
		name
	}
	
    
    weak var _function: WrapFunction?
    var function: WrapFunction? { _function }
    
    private weak var wrap_cls : WrapClass?
    
    private var callable_name: String?
    
    var callable_args: [WrapArgProtocol]?
    var callable_rtn: WrapArgProtocol?
    var args: [WrapArgProtocol] {
        if let _function = _function {
            return _function._args_
        }
        return callable_args ?? []
    }
    
    var _return_: WrapArgProtocol {
        if let _function = _function { return _function._return_ }
        if let callable_rtn = callable_rtn { return callable_rtn }
        fatalError()
    }
    
    var wrap_class: WrapClass {
        if let wrap_cls = _function?.wrap_class { return wrap_cls }
        if let wrap_cls = wrap_cls { return wrap_cls }
        fatalError()
    }
	
	var call_target: String {
		if let call_target = function?.call_target { return call_target }
		return function?.name ?? "ErrorName"
	}
    
    var name: String {
        if let function = _function {
			//
			
            return function.name
        }
        if let callable_name = callable_name {
            return callable_name
        }
        return "py_function"
    }
    
    
    init(function: WrapFunction) {
        _function = function
    }
    init(callable name: String, args: [WrapArgProtocol], rtn: WrapArgProtocol, cls: WrapClass? = nil) {
        callable_name = name
        callable_args = args
        callable_rtn = rtn
        wrap_cls = cls
    }
    
    var converted_args: [WrapArgProtocol] { args.filter {!($0 is objectArg)} }
    
    private var pre_converted_args: String {
        converted_args.map({ a in
            guard let arg = a as? PyCallbackExtactable else { fatalError("\(a.name): \( a.type.rawValue)")}
            return "let _\(a.name): PyPointer? = " + (arg.cb_extractLine(many: converted_args.count > 1, for: " wrap_class.getSwiftPointer") ?? "")
        }).joined(separator: newLine)
    }
    
    var convert_result: String {
        switch _return_.type {
        case .void, .None:
            return ""
        default: return ""
        }
    }
    
    var filtered_cb_arg_names: [String] {
        args.filter{ a -> Bool in
            if let function = _function {
                if function.call_class_is_arg { if a.name == function.call_class { return false } }
                if function.call_target_is_arg { if a.name == function.call_target { return false } }
            }
            return true
        }.map{a -> String in
            //if let optional_name = a.optional_name { return optional_name }
            if a.other_type == "Error" { return "_\(a.name)"}
            if a.type == .object { return a.name }
            return "_\(a.name)"
        }
    }
    
//    private var callback_func_args: String {
//        args.map({ a in
//            if let extract = a as? PyCallbackExtactable {
//                return extract.function_arg
//            }
//            if a.options.contains(.alias) {
//                return "\(a.optional_name ?? "") \(a.swift_callback_func_arg)"
//            }
//            return a.swift_callback_func_arg
//        }).joined(separator: ", ")
//    }
    
    var decref_converted_args: String {
        """
        \(args
        .filter({$0.decref_needed})
        .map({"Py_DecRef( _\($0.name) )"})
        .joined(separator: newLine))
        """
    }
    
    private var return_string: String { "let \(name)_result: PyPointer? = " }
    
    private var py_call: String {
        let _args = filtered_cb_arg_names.joined(separator: ", ")
        let arg_count = filtered_cb_arg_names.count
		let name = function?.name ?? name
        switch arg_count {
        case 0: return  "\(return_string)\(_return_.convert_return(arg: "PyObject_CallNoArgs(_\(name))"))"
        case 1: return  """
                        \(pre_converted_args)
                        \(return_string)PyObject_CallOneArg(_\(name), \(_args))
                        //\(return_string)try? _\(name)( \(_args))
                        \(decref_converted_args)
                        """
        default: return """
                        \(pre_converted_args)
                        
                        //let vector_callargs: [PythonPointer?] = [\(_args)]
                        \(return_string)[\(_args)].withUnsafeBufferPointer { PyObject_Vectorcall(_\(name), $0.baseAddress, \(arg_count), nil) }
                        if \(name)_result == nil { PyErr_Print() }
                        \(decref_converted_args)
                        
                        """
        }
    }
    
    private var py_call_lines: [String] {
        py_call.split(whereSeparator: \.isNewline).map(\.description)
    }
    
    var return_result: String {
        switch _return_.type {
        case .void, .None:
            return ""
        default: return """
            """
        }
    }
    
    var returnClause: ReturnClauseSyntax? {
        switch _return_.type {
        case .None, .void:
            return nil
        default:
            return ReturnClauseSyntax(arrow: .arrowToken(), returnType: (_return_ as! WrapArgSyntax).typeSyntax)
        }
    }
    
    private func withCodeLines(_ lines: [String]) -> ClosureExprSyntax {
		var header = ClosureExprSyntax(signature: .init(input: .simpleInput(args.map(\.name).closureInputList), output: returnClause, inTok: .keyword(.in))) {
            lines.codeBlockList//.withoutTrivia()
        }
//        header.statements = lines.codeBlockList.map({ line in
//            var l = line
//            l.leadingTrivia = .tab
//            return l
//        })
        return header
    }
    

    
    var closureDecl: ClosureExprSyntax {
        var func_lines: [String] = []
        
        func_lines.append("var gil: PyGILState_STATE?")
        func_lines.append("if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }")
        func_lines.append(contentsOf: py_call_lines)
        func_lines.append(convert_result)
        func_lines.append("Py_DecRef(\(name)_result)")
        func_lines.append("if let gil = gil { PyGILState_Release(gil) }")
        func_lines.append(return_result)
        return withCodeLines(func_lines)
			.with(\.rightBrace, .rightBraceToken(leadingTrivia: .newline))
			//.withRightBrace(.rightBrace.with(\.leadingTrivia, .newline))
    }
    
    var signature: FunctionSignatureSyntax {
        
        func functionParameter(_ a: WrapArgProtocol) -> FunctionParameterSyntax {
            var secondName: TokenSyntax? {
                if let optional_name = a.optional_name {
                    //return .init(.identifier(optional_name))?.withTrailingTrivia(.space)
					return .init(stringLiteral: "_")
                }
                return nil
            }
            if !a.no_label {
				return .init(firstName: .identifier(a.name),secondName: secondName, type: (a as! WrapArgSyntax).typeSyntax)
//                return .init(
//                    firstName: secondName,
//                    secondName: .identifier(a.name),
//                    colon: .colon,
//                    type: (a as! WrapArgSyntax).typeSyntax
//                )
            }
            return .init(
				firstName: .identifier(a.name),
                type: (a as! WrapArgSyntax).typeSyntax
            )
        }
        var parameterList: FunctionParameterListSyntax {
            return .init {
                for par in args {
                    par.functionParameter
                }
            }
        }
        
        var parameterClause: ParameterClauseSyntax {
            .init(parameterList: parameterList)
        }
        
        
        return .init(input: args.parameterClause, output: returnClause)
    }
    
    var function_header: FunctionDeclSyntax {
        .init(identifier: .identifier(call_target), signature: signature)
    }
    
    func withCodeLines(_ lines: [String]) -> FunctionDeclSyntax {
        var header = function_header
        header.body = lines.codeBlock
        return header
    }
    
    var functionDecl: FunctionDeclSyntax {
        var func_lines: [String] = []
        
        func_lines.append("var gil: PyGILState_STATE?")
        func_lines.append("if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }")
        func_lines.append(contentsOf: py_call_lines)
        func_lines.append(convert_result)
        func_lines.append("Py_DecRef(\(name)_result)")
        func_lines.append("if let gil = gil { PyGILState_Release(gil) }")
        func_lines.append(return_result)
		var code = withCodeLines(func_lines) as FunctionDeclSyntax
		code.modifiers.append(.init(name: .keyword(.public)))
		return code
			
			//.addModifier(.init(name: .public))
    }
    
    var function_string: String {

        var func_lines: [String] = []
        
        func_lines.append("var gil: PyGILState_STATE?")
        func_lines.append("if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }")
        func_lines.append(contentsOf: py_call_lines)
        func_lines.append(convert_result)
        func_lines.append("Py_DecRef(\(name)_result)")
        func_lines.append("if let gil = gil { PyGILState_Release(gil) }")
        func_lines.append(return_result)
        return function?.withCodeLines(func_lines) ?? ""
    }
    
    
    
    
}
extension WrapFunction {
    var pythonCall: PythonCall { .init(function: self) }
}



fileprivate extension WrapFunction {
    
//    var filtered_cb_arg_names: [String] {
//        _args_.filter{ a -> Bool in
//            if call_class_is_arg { if a.name == call_class { return false } }
//            if call_target_is_arg { if a.name == call_target { return false } }
//            return true
//        }.map{a -> String in
//            if a.other_type == "Error" { return "_\(a.name)"}
//            if a.type == .object { return a.name }
//            return "_\(a.name)"
//        }
//    }
//    var callback_func_args: String {
//        _args_.map({ a in
//            if let extract = a as? PyCallbackExtactable {
//                return extract.function_arg
//            }
//            if a.options.contains(.alias) {
//                return "\(a.optional_name ?? "") \(a.swift_callback_func_arg)"
//            }
//            return a.swift_callback_func_arg
//        }).joined(separator: ", ")
//    }
    
    //var converted_args: [WrapArgProtocol] { _args_.filter { $0.type != .object || $0.other_type == nil } }
    var converted_args: [WrapArgProtocol] { _args_.filter {!($0 is objectArg)} }
    
    var _pre_converted_args: String {
        converted_args.map({ a in
            let name = a.name
            let optional = a.type == .optional
            var src: String {
                
                if a.other_type == "Error" { return "\(name)\(a.swiftType).localizedDescription" }
                return name
            }
            
            if a is optionalArg {
                
                return "let _\(name) = if \(name) == nil ? .None : \(src).pyPointer"
            }
            return "let _\(name) = \(src).pyPointer"
            
            
            
        }).joined(separator: newLine)
    }
//    
//    var pre_converted_args: String {
//        converted_args.map({ a in
//            guard let arg = a as? PyCallbackExtactable else { fatalError("\(a.name): \( a.type.rawValue)")}
//            return "let _\(a.name): PyPointer? = " + (arg.cb_extractLine(many: converted_args.count > 1, for: wrap_class.getSwiftPointer) ?? "")
//        }).joined(separator: newLine)
//    }
//        
    var decref_converted_args: String {
        """
        \(_args_
        .filter({$0.decref_needed})
        .map({"Py_DecRef( _\($0.name) )"})
        .joined(separator: newLineTab))
        """
    }
    
    var use_rtn: Bool { _return_.type != .void || _return_.type != .None}
    
//    var _callback_function: String {
//        
//        let use_rtn = use_rtn
//        let return_string = "let \(name)_result: \(_return_.type == .void ? "PyPointer?" : _return_.swift_callback_return_type) = "
//        
//        let filtered_cb_arg_names = filtered_cb_arg_names
//        
//        var arg_count = filtered_cb_arg_names.count
//        
//        let _args = filtered_cb_arg_names.joined(separator: ", ")
//        
//        
//        var pycall = ""
//        switch arg_count {
//        case 0: pycall = "\(return_string)\(_return_.convert_return(arg: "PyObject_CallNoArgs(_\(name))"))"
//        case 1: pycall =    """
//                            \(pre_converted_args)
//                            
//                            //\(return_string)PyObject_CallOneArg(_\(name), \(_args))
//                            \(return_string)try? _\(name)( \(_args))
//                            \(decref_converted_args)
//                            """
//        default: pycall =   """
//                            \(pre_converted_args)
//                            
//                            let vector_callargs: [PythonPointer?] = [\(_args)]
//                            \(return_string)vector_callargs.withUnsafeBufferPointer { PyObject_Vectorcall(_\(name), $0.baseAddress, \(arg_count), nil)
//                            //let call_args: [PyConvertible] = [\(_args)]
//                            //let rtn_ptr: PyPointer? = try? _\(name)._callAsFunction_(call_args)
//                            }
//                            \(decref_converted_args)
//                            """//.replacingOccurrences(of: newLine, with: newLineTab)
//        }
//        
//        return """
//            //@inlinable
//            //\(name)
//            func \(call_target ?? name)(\(callback_func_args)) \(if: use_rtn, " -> \(_return_.swiftType)"){
//                var gil: PyGILState_STATE?
//                if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }
//                //print("\(name)", _Py_REFCNT(_\(name)))
//                \(pycall)
//                //defer { Py_DecRef( \(name)_result ) }
//                if let gil = gil { PyGILState_Release(gil) }
//                \(if: use_rtn, "return try ")
//            }
//            """//.newLineTabbed
//    }
//    
//    var callback_function: String {
//        
//        let use_rtn = use_rtn
//        //let return_string = "let \(name)_result: \(_return_.type == .void ? "PyPointer?" : _return_.swift_callback_return_type) = "
//        
//        let return_string = "let \(name)_result: PyPointer? = "
//        
//        let filtered_cb_arg_names = filtered_cb_arg_names
//        
//        var arg_count = filtered_cb_arg_names.count
//        
//        let _args = filtered_cb_arg_names.joined(separator: ", ")
//        
//        var convert_result: String {
//            switch _return_.type {
//            case .void, .None:
//                return ""
//            default: return """
//            """
//            }
//        }
//        
//        var return_result: String {
//            switch _return_.type {
//            case .void, .None:
//                return ""
//            default: return """
//            """
//            }
//        }
//        
//        var pycall = ""
//        switch arg_count {
//        case 0: pycall = "\(return_string)\(_return_.convert_return(arg: "PyObject_CallNoArgs(_\(name))"))"
//        case 1: pycall =    """
//                            \(pre_converted_args)
//                            \(return_string)PyObject_CallOneArg(_\(name), \(_args))
//                            \(decref_converted_args)
//                            """
//        default: pycall =   """
//                            \(pre_converted_args)
//                            \(return_string)[\(_args)].withUnsafeBufferPointer({ PyObject_Vectorcall(_\(name), $0.baseAddress, \(arg_count), nil) })
//                            if \(name)_result == nil { PyErr_Print() }
//                            \(decref_converted_args)
//                            
//                            """.replacingOccurrences(of: newLine, with: newLineTab)
//        }
//        
//        return """
//            //@inlinable
//            //\(name)
//            func \(call_target ?? name)(\(callback_func_args)) \(if: use_rtn, " -> \(_return_.swiftType)"){
//                
//                var gil: PyGILState_STATE?
//                if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }
//                //print("\(call_target ?? name)(\(callback_func_args)) - main:",RunLoop.current == RunLoop.main)
//                \(pycall)
//                \(convert_result)
//                defer { Py_DecRef( \(name)_result ) }
//                if let gil = gil { PyGILState_Release(gil) }
//                \(return_result)
//            }
//            """.newLineTabbed
//    }
//    
}

extension WrapClass {
    
//    var pyCallbackClass: String {
//        
//        let is_nsobject = bases.contains(.NSObject)
//        
//        let class_title = new_class ? title : "\(title)PyCallback"
//        
//        let cb_funcs = callback_functions
//        let cls_attributes = cb_funcs.map({f in "private let _\(f.name): PyPointer"}).joined(separator: newLineTab)
//        let init_attributes = cb_funcs.map({f in "_\(f.name) = PyObject_GetAttr(callback, \"\(f.name)\").xDECREF"}).joined(separator: newLineTabTab)
//        
//        let dict_attributes = cb_funcs.map { f in
//            """
//            _\(f.name) = PyDict_GetItem(callback, "\(f.name)")
//            """
//        }.joined(separator: newLineTabTab)
//        
//        let call_funcs = cb_funcs.map(\.pythonCall.function_string).joined(separator: newLineTab)
//        
//        let extensions: String = callback_protocols.count > 0 ? "\nextension \(class_title): \(callback_protocols.joined(separator: ", ")) {}" : ""
//        
//        
//        
//        return """
//        class \(class_title)\(if: is_nsobject, ": NSObject") {
//        
//            public var _pycall: PythonObject
//            \(cls_attributes)
//        
//            init(callback: PyPointer) {
//                if PythonDict_Check(callback) {
//                    _pycall = .init(ptr: callback, keep_alive: true)
//                    \(dict_attributes.addTabs())
//                } else {
//                    _pycall = .init(ptr: callback)
//                    \(init_attributes.addTabs())
//                }
//                \(if: is_nsobject, "super.init()")
//            }
//            
//            \(call_funcs)
//        }
//        \(extensions)
//        """
//    }
//    
}
