
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import WrapContainers


extension WrapClass {
	public class PyMappingMethods {
		
		
		required init?<S>(_ node: S) where S : SwiftSyntax.SyntaxProtocol {
			fatalError()
		}

		
		//var _syntaxNode: SwiftSyntax.Syntax {
		var output: ExprSyntax {
//			guard cls.pySequenceMethods.count > 0 else { return .init(fromProtocol: NilLiteralExprSyntax()) }
			let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
			let out = FunctionCallExprSyntax(
				
				calledExpression: exp,
				leftParen: .leftParenToken(trailingTrivia: .newline),//.with(\.leadingTrivia, .newline),
				argumentList: .init {
					
					TupleExprElementSyntax(
						label: "__len__",
						expression: length_expr
					).with(\.leadingTrivia, .newline)
					
					
					TupleExprElementSyntax(
						label: "__getitem__",
						expression: get_item_expr
					).with(\.leadingTrivia, .newline)
					
					TupleExprElementSyntax(
						label: "__setitem__",
						expression: set_item_expr
					).with(\.leadingTrivia, .newline)
					
					
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
		
		var get_item_expr: ExprSyntax = .nil
		var set_item_expr: ExprSyntax = .nil
		
		
		let cls: WrapClass
		
		init(cls: WrapClass) {
			self.cls = cls
			setLengthExpr()
			setGetItemExpr()
			setSetItemExpr()
		}
		
		func setLengthExpr() {
			length_expr = .init(closure: """
				{ _self_ -> Int in
				do {
				if let _self_ = _self_ {
				return try UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__len__()
				}
				}
				catch _ {}
				return -1
				}
				"""
			)
		}
		
		func setGetItemExpr() {
			get_item_expr = .init(closure: """
				{ __self__, key -> PyPointer? in
				guard let __self__ = __self__, let key = key else { return .None }
				do {
				return try UnPackPySwiftObject(with: __self__, as: \(cls.title).self).__getitem__(
				key: try String(object: key)
				)
				}
				catch _ {
				PyErr_Print()
				}
				return .None
				}
				"""
			)
		}
		
		func setSetItemExpr() {
			set_item_expr = .init(closure: """
				{ __self__, key, value -> Int32 in
				guard let __self__ = __self__, let key = key else { return -1 }
				do {
				if let value = value {
					return try UnPackPySwiftObject(with: __self__, as: \(cls.title).self).__setitem__(
					key: try String(object: key),
					value: value
					)
				} else {
					return try UnPackPySwiftObject(with: __self__, as: \(cls.title).self).__delitem__(
					key: try String(object: key)
					)
					}
				}
				catch let err {
				PyErr_Print()
				}
				return -1
				}
				
				"""
			)
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
