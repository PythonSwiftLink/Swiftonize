import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper


extension PyWrap.StringArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.TupleExprElementSyntax {
		.pyCast(arg: self, many: many)
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		
		let expr: ExprSyntaxProtocol? = switch type.py_type {
		case .url:
			ExprSyntax(stringLiteral: "\(name).path")
		case .error:
			ExprSyntax(stringLiteral: "\(name).localizedDescription")
		default:
			nil
		}
		guard let expr = expr else { return nil }
		return .init(
			.let,
			name: .init(stringLiteral: name),
			type: .init(type: TypeSyntax("String")),
			initializer: .init(value: expr)
		)
	}
}


extension PyWrap.StringType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		switch py_type {
		case .url:
			return "URL"
		case .error:
			return "Error"
		default:
			return "String"
		}
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

