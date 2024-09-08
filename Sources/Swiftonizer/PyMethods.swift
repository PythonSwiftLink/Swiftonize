import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

import PyWrapper
import PyAst
import SwiftParser



struct PyMethods {
	
	var cls: PyWrap.Class?
	var methods: [PyWrap.Function] = []
	let is_public: Bool
	let custom_title: String?
	init(cls: PyWrap.Class? = nil, methods: [PyWrap.Function]? = nil, is_public: Bool = false, custom_title: String? = nil) {
		self.cls = cls
		self.methods = cls?.functions?.filter({!$0.static}) ?? methods ?? []
		self.is_public = is_public
		self.custom_title = custom_title
	}
	
	
	
	var output: VariableDeclSyntax {
		
		let elements: ArrayElementListSyntax = .init {
			for method in methods {
				PyMethodGenerator(cls: cls, function: method).asArrayElement
//				Self.asArrayElement(f: method)
//					.with(\.trailingComma, .commaToken(trailingTrivia: .newline))
			}
			ArrayElementSyntax(expression: ExprSyntax(stringLiteral: "PyMethodDef()"))
		}
		var modifiers: [DeclModifierSyntax] = []
		if cls != nil {
			modifiers.append(.fileprivate)
			modifiers.append(.static)
		} else {
			if is_public {
				modifiers.append(.public)
			}
		}
		return .init(
			modifiers: .init(modifiers),
			.var,
			name: .init(stringLiteral: custom_title ?? "PyMethods"),
			type: .init(type: TypeSyntax(stringLiteral: "[PyMethodDef]")),
			initializer: .init(value: ArrayExprSyntax(
				leftSquare: .leftSquareToken(),
				elements: elements.with(\.leadingTrivia, .newline),
				rightSquare: .rightSquareToken(leadingTrivia: .newline)
			))
		)
	}
	
	static func asArrayElement(f: PyWrap.Function) -> ArrayElementSyntax {
		let maxArgs = f.args.count - f.defaults_name.count
		let meth_or_func: PyWrap.Function.FunctionFlag = f.class != nil ? .method : .function
		
		let closure: ClosureExprSyntax = .init(
			signature: f.getPyMethodDefSignature(flag: meth_or_func, keywords: false),
			//statements: PySwiftClosure(function: f).statements
			statements: ""
		)
		//		let closure: ClosureExprSyntax = .init(signature: f._args_.signature(), statements: .init {
		//			"return nil"
		//		})
		
		return .init(expression: FunctionCallExprSyntax.pyMethodDef(
			name: f.name,
			doc: "yo",
			flag: f.getFlag(flag: meth_or_func, keywords: false),
			ftype: f.getMethodType(),
			pymethod: closure
		))
	}
}
extension PyWrap.Function {
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
		let nargs = args.count
		if nargs > 1 {
			return "PySwiftFunctionFast"
		}
		
		return "PySwiftFunction"
	}
	
	func getFlag(flag: FunctionFlag, keywords: Bool) -> String {
		
		let nargs = args.count
		
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



