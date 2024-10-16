import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import WrapContainers


extension WrapClass {
	
	
	class PyAsyncMethods: ExprSyntaxProtocol {
		
		
		required init?<S>(_ node: S) where S : SwiftSyntax.SyntaxProtocol {
			fatalError()
		}
		
		
		var _syntaxNode: SwiftSyntax.Syntax {
			guard cls.pySequenceMethods.count > 0 else { return .init(fromProtocol: NilLiteralExprSyntax()) }
			let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
			let out: Syntax =  .init(FunctionCallExprSyntax(
				
				calledExpression: exp,
				//leftParen: .leftParen.with(\.leadingTrivia, .newline),
				leftParen: .leftParenToken(leadingTrivia: .newline),
				argumentList: .init {
					
					TupleExprElementSyntax(
						leadingTrivia: .newline,
						label: "am_await",
						expression: am_await_expr
					)
					.with(\.leadingTrivia, .newline)
					//.with(\.leadingTrivia, .newline)
					
					
					TupleExprElementSyntax(
						leadingTrivia: .newline,
						label: "am_aiter",
						expression: am_aiter_expr
					)
					
					TupleExprElementSyntax(
						leadingTrivia: .newline,
						label: "am_anext",
						expression: am_anext_expr
					)
					
					TupleExprElementSyntax(
						leadingTrivia: .newline,
						label: "am_send",
						expression: am_send_expr
					)
	
				},
				rightParen: .rightParenToken(leadingTrivia: .newline)
			))
			
			//print(out)
			return out
			
		}
		
		static var structure: SwiftSyntax.SyntaxNodeStructure = .choices([.node(FunctionCallExprSyntax.self)])
		
		func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
			nil
		}
		
		
		var am_await_expr: ExprSyntax = .nil
		var am_aiter_expr: ExprSyntax = .nil
		var am_anext_expr: ExprSyntax = .nil
		var am_send_expr: ExprSyntax = .nil
		
		let cls: WrapClass
		
		init(cls: WrapClass) {
			self.cls = cls
			handleExprs()
		}
		
		func setAmAwaitExpr() {
			am_await_expr = .init(closure: """
			{ _self_ -> PyPointer? in
			do {
			if let _self_ = _self_ {
			return try UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__await__()
			}
			}
			catch _ {}
			return -1
			}
			""")
		}
		
		func setAmAIterExpr() {
			am_aiter_expr = .init(closure: """
			{ _self_ -> PyPointer? in
			do {
			if let _self_ = _self_ {
			return try UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__aiter__(idx: idx)
			}
			}
			catch _ {}
			return nil
			}
			""")
		}
		
		func setAmANextExpr() {
			am_anext_expr = .init(closure: """
			{ _self_ -> PyPointer? in
			do {
			if let _self_ = _self_ {
			return try UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__aiter__(idx: idx)
			}
			}
			catch _ {}
			return nil
			}
			""")
		}
		
		func handleExprs() {
			for method in cls.pyAsyncMethods {
				
				switch method {
				case .__await__:
					setAmAwaitExpr()
				case .__aiter__:
					setAmAIterExpr()
				case .__anext__:
					setAmANextExpr()
				}
			}
			
		}
		
	}
	
	
	
	
	
}
