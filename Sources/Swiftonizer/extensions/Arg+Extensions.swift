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




extension Array where Element == AnyArg {
	var parameterList: FunctionParameterListSyntax {
		return .init {
			for par in self {
				par.functionParameter
			}
		}
	}
	
	var cParameterList: ClosureParameterListSyntax {
		
		return .init {
			
		}
		return .init {
			for par in self {
				par.clossureParameter
			}
		}
	}
	
	var closureParameterClause: ClosureParameterClauseSyntax {
		.init(parameters: cParameterList)
	}
	
	var parameterClause: ParameterClauseSyntax {
		.init(parameterList: parameterList)
	}
	var argConditions: [ConditionElementSyntax] {
		switch count {
		case 0: return []
		case 1: return [first!.__arg__optionalGuardUnwrap]
		default: return map(\.optionalGuardUnwrap)
		}
		
	}
}


extension AnyArg {
	
	var __arg__optionalGuardUnwrap: ConditionElementSyntax {
		name.__arg__optionalGuardUnwrap
	}
	var optionalGuardUnwrap: ConditionElementSyntax {
		name.optionalGuardUnwrap
	}
	
	
	var _typeSyntax: TypeSyntax { (type as! ArgTypeSyntax).typeSyntax  }
	
	var clossureParameter: ClosureParameterSyntax {
		var secondName: TokenSyntax? {
			//            if options.contains(.) {
			//                return .init(.identifier("_"))?.withTrailingTrivia(.space)
			//            }
			if let optional_name = optional_name {
				//return .init(.identifier(optional_name))?.withTrailingTrivia(.space)
				return .init(stringLiteral: optional_name).with(\.trailingTrivia, .space)
			}
			return nil
		}
		if no_label {
			return .init(
				firstName: .identifier("_ "),
				secondName: .identifier(name),
				colon: .colonToken(),
				type: _typeSyntax
			)
		}
		
		return .init(
			firstName: .identifier(name),
			secondName: secondName,
			colon: .colonToken(),
			type: _typeSyntax
		)
	}
	
	var functionParameter: FunctionParameterSyntax {
		var secondName: TokenSyntax? {
			//            if options.contains(.) {
			//                return .init(.identifier("_"))?.withTrailingTrivia(.space)
			//            }
			if let optional_name = optional_name {
				//return .init(.identifier(optional_name))?.withTrailingTrivia(.space)
				return .init(stringLiteral: optional_name).with(\.trailingTrivia, .space)
			}
			return nil
		}
		if no_label {
			return .init(
				firstName: .identifier("_"),
				secondName: .identifier(name),
				colon: .colonToken(),
				type: _typeSyntax
			)
		}
		return .init(
			firstName: .identifier(name),
			secondName: secondName,
			colon: .colonToken(),
			type: _typeSyntax
		)
		//        return .init(
		//            firstName: secondName,
		//            secondName: .identifier(name),
		//            colon: .colonToken(),
		//            type: _typeSyntax
		//        )
		
		//        var arg_string: String {
		//            if let extract = self as? PyCallbackExtactable {
		//                return extract.function_arg
		//            }
		//            if options.contains(.alias) {
		//                return "\(optional_name ?? "") \(swift_callback_func_arg)"
		//            }
		//            return swift_callback_func_arg
		//        }
		//        return arg_string.functionParameter
	}
	//    var typeSyntax: TypeSyntaxProtocol {
	//
	//        switch self {
	//        case let array as collectionArg:
	//            return ArrayType(stringLiteral: array.__argType__)
	//        default:
	//            return SimpleTypeIdentifier(stringLiteral: __argType__ )
	//        }
	//
	//    }
	
	
}
