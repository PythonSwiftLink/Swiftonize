import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

extension PyWrap.PyObjectArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.TupleExprElementSyntax {
		if no_label { return .init(expression: (many ? "__args__[\(index ?? 0)]!" : name).expr) }
		return .init(label: name, expression: (many ? "__args__[\(index ?? 0)]!" : name).expr)
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
}

extension PyWrap.PyObjectType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		.init(stringLiteral: "PyPointer")
	}
	
	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
		.init(type: typeSyntax)
	}
}
