import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper


extension PyWrap.TupleArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.LabeledExprSyntax {
		.pyCast(arg: self, many: many)
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
	
	
}


extension PyWrap.TupleType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		//.init(TupleTypeSyntax(elements: tupleTypeList))
		.init(stringLiteral: "SomeTuple")
	}
	
	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
		.init(type: typeSyntax)
	}
	
	public var tupleTypeList: TupleTypeElementListSyntax {
		types.tupleTypeList
	}
}
