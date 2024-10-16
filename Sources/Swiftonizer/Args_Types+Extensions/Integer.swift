import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper


extension PyWrap.IntegerArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.TupleExprElementSyntax {
		if no_label { return .init(expression: TryExprSyntax.pyCast(arg: self, many: many)) }
		return .init(label: name, expression: TryExprSyntax.pyCast(arg: self, many: many))
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
}


extension PyWrap.IntegerType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		"\(wrapped)"
	}
	
	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
		.init(type: typeSyntax)
	}
	
	public func callTupleElement(many: Bool, label: String?) -> SwiftSyntax.TupleExprElementSyntax {
		fatalError()
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
	
	
}
