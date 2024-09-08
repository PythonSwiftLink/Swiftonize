
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

extension FunctionCallExprSyntax {
	static func pyErr_SetString(_ string: String) -> Self {
		
		return .init(callee: ExprSyntax(stringLiteral: "PyErr_SetString") ) {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "PyExc_IndexError"))
			//LabeledExprSyntax(expression: StringLiteralExprSyntax(content: "\(string)"))
			LabeledExprSyntax(expression: string.makeLiteralSyntax() )
		}
	}
	
	static func pyDict_GetItem(_ o: String, _ key: String) -> Self {
		
		return .init(callee: ExprSyntax(stringLiteral: "PyDict_GetItem") ) {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: o))
			//LabeledExprSyntax(expression: StringLiteralExprSyntax(content: "\(key)"))
			LabeledExprSyntax(expression: key.makeLiteralSyntax() )
		}
	}
	
	static func pyTuple_GetItem(_ o: String, _ key: Int) -> Self {
		
		return .init(callee: ExprSyntax(stringLiteral: "PyTuple_GetItem") ) {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: o))
			LabeledExprSyntax(expression: IntegerLiteralExprSyntax(key) )
		}
	}
	
}




extension GuardStmtSyntax {
	static func nargs_kwargs(_ n: Int) -> Self {
		return try! .init("guard nkwargs + nargs >= \(raw: n) else") {
			FunctionCallExprSyntax.pyErr_SetString("Args missing needed \(n)")
			"return -1"
		}
	}
}



extension SequenceExprSyntax {
	
	init(pyDict arg: AnyArg) {
		self.init(elements: .init(itemsBuilder: {
			//IdentifierExpr(stringLiteral: arg.name)
			ExprSyntax(stringLiteral: "\(arg.self)")
			AssignmentExprSyntax()
			TryExprSyntax.pyDict_GetItem("kw", "\(arg.self)")
		}))
	}
	
	init(pyTuple arg: AnyArg) {
		self.init(elements: .init(itemsBuilder: {
			//            IdentifierExpr(stringLiteral: arg.name)
			ExprSyntax(stringLiteral: "\(arg.self)")
			AssignmentExprSyntax()
			TryExprSyntax.pyTuple_GetItem("_args_", 0)
		}))
	}
}




extension ExprSyntax {
	init(nilOrExpression exp: ExprSyntaxProtocol?) {
		if let exp = exp {
			self.init(fromProtocol: exp)
		} else {
			self.init(fromProtocol: NilLiteralExprSyntax())
		}
		
	}
	
}
extension LabeledExprSyntax {
	init(label: String, nilOrExpression exp: ExprSyntax?) {
		if let exp = exp {
			self.init(label: label, expression: exp)
		} else {
			self.init(label: label, expression: NilLiteralExprSyntax() )
		}
		
	}
	init(nilOrExpression exp: ExprSyntax?) {
		if let exp = exp {
			self.init(expression: exp)
		} else {
			self.init(expression: NilLiteralExprSyntax() )
		}
		
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

extension Array where Element == any TypeProtocol {
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


func countCompare(_ label: String,_ op: TokenKind, _ count: Int) -> ConditionElementSyntax {
	.init(condition: .expression(.init(SequenceExprSyntax(
		elements: .init {
			//            IdentifierExprSyntax(stringLiteral: label)
			ExprSyntax(stringLiteral: label)
			BinaryOperatorExprSyntax(operatorToken: .init(op, presence: .present))
			//IntegerLiteralExprSyntax(stringLiteral: String(count))
			IntegerLiteralExprSyntax(integerLiteral: count)
		}
	))))
}

func countCompare(_ label: String,_ op: String, _ count: Int) -> ConditionElementSyntax {
	.init(condition: .expression(.init(SequenceExprSyntax(
		elements: .init {
			//            IdentifierExprSyntax(stringLiteral: label)
			ExprSyntax(stringLiteral: label)
			BinaryOperatorExprSyntax(operatorToken: .identifier(op))
			//IntegerLiteralExprSyntax(stringLiteral: String(count))
			IntegerLiteralExprSyntax(integerLiteral: count)
		}
	))))
}


extension GuardStmtSyntax {
	var codeBlockItem: CodeBlockItemSyntax { .init(item: .init(self)) }
}
