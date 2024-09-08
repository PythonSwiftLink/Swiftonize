
import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper


extension PyWrap.Function {
	
	func getPyMethodDefSignature(flag: FunctionFlag, keywords: Bool) -> ClosureSignatureSyntax {
		let nargs = args.count
		let list = ClosureParameterListSyntax {
			switch flag {
			case .function, .static_method:
				"_"
			case .method, .class_method:
				"__self__"
			}
			if flag == .class_method || flag == .static_method {
				"__type__"
			}
			if nargs == 0 { "_"}
			if nargs > 0 { "__arg\(raw: nargs > 1 ? "s" : "")__" }
			if nargs > 1 { "__nargs__" }
			
			if keywords {
				"__kw__"
			} else {
				//if nargs > 1 { "_" }
			}
		}
		
		return .init(parameterClause: .parameterClause(.init(parameters: list)), returnClause: nil, inKeyword: .keyword(.in))
	}
	
	
}


extension PyWrap.Function {
	
	//    var __init__: FunctionCallExprSyntax {
	//        //let cls_pointer: FunctionCallExprSyntax = .getClassPointer(wrap_class?.title ?? "Unknown")
	////        let src_member = MemberAccessExprSyntax(
	////            base: TryExprSyntax.unPackPySwiftObject(with: "s", as: wrap_class?.title ?? "Unknown"),
	////            dot: .period,
	////            name: .identifier(call_target ?? name)
	////        )
	//        let call = FunctionCallExprSyntax.
	////        let call = FunctionCallExprSyntax.pyCall(
	////            src_member,
	////            args: _args_,
	////            cls: wrap_class
	////        )
	//        return call.withRightParen(.rightParen.with(\.leadingTrivia, .newline))//.withRightParen(.rightParen.with(\.leadingTrivia, .newline)).with(\.leadingTrivia, .newline)
	//    }
	
	
	
	
	var assignFromClass: SequenceExprSyntax {
		.init {
			.init {
				//IdentifierExpr(stringLiteral: "_\(name)")
				ExprSyntax(stringLiteral: "_\(name)")
				AssignmentExprSyntax()
				pyGetAttr
				//MemberAccessExprSyntax(base: pyGetAttr, dot: .period, name: .identifier("xDECREF"))
			}
		}
	}
	
	func decref() -> MemberAccessExprSyntax {
		.init(base: ExprSyntax(stringLiteral: "_\(name)"), name: .identifier("decref()"))
	}
	
	var assignFromDict: SequenceExprSyntax {
		.init {
			.init {
				ExprSyntax(stringLiteral: "_\(name)")
				AssignmentExprSyntax()
				pyDictGet
			}
		}
	}
	
	
	var pyGetAttr: FunctionCallExprSyntax {
		//        .init(callee: IdentifierExpr(stringLiteral: "PyObject_GetAttr")) {
		//            "callback".tupleExprElement
		//            name._tupleExprElement
		//        }
		.init(callee: ExprSyntax(stringLiteral: "PyObject_GetAttr")) {
			"callback".tupleExprElement
			name._tupleExprElement
		}
	}
	
	var pyDictGet: FunctionCallExprSyntax {
		.init(callee: ExprSyntax(stringLiteral: "PyDict_GetItem")) {
			"callback".tupleExprElement
			name._tupleExprElement
		}
	}
}





public extension PyWrap.Function {
	
	var pyReturnStmt: ReturnStmtSyntax {
		switch returns?.py_type {
		case .None, .void:
			return .init(expression: MemberAccessExprSyntax(name: "None"))
		case .object:
			//return .init(expression: IdentifierExpr(stringLiteral: "\(name)_result"))
			return .init(expression: ExprSyntax(stringLiteral: "\(name)_result"))
		default:
			//            return .init(expression: MemberAccessExprSyntax(base: .init(stringLiteral: "\(name)_result"), name: "pyPointer"))
			return .init(expression: MemberAccessExprSyntax(base: ExprSyntax(stringLiteral: "\(name)_result"), name: .identifier("pyPointer")))
		}
		
	}
	
	var returnClause: ReturnClauseSyntax? {
		switch returns?.py_type {
		case .None, .void, .none:
			return nil
		default:
			//return ReturnClause(arrow: .arrow, returnType: (_return_ as! WrapArgSyntax).typeSyntax)
			return .init(type: (returns as! ArgTypeSyntax).typeSyntax)
		}
	}
	
	var signature: FunctionSignatureSyntax {
		.init(input: args.parameterClause, output: returnClause)
	}
	
	var csignature: ClosureSignatureSyntax {
		//.init(input: _args_.parameterClause, output: returnClause)
		//.init(input: .input(_args_.parameterClause), output: returnClause, inTok: .keyword(.in))
		.init(parameterClause: .parameterClause(args.closureParameterClause), returnClause: returnClause, inKeyword: .keyword(.in))
	}
	
	var function_header: FunctionDeclSyntax {
		.init(identifier: .identifier(call_target ?? name), signature: signature)
	}
	
	func withCodeLines(_ lines: [String]) -> FunctionDeclSyntax {
		var header = function_header
		header.body = .init{
			for line in lines { CodeBlockItemSyntax(stringLiteral: line) }
		}//lines.codeBlock
		return header
	}
	
	func withCodeLines(_ lines: [String]) -> ClosureExprSyntax {
		var header = ClosureExprSyntax(signature: csignature, statements: lines.codeBlockList)
		//header.statements = lines.codeBlockList
		return header
	}
	
	func withCodeLines(_ lines: [String]) -> String {
		var header = function_header
		header.body = lines.codeBlock
		return header.formatted().description
		//        FunctionDeclSyntax(
		//            identifier: .identifier(call_target ?? name),
		//            signature: signature,
		//            body: lines.codeBlock
		//        ).formatted().description
	}
	
	
	
	
	
}
