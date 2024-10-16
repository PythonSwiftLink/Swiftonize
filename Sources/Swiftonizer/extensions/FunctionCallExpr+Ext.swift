//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/02/2024.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

typealias FCallExpr = FunctionCallExprSyntax

extension ExprSyntaxProtocol where Self == MemberAccessExprSyntax {
	static func getClassPointer(_ label: String) -> MemberAccessExprSyntax {
		
		let output = MemberAccessExprSyntax(
			//            base: .init(stringLiteral: "__self__"),
			base: ExprSyntax(stringLiteral: "__self__"),
			dot: .periodToken(),
			name: "get\(raw: label)Pointer"
		)
		return output
	}
}

extension FunctionCallExprSyntax {
	
	static func getClassPointer(_ label: String) -> FunctionCallExprSyntax {
		return .init(
			
			calledExpression: .getClassPointer(label),
			leftParen: .leftParenToken(),
			argumentList: .init([]),
			rightParen: .rightParenToken()
		)
	}
	
	static func pyCall<S: ExprSyntaxProtocol>(_ src: S, args: [ArgSyntax], cls: PyWrap.Class? = nil) -> FunctionCallExprSyntax {
		let many = args.count > 1
		let tuple = TupleExprElementListSyntax {
			for arg in args {
				
				//(arg as! WrapArgSyntax).callTupleElement(many: many)//.with(\.leadingTrivia, .newline)
				arg.callTupleElement(many: many)
					.with(\.leadingTrivia, .newline)
			}
		}//.with(\.leadingTrivia, .newline)
		
		return .init(
			calledExpression: src,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken()
			//trailingTrivia: .newline
		)
		
		//return .init(calledExpression: .getClassPointer(label), argumentList: tuple)
	}
	
	static func pyCall(_ label: String, args: [ArgSyntax]) -> FunctionCallExprSyntax {
		let many = args.count > 1
		let tuple = LabeledExprListSyntax {
			for arg in args {
				arg.callTupleElement(many: many)
					.with(\.leadingTrivia, .newline)
				//				if arg.type == .other {
				//					.pyUnpack(with: arg as! otherArg, many: many)
				//				} else {
				//					.pyCast(arg: arg, many: many)
				//				}
			}
		}
		
		return .init(
			calledExpression: label.expr,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken()
		)
		
		//return .init(calledExpression: .getClassPointer(label), argumentList: tuple)
	}
	var codeBlockItem: CodeBlockItemSyntax { .init(item: .init(self)) }
	
	
	
}


extension FunctionCallExprSyntax {
//	static func cString(_ string: String) -> Self {
//		return .init(callee: DeclReferenceExprSyntax(baseName: .identifier("cString"))) {
//			LabeledExprSyntax(expression: StringLiteralExprSyntax(content: string))
//		}
//	}
//	
//	static func cString(multi string: String) -> Self {
//		return .init(callee: DeclReferenceExprSyntax(baseName: .identifier("cString"))) {
//			LabeledExprSyntax(expression: StringLiteralExprSyntax(openingQuote: .multilineStringQuoteToken(trailingTrivia: .newline), content: string, closingQuote: .multilineStringQuoteToken()))
//		}
//	}
	
	
}
public extension FunctionCallExprSyntax {
	
	var initClause: InitializerClauseSyntax {
		.init(value: self)
	}
	
	init(
		name: String,
		trailingClosure: ClosureExprSyntax? = nil,
		additionalTrailingClosures: MultipleTrailingClosureElementListSyntax = [],
		@LabeledExprListBuilder argumentList: () -> LabeledExprListSyntax = { [] }
	) {
		self.init(callee: ExprSyntax(stringLiteral: name), trailingClosure: trailingClosure, additionalTrailingClosures: additionalTrailingClosures, argumentList: argumentList)
	}
}
