//
//  File.swift
//  
//
//  Created by CodeBuilder on 12/02/2024.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax


extension String {
	var `import`: ImportDeclSyntax {
//		.init(path: .init(itemsBuilder: {
//			.init(name: .identifier(self))
//		}))
		.init(path: .init { .init(name: .identifier(self)) } )
	}
	
	var expr: ExprSyntax { .init(stringLiteral: self) }
	
//	var inheritanceType: InheritedTypeSyntax {
//		//        InheritedTypeSyntax(typeName: SimpleTypeIdentifier(stringLiteral: self))
//		.init(type: SimpleTypeIdentifierSyntax(name: .identifier(self)))
//	}
	
	public func typeSyntax() -> TypeSyntax {
		.init(stringLiteral: self)
	}
	public var inheritanceType: InheritedTypeSyntax {
		InheritedTypeSyntax(type: typeSyntax() )
	}
}


extension String {
	func tuplePExprElement(_ label: String) -> TupleExprElementSyntax {
		//.init(label: self, expression: ExprSyntax(stringLiteral: "\"\(label)\""))
		.init(label: self, expression: label.makeLiteralSyntax() )
	}
	
	func _tuplePExprElement(_ label: String) -> TupleExprElementSyntax {
		.init(label: self, expression: label.expr)
	}
	
	
	var tupleExprElement: LabeledExprSyntax { .init(expression: ExprSyntax(stringLiteral: self)) }
	var _tupleExprElement: LabeledExprSyntax { .init(expression: "\(self)".makeLiteralSyntax() ) }

}


extension String {
	
	var nargsCheck: ConditionElementSyntax {
		.init(condition: .expression(.init(SequenceExprSyntax(
			elements: .init {
				//IdentifierExprSyntax(stringLiteral: "__nargs__")
				ExprSyntax(stringLiteral: "__nargs__")
				BinaryOperatorExprSyntax(operatorToken: .leftAngleToken())
				//IntegerLiteralExprSyntax(stringLiteral: self)
				ExprSyntax(stringLiteral: self)
			}
		))))
	}
	var __arg__optionalGuardUnwrap: ConditionElementSyntax {
		.init(condition: .optionalBinding(.init(
			bindingSpecifier: .identifier("let"),
			pattern: IdentifierPatternSyntax(identifier: .identifier(self)),
			initializer: "__arg__".initializerClause
		)))
	}
	
	var optionalGuardUnwrap: ConditionElementSyntax {
		.init(condition: .optionalBinding(.init(
			bindingSpecifier: .identifier("let"),
			pattern: IdentifierPatternSyntax(identifier: .identifier(self)),
			initializer: self.initializerClause
		)))
	}
	
	var initializerClause: InitializerClauseSyntax {
		.init(equal: .equalToken(), value: expr)
	}
	
	
	var closureParameter: ClosureParamSyntax {
		.init(name: .identifier(self))
	}
	
	var codeBlockItem: CodeBlockItemSyntax { .init(stringLiteral: self) }
}


extension Array where Element == String {
	var codeBlockList: CodeBlockItemListSyntax {
		.init {
			for element in self {
				CodeBlockItemSyntax(stringLiteral: element)
			}
		}
	}
	var codeBlock: CodeBlockSyntax {
		.init(statements: codeBlockList)
	}
	
	var closureSignature: ClosureSignatureSyntax {
		.init(input: .simpleInput(closureInputList) )
	}
	
	var closureInputList: ClosureParamListSyntax {
		var list = ClosureParamListSyntax {
			for par in self {
				par.closureParameter
			}
		}
		list.leadingTrivia = .space
		list.trailingTrivia = .space
		return list
	}
	
}
