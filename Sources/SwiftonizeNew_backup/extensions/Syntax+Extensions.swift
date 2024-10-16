import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

import WrapContainers
import PyAst
import PySwiftCore
import SwiftParser



extension DeclReferenceExprSyntax {
	static var METH_O: Self {
		.init(baseName: .identifier("METH_O"))
	}
}

extension FunctionCallExprSyntax {
	static func unsafeBitCast(pymethod: ClosureExprSyntax, from type: String = "PySwiftCFunc") -> Self {
		.init(
			calledExpression: DeclReferenceExprSyntax(baseName: .identifier("unsafeBitCast")),
			leftParen: .leftParenToken(),
			arguments: .init {
				LabeledExprSyntax(expression: AsExprSyntax(
					expression: pymethod,
					type: TypeSyntax(stringLiteral: type)
				))
				LabeledExprSyntax(label: "to", expression: ExprSyntax(stringLiteral: "PyCFunction.self"))
			},
			rightParen: .rightParenToken()
		)
	}
	
	static func cString(_ string: String) -> Self {
		return .init(callee: DeclReferenceExprSyntax(baseName: .identifier("cString"))) {
			LabeledExprSyntax(expression: StringLiteralExprSyntax(content: string))
		}
	}
	
	static func cString(multi string: String) -> Self {
		return .init(callee: DeclReferenceExprSyntax(baseName: .identifier("cString"))) {
			LabeledExprSyntax(expression: StringLiteralExprSyntax(openingQuote: .multilineStringQuoteToken(trailingTrivia: .newline), content: string, closingQuote: .multilineStringQuoteToken()))
		}
	}
	
	static func pyMethodDef(name: String, doc: String, flag: String, ftype: String, pymethod: ClosureExprSyntax) -> Self {
		
		return .init(callee: ExprSyntax(stringLiteral: "PyMethodDef")) {
			LabeledExprSyntax(
				label: "ml_name",
				expression: cString(name)
			).with(\.trailingComma, .commaToken(trailingTrivia: .newline)).with(\.leadingTrivia, .newline)
			LabeledExprSyntax(
				label: "ml_meth",
				expression: unsafeBitCast(pymethod: pymethod, from: ftype)
			).with(\.trailingComma, .commaToken(trailingTrivia: .newline))
//			LabeledExprSyntax(
//				label: "ml_flags",
//				expression: DeclReferenceExprSyntax.METH_O
//			).with(\.trailingComma, .commaToken(trailingTrivia: .newline))
			LabeledExprSyntax(
				label: "ml_flags",
				expression: flag.expr
			).with(\.trailingComma, .commaToken(trailingTrivia: .newline))
			LabeledExprSyntax(
				label: "ml_doc",
				expression: cString(multi: doc)
			)
		}
			.with(\.leftParen, .leftParenToken())
			.with(\.rightParen, .rightParenToken(leadingTrivia: .newline))
	}
}

extension ExprSyntaxProtocol {
	static func _cString(_ string: String) -> Self {
		.init(FunctionCallExprSyntax.cString(string))!
	}
	
	static func _cString(multi string: String) -> Self {
		.init(FunctionCallExprSyntax.cString(multi: string))!
	}
}

extension TypeSyntax {
	static var optPyPointer: Self { TypeSyntax(stringLiteral: "PyPointer?")}
	static var pyPointer: Self { TypeSyntax(stringLiteral: "PyPointer")}
}

extension ReturnClauseSyntax {
	static var optPyPointer: Self { .init(type: TypeSyntax.optPyPointer) }
	static var pyPointer: Self { .init(type: TypeSyntax.pyPointer) }
}

extension Array where Element == any WrapArgProtocol {
	func signature() -> ClosureSignatureSyntax {
		switch count {
		case 0:
			return .init(parameterClause: .simpleInput(.init{
				.init(name: .identifier("__self__"))
			}), returnClause: .optPyPointer )
		default:
			return .init(parameterClause: .simpleInput(.init{
				.init(name: .identifier("__self__"))
			}), returnClause: .optPyPointer )
		}
		
	}
}
extension WrapFunction {
	
	func getPyMethodDefSignature(flag: FunctionFlag, keywords: Bool) -> ClosureSignatureSyntax {
		let nargs = _args_.count
		let list = ClosureParameterListSyntax {
			switch flag {
			case .function, .static_method:
				"_"
			case .method, .class_method:
				"__self__"
			}
			if flag == .class_method || flag == .static_method {
				"__type__"
			}
			if nargs > 0 { "__arg\(raw: nargs > 2 ? "s" : "")__" }
			if nargs > 1 { "__nargs__" }
			
			if keywords {
				"__kw__"
			} else {
				//if nargs > 1 { "_" }
			}
		}
		
		return .init(parameterClause: .parameterClause(.init(parameters: list)), returnClause: nil, inKeyword: .keyword(.in))
	}
	
	static func asArrayElement(f: WrapFunction) -> ArrayElementSyntax {
		let meth_or_func: FunctionFlag = f.wrap_class != nil ? .method : .function
		
		let closure: ClosureExprSyntax = .init(
			signature: f.getPyMethodDefSignature(flag: meth_or_func, keywords: false),
			statements: PySwiftClosure(function: f).statements)
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


extension ExprSyntaxProtocol {
	func xIncRef() -> MemberAccessExprSyntax {
		.init(base: self, name: .identifier("xIncRef"))
	}
}


extension DeclModifierListSyntax.Element {
	static var `static`: Self { .init(name: .keyword(.static)) }
	static var `fileprivate`: Self { .init(name: .keyword(.fileprivate)) }
	static var `public`: Self { .init(name: .keyword(.public)) }
}


