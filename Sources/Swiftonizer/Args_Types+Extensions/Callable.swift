import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

extension PyWrap.CallableArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.TupleExprElementSyntax {
		if no_label { return .init(expression: "_\(name)".expr) }
		return .init(label: name, expression: "_\(name)".expr)
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
	
	
}



extension PyWrap.CallableType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		let _input = input as! ArgTypeSyntax
		
		return .init(
			FunctionTypeSyntax(
				parameters: input.types.tupleTypeList,
				returnClause: .init(type: TypeSyntax(stringLiteral: "Void"))
			)
		)
	}
	
	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
		.init(type: typeSyntax)
	}
	
	
}
