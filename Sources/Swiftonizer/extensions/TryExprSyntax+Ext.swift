

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

extension TryExprSyntax {
	
	static func pyDict_GetItem(_ o: String, _ key: String) -> Self {
		
		return .init(expression: FunctionCallExprSyntax.pyDict_GetItem(o, key))
	}
	
	static func pyTuple_GetItem(_ o: String, _ key: Int) -> Self {
		
		return .init(expression: FunctionCallExprSyntax.pyTuple_GetItem(o, key))
	}
}

extension FunctionCallExprSyntax {
	static func unPackPyPointer(with arg: AnyArg, many: Bool, type: String? = nil) -> FunctionCallExprSyntax {
		var _arg: String {
			if many { return "__args__[\(arg.index ?? 0)]"}
			return arg.name
		}
		
		return unPackPyPointer(with: _arg, many: many, type: type)
	}
	static func unPackPyPointer(with _arg: String, many: Bool, type: String? = nil) -> FunctionCallExprSyntax {
		//fatalError("unPackPyPointer\(arg.argType)")
		let id = IdentifierExprSyntax(identifier: .identifier("UnPackPyPointer"))
		
		let tuple = LabeledExprListSyntax {
			//TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: label)))
			//            "with"._tuplePExprElement("\(arg.other_type ?? "Unknown")PyType.pytype")
			"with"._tuplePExprElement("\(type ?? "Unknown").PyType")
			"from"._tuplePExprElement(_arg)
			"as"._tuplePExprElement("\( type ?? "Unknown").self")
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken()
		)
		return f_exp
		
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
	}
	
	
	
	
}

extension TryExprSyntax {
	
	static func pyCast(arg: AnyArg, many: Bool) -> TryExprSyntax {
		let id = IdentifierExprSyntax(identifier: .identifier("pyCast"))
		var label: String {
			if many { return "__args__[\(arg.index ?? 0)]"}
			return arg.name
		}
		let tuple = TupleExprElementListSyntax {
			"from"._tuplePExprElement(label)
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken()
		)
		return TryExprSyntax(tryKeyword: .keyword(.try), expression: f_exp)
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
	}
	//static func unPackPySwiftObject(with src: String, as type: String) -> TryExprSyntax {
	static func unPackPySwiftObject(with src: String, as type: String) -> FunctionCallExprSyntax {
		let id = IdentifierExprSyntax(identifier: .identifier("UnPackPySwiftObject"))
		
		let tuple = LabeledExprListSyntax {
			//TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
			LabeledExprSyntax(label: "with", expression: ExprSyntax(stringLiteral: src))
			LabeledExprSyntax(
				label: "as",
				expression: MemberAccessExprSyntax(
					base: ExprSyntax(stringLiteral: type),
					dot: .periodToken(),
					name: .identifier("self")
				)
			)
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken()
		)
		return f_exp
		
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
	}
	
	static func unPackPySwiftObject(with arg: AnyArg, many: Bool) -> FunctionCallExprSyntax {
		let id = IdentifierExprSyntax(identifier: .identifier("UnPackPySwiftObject"))
		var label: String {
			if many { return "__args__[\(arg.index ?? 0)]"}
			return arg.name
		}
		let tuple = TupleExprElementListSyntax {
			//TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: label)))
			"with"._tuplePExprElement(label)
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken(leadingTrivia: .newlines(2))
		)
		return f_exp
		
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
	}
	
	static func unPackPyPointer(with arg: AnyArg, many: Bool, type: String? = nil) -> TryExprSyntax {
		
		//		.init(tryKeyword: .tryKeywordSyntax(trailingTrivia: .keyword(.space)), expression: unPackPyPointer(with: arg, many: many) as FunctionCallExprSyntax)
		.init(tryKeyword: .keyword(.try, trailingTrivia: .space), expression: FunctionCallExprSyntax.unPackPyPointer(with: arg, many: many, type: type))
	}
	
	
	
	
}
