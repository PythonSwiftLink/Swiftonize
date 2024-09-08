import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper



extension PyWrap.CollectionArg: ArgSyntax {
	public func callTupleElement(many: Bool) -> SwiftSyntax.TupleExprElementSyntax {
		switch type.element.py_type {
		case .other:
			let other = type.element as! PyWrap.OtherType
			//return .init(label: name, expression: ExprSyntax(stringLiteral: "PyUnpackOther()"))
			if no_label { return .init(expression: TryExprSyntax.unPackPyPointer(with: self, many: many, type: other.wrapped)) }
			return .init(
				label: name,
				expression: TryExprSyntax.unPackPyPointer(with: self, many: many, type: other.wrapped)
			)
		default: 
			if no_label { return .init(expression: TryExprSyntax.pyCast(arg: self, many: many)) }
			return .init(
			label: name,
			expression: TryExprSyntax.pyCast(arg: self, many: many)
		)
		}
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
	
	
}


extension PyWrap.CollectionType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		//"\(raw: self.element as! CustomStringConvertible)"
		.init(ArrayTypeSyntax(element: (element as! ArgTypeSyntax).typeSyntax))
	}
	
	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
		.init(type: typeSyntax)
	}
	
	public func callTupleElement(many: Bool, label: String?) -> SwiftSyntax.TupleExprElementSyntax {
		//		switch wrapped {
		//		case let other as PyWrap.OtherType:
		//			return .init(
		//				label: label,
		//				expression: TryExprSyntax.unPackPyPointer(with: other, many: many) as TryExprSyntax
		//			)
		//
		//		default: return .init(
		//			label: label,
		//			expression: TryExprSyntax.pyCast(arg: element, many: many) as TryExprSyntax
		//		)
		//		}
		fatalError()
	}
	
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		nil
	}
	
	
}
