//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/02/2024.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

public protocol ArgSyntax {
	//var typeExpr: TypeExprSyntax { get }
	
	//var typeSyntax: TypeSyntax { get }
	
	//var typeAnnotation: TypeAnnotationSyntax { get }
	
	func callTupleElement(many: Bool) -> TupleExprElementSyntax
	
	func extractDecl(many: Bool) -> VariableDeclSyntax?
}

public protocol ArgTypeSyntax {
	var typeExpr: TypeExprSyntax { get }
	
	var typeSyntax: TypeSyntax { get }
	
	var typeAnnotation: TypeAnnotationSyntax { get }
	
	//func expression(many: Bool) -> ExprSyntax
	
	//func callTupleElement(many: Bool, label: String?) -> TupleExprElementSyntax
	
	//func extractDecl(many: Bool) -> VariableDeclSyntax?
}

//extension AnyArg: ArgTypeSyntax {
//	public var typeExpr: SwiftSyntax.TypeExprSyntax {
//		(type as! ArgTypeSyntax).typeExpr
//	}
//	
//	public var typeSyntax: SwiftSyntax.TypeSyntax {
//		(type as! ArgTypeSyntax).typeSyntax
//	}
//	
//	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
//		(type as! ArgTypeSyntax).typeAnnotation
//	}
//	
//	public func callTupleElement(many: Bool, label: String?) -> SwiftSyntax.TupleExprElementSyntax {
//		(type as! ArgTypeSyntax).callTupleElement(many: many, label: name)
//	}
//	
//	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
//		(type as! ArgTypeSyntax).extractDecl(many: many)
//	}
//	
//	
//}

extension Array where Element == any (TypeProtocol) {
	var tupleType: TupleTypeSyntax {
		.init(elements: .init {
			for type in self {
				
				TupleTypeElementSyntax(type: (type as! ArgTypeSyntax).typeSyntax)
			}
		})
	}
	var tupleTypeList: TupleTypeElementListSyntax {
		.init {
			for type in self {
				
				TupleTypeElementSyntax(type: (type as! ArgTypeSyntax).typeSyntax)
			}
		}
	}
}
extension Array where Element == any (ArgTypeSyntax) {
	var tupleType: TupleTypeSyntax {
		.init(elements: .init {
			for type in self {
				TupleTypeElementSyntax(type: type.typeSyntax)
			}
		})
	}
}



extension PyWrap.TupleType {
	
}



