import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

import WrapContainers
import PyAst
import PySwiftCore
import SwiftParser



struct PyMethods {
	
	var cls: WrapClass?
	var methods: [WrapFunction] = []
	
	init(cls: WrapClass? = nil, methods: [WrapFunction]? = nil) {
		self.cls = cls
		self.methods = cls?.send_functions ?? methods ?? []
	}
	
	var output: VariableDeclSyntax {
		let elements: ArrayElementListSyntax = .init {
			for method in methods {
				WrapFunction.asArrayElement(f: method)
					.with(\.trailingComma, .commaToken(trailingTrivia: .newline))
			}
			ArrayElementSyntax(expression: ExprSyntax(stringLiteral: "PyMethodDef()"))
		}
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))],
			.var,
			name: .init(stringLiteral: "PyMethods"),
			type: .init(type: TypeSyntax(stringLiteral: "[PyMethodDef]")),
			initializer: .init(value: ArrayExprSyntax(
				leftSquare: .leftSquareToken(),
				elements: elements.with(\.leadingTrivia, .newline),
				rightSquare: .rightSquareToken(leadingTrivia: .newline)
			))
//			initializer: .init(value: ArrayExprSyntax(elementsBuilder: {
//				for method in methods {
//					WrapFunction.asArrayElement(f: method)
//				}
//				ArrayElementSyntax(expression: ExprSyntax(stringLiteral: "PyMethodDef()"))
//			}))
		)
	}
}
extension WrapFunction {
	enum FunctionFlag {
		case function
		case method
		case static_method
		case class_method
		
		var flag: String {
			switch self {
			case .function:
				return ""
			case .method:
				return ""
			case .static_method:
				return ""
			case .class_method:
				return ""
			}
		}
	}
	
	func getMethodType() -> String {
		let nargs = _args_.count
		if nargs > 1 {
			return "PySwiftFunctionFast"
		}
		
		return "PySwiftFunction"
	}
	
	func getFlag(flag: FunctionFlag, keywords: Bool) -> String {
		
		let nargs = _args_.count
		
		var out = Set<String>()
		
		if keywords { out.insert("METH_KEYWORDS") }
		
		//if wrap_class != nil { out.insert("METH_METHOD")}
		
		switch nargs {
		case 0:
			out.insert("METH_NOARGS")
		case 1:
			out.insert("METH_O")
		default: // multi args
			out.insert("METH_FASTCALL")
		}
		
//		switch flag {
//		case .function:
//			break
//		case .method, .static_method, .class_method:
//			out.insert("METH_METHOD")
//		}
		switch flag {
		case .function: break
		case .method: 
			if nargs > 1 {
				//out.insert("METH_METHOD")
			}
		case .static_method: out.insert("METH_STATIC")
		case .class_method: out.insert("METH_CLASS")
		}
//		switch self {
//		case .PySwiftFunction:
//			return "METH_METHOD | METH_FASTCALL | METH_KEYWORDS"
//		case .PySwiftFunctionFast:
//			return "METH_METHOD | METH_FASTCALL | METH_KEYWORDS"
//		case .PySwiftFunctionFastKeywords:
//			return "METH_METHOD | METH_FASTCALL | METH_KEYWORDS"
//		case .PySwiftMethod:
//			return "METH_METHOD | METH_FASTCALL | METH_KEYWORDS"
//		}
		return out.joined(separator: " | ")
	}
}

extension PyMethods {
	
	
	enum MethodType: String {
		case PySwiftFunction
		case PySwiftFunctionFast
		case PySwiftFunctionFastKeywords
		case PySwiftMethod
		
		
		
	}
	
	
}
