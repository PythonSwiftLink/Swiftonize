import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

extension PyWrap.BoolArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.TupleExprElementSyntax {
		.pyCast(arg: self, many: many)
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
	
}

extension PyWrap.BoolType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		"Bool"
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
