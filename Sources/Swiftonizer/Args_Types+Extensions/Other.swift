import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper



extension PyWrap.OtherArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.TupleExprElementSyntax {
		.pyUnpack(with: self, many: many)
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
	
	
}

extension PyWrap.OtherType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		.init(stringLiteral: wrapped)
	}
	
	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
		.init(type: typeSyntax)
	}
	
	
}
