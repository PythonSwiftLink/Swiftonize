
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import WrapContainers

extension ExprSyntax {
	init(closure: String) {
		//self.init(fromProtocol: ClosureExprSyntax(stringLiteral: closure))
		self.init(stringLiteral: closure)
	}
	static var `nil`: Self { .init(fromProtocol: NilLiteralExprSyntax()) }
}

extension WrapClass {
	class GenPySequenceMethods {
		
		
		required init?<S>(_ node: S) where S : SwiftSyntax.SyntaxProtocol {
			fatalError()
		}
		
		
		//var _syntaxNode: SwiftSyntax.Syntax {
		var output: ExprSyntax {
			guard cls.pySequenceMethods.count > 0 else { return .init(fromProtocol: NilLiteralExprSyntax()) }
			let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
			let out = FunctionCallExprSyntax(
				
				calledExpression: exp,
				leftParen: .leftParenToken(trailingTrivia: .newline),//.with(\.leadingTrivia, .newline),
				argumentList: .init {
					
					TupleExprElementSyntax(
						label: "length",
						expression: length_expr
					).with(\.leadingTrivia, .newline)
					
					
					TupleExprElementSyntax(
						label: "concat",
						expression: concat_expr
					).with(\.leadingTrivia, .newline)
					
					TupleExprElementSyntax(
						label: "repeat_",
						expression: repeat_expr
					).with(\.leadingTrivia, .newline)
					
					TupleExprElementSyntax(
						label: "get_item",
						expression: get_item_expr
					).with(\.leadingTrivia, .newline)
					
					TupleExprElementSyntax(
						label: "set_item",
						expression: set_item_expr
					).with(\.leadingTrivia, .newline)
					
					TupleExprElementSyntax(
						label: "contains",
						expression: contains_expr
					).with(\.leadingTrivia, .newline)
					
					TupleExprElementSyntax(
						label: "inplace_concat",
						expression: inplace_concat_expr
					).with(\.leadingTrivia, .newline)
					
					TupleExprElementSyntax(
						label: "inplace_repeat",
						expression: inplace_repeat_expr
					).with(\.leadingTrivia, .newline)//.with(\.leadingTrivia, .newline)
					
				},
				rightParen: .rightParenToken(leadingTrivia: .newline)
			)
			
			//print(out)
			return .init(out)
			
		}
		
		static var structure: SwiftSyntax.SyntaxNodeStructure = .choices([.node(FunctionCallExprSyntax.self)])
		
		func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
			nil
		}
	
		
		var length_expr: ExprSyntax = .nil
		var concat_expr: ExprSyntax = .nil
		var repeat_expr: ExprSyntax = .nil
		var get_item_expr: ExprSyntax = .nil
		var set_item_expr: ExprSyntax = .nil
		var contains_expr: ExprSyntax = .nil
		var inplace_concat_expr: ExprSyntax = .nil
		var inplace_repeat_expr: ExprSyntax = .nil
		
		let cls: WrapClass
		
		init(cls: WrapClass) {
			self.cls = cls
			handleExprs()
		}
		
		func setLengthExpr() {
			length_expr = .init(closure: """
			{ _self_ -> Int32 in
			do {
			if let _self_ = _self_ {
			return try UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__len__()
			}
			}
			catch _ {}
			return -1
			}
			""")
		}
		
		func setGetItemExpr() {
			get_item_expr = .init(closure: """
			{ _self_, idx -> PyPointer? in
			do {
			if let _self_ = _self_ {
			return try UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__getitem__(idx: idx)
			}
			}
			catch _ {}
			return nil
			}
			""")
		}

		func setSetItemExpr() {
			set_item_expr = .init(closure: """
			{ _self_, idx, value -> Int32 in
			do {
			if let _self_ = _self_, let value = value {
			return try UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__setitem__(idx: idx, value: PyPointer)
			}
			}
			catch _ {}
			return -1
			}
			""")
		}
		
		func handleExprs() {
			for method in cls.pySequenceMethods {
				
				switch method {
				case .__len__:
					
					setLengthExpr()
				case .__getitem__(let key, let returns):
					setGetItemExpr()
				case .__setitem__(let key, let value):
					setSetItemExpr()
				case .__delitem__(let key):
					break
				case .__missing__:
					break
				case .__reversed__:
					break
				case .__contains__:
//					contains_expr = .init(closure: """
//					""")
					break
				}
			}
	
		}
		
	}
	
	
	
	
	
}
