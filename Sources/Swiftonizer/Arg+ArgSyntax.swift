
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper
extension LabeledExprSyntax {
	
	static func pyCast(arg: any ArgProtocol, many: Bool) -> Self {
		switch arg {
		default:
			if arg.no_label {
				return .init(expression: TryExprSyntax.pyCast(arg: arg, many: many))
			}
			return .init(label: arg.name, expression: TryExprSyntax.pyCast(arg: arg, many: many))
		}
		
	}
	
	
	
	static func optionalPyCast(arg: any ArgProtocol, many: Bool) -> Self {
		
		let id = IdentifierExprSyntax(identifier: .identifier("optionalPyCast"))
		var label: String {
			if many { return "__args__[\(arg.index)]"}
			return arg.name
		}
		let tuple = LabeledExprListSyntax {
			"from"._tuplePExprElement(label)
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken()
		)
		if arg.no_label {
			return .init(expression: f_exp)
		}
		return .init(
			label: arg.name,
			expression: f_exp //.init(f_exp)
		)
		
		
	}
	static func pyUnpack(with arg: PyWrap.OtherArg, many: Bool) -> Self {
		if arg.no_label {
			return .init(expression: TryExprSyntax.unPackPyPointer(with: arg, many: many, type: arg.type.wrapped) )
		}
		return .init(
			label: arg.name,
			expression: TryExprSyntax.unPackPyPointer(with: arg, many: many, type: arg.type.wrapped)  //as TryExprSyntax
		)
	}
	static func pyUnpack(optional arg: PyWrap.OptionalArg, many: Bool) -> Self {
		if arg.no_label {
			return .init(expression: TryExprSyntax.unPackPyPointer(with: arg, many: many, type: arg.type.wrapped.string) )
		}
		return .init(
			label: arg.name,
			expression: TryExprSyntax.unPackPyPointer(with: arg, many: many, type: arg.type.wrapped.string)  //as TryExprSyntax
		)
	}
}



















