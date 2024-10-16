//
//  File.swift
//
//
//  Created by MusicMaker on 27/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftParser
import WrapContainers

extension WrapFunction {
	//	public var statements: SwiftSyntax.CodeBlockItemListSyntax {
	//		.init([.init(item: body)])
	//	}
	//
	public func withStatements(_ newChild: SwiftSyntax.CodeBlockItemListSyntax?) -> Self {
		fatalError()
	}
	
	public var body: SwiftSyntax.CodeBlockSyntax {
		PySwiftClosure(function: self).body
	}
	
	
	public func withBody(_ newChild: SwiftSyntax.CodeBlockSyntax?) -> Self {
		fatalError()
	}
	
	public var _syntaxNode: SwiftSyntax.Syntax {
		fatalError()
	}
	
	public static var structure: SwiftSyntax.SyntaxNodeStructure {
		fatalError()
	}
	
	public func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
		fatalError()
		
	}
	
	
}

class PySwiftClosure {
	
	let _function: WrapFunction?
	var function: WrapFunction { _function! }
	//var guard_line: String = ""
	var code: [String] = []
	var args: [WrapArgProtocol] { function._args_ }
	var defaults: [String] { function.default_args }
	var arg_count: Int { args.count }
	var defaults_count: Int { defaults.count }
	
	init(function: WrapFunction) {
		self._function = function
		//        if function._args_.count > 1 {
		//            guard_line = "guard nargs > 1, let _args_ = _args_, let s = s else { throw PythonError.call }"
		//        } else if function._args_.count == 1 {
		//            let arg = function._args_.first!
		//            guard_line = "guard let \(arg.name) = \(arg.name), let s = s else { throw PythonError.call }"
		//        }
	}
	
	required init?<S>(_ node: S) where S : SyntaxProtocol {
		self._function = nil
	}
	
	//private var codeBlock: CodeBlockSyntax { ([guard_line] + code).codeBlock }
	
	private func catchItem(_ label: String) -> CatchItemListSyntax {
		.init(
			arrayLiteral: .init(pattern: IdentifierPatternSyntax(identifier: .identifier(label)))
		)
	}
	
	private var catchClauseList: CatchClauseListSyntax {
		
		.init {
			CatchClauseSyntax(catchItem("let err as PythonError")) {
				if arg_count > 1 {
	 """
	 switch err {
	 case .call: err.triggerError("wanted \(arg_count) got \\(__nargs__)")
	 default: err.triggerError("hmmmmmm")
	 }
	 """.codeBlockItem
				} else {
					#"""
					switch err {
					case .call: err.triggerError("arg type Error")
					default: err.triggerError("hmmmmmm")
					}
					"""#.codeBlockItem
				}
			}
			CatchClauseSyntax(catchItem("let other_error")) {
				"other_error.pyExceptionError()".codeBlockItem
			}
			
		}
	}
	private var _guard: GuardStmtSyntax {
		let conditions = ConditionElementListSyntax {
			let arg_count = function._args_.count
			let defaults_count = function.default_args.count
			if arg_count > 1 {
				countCompare("__nargs__", " >= ", arg_count - defaults_count)
				"__args__".optionalGuardUnwrap
			} else {
				for arg in function._args_.argConditions {
					arg
				}
			}
			if function.wrap_class != nil {
				"__self__".optionalGuardUnwrap
			}
		}
		//        return .init(
		//            conditions: conditions,
		//            elseKeyword: .elseKeyword(leadingTrivia: .space),
		//            body: .init(statements: .init([
		//            .init(item: .init(ThrowStmtSyntax(stringLiteral: "throw PythonError.call")) )
		//        ])))
		return .init(
			conditions: conditions,
			elseKeyword: .keyword(.else, leadingTrivia: .space),
			body: .init(statements: .init([
				.init(item: .init(ThrowStmtSyntax(expression: ExprSyntax(stringLiteral: "PythonError.call"))) )
			])))
	}
	private var completionHandlers: ExprSyntax {
		
		
		
		
		.init(stringLiteral: "")
	}
	private var extracts: [CodeBlockItemSyntax] {
		let many = arg_count > 1
		return args.compactMap {
			if let extract = ($0 as! WrapArgSyntax).extractDecl(many: many) {
				return .init(item: .decl(.init(extract)))
			}
			return nil
		}
		//        return args.compactMap { arg in
		//            switch arg {
		//            case let call as callableArg:
		//                if many {
		//                    return .init(
		//                        item: .decl(.init(stringLiteral: "let _\(call.name) = _args_[\(call.idx)]!"))
		//                    )
		//                }
		//                return .init(
		//                    item: .decl(.init(stringLiteral: "let _\(call.name) = \(call.name)"))
		//                )
		//            default: return nil
		//            }
		//        }
	}
	
	//	func caseItem(_ v: Int) -> CaseItem {
	//		.init(pattern: ExpressionPatternSyntax(expression: IntegerLiteralExprSyntax(v) ) )
	//	}
	//	func switchCaseLabel(_ v: Int) -> SwitchCaseLabel {
	//		return .init(caseItems: .init([
	//			caseItem(v)
	//		]))
	//	}
	
	func caseItem(_ v: Int) -> CaseItemSyntax {
		.init(pattern: ExpressionPatternSyntax(expression: IntegerLiteralExprSyntax(v) ) )
	}
	func switchCaseLabel(_ v: Int) -> SwitchCaseLabelSyntax {
		return .init(caseItems: .init([
			caseItem(v)
		]))
	}
	
	var breakBlockItem: CodeBlockItemListSyntax {
		.init([
			.init(item: .stmt(.init(stringLiteral: "break")))
		])
	}
	
	var sCases: [SwitchCaseSyntax] {
		let min_count = (arg_count - defaults_count)
		var sc  =  ((min_count )..<arg_count).map { i in
			//SwitchCase(label: .case(switchCaseLabel(i)), statements: [])
			SwitchCaseSyntax(label: .case(switchCaseLabel(i)), statements: caseFunctionCode(maxArgs: i))
			
		}
		sc.append(
			SwitchCaseSyntax(label: .default(.init()), statements: caseFunctionCode(maxArgs: arg_count))
		)
		return sc
	}
	//var switchcase: SwitchStmt {
	var switchcase: SwitchExprSyntax {
		
		//		return .init(
		//			expression: IdentifierExpr(stringLiteral: "__nargs__"),
		//			cases: .init(itemsBuilder: {
		//				for c in sCases {
		//					c
		//				}
		//			})
		//		)
		return .init(
			expression: ExprSyntax(stringLiteral: "__nargs__"),
			cases: .init(itemsBuilder: {
				for c in sCases {
					c
				}
			})
		)
	}
	
	private var functionCode: CodeBlockItemListSyntax {
		.init {
			for extract in extracts {
				extract
			}
			switch function._return_.type {
			case .void, .None:
				if function.throws {
					TryExprSyntax(expression: function.pyCall )
				} else {
					function.pyCall
				}
			default:
				function.pyCallReturn
			}
			function.pyReturnStmt.with(\.leadingTrivia, .newline)
		}
	}
	
	private func caseFunctionCode(maxArgs: Int) -> CodeBlockItemListSyntax {
		.init {
			for extract in extracts {
				extract
			}
			switch function._return_.type {
			case .void, .None:
				if function.throws {
					TryExprSyntax(expression: function.pyCallDefault(maxArgs: maxArgs))
				} else {
					function.pyCallDefault(maxArgs: maxArgs)
				}
			default:
				function.pyCallDefaultReturn(maxArgs: maxArgs)
			}
			
			function.pyReturnStmt.with(\.trailingTrivia, .newline)
		}
	}
	
	private func doCatchCase() -> DoStmtSyntax {
		var do_stmt = DoStmtSyntax {
			CodeBlockItemListSyntax {
				
				_guard.codeBlockItem
					.with(\.trailingTrivia, .newline)
				//.with(\.leadingTrivia, .newline)
				//caseFunctionCode(maxArgs: arg_count - defaults_count)
				switchcase
				
			}
			//.with(\.leadingTrivia, .newline)
		}
		do_stmt.catchClauses = catchClauseList
		return do_stmt
	}
	
	private var doCatch: DoStmtSyntax {
		var do_stmt = DoStmtSyntax {
			CodeBlockItemListSyntax {
				
				_guard.codeBlockItem.with(\.trailingTrivia, .newline)
				functionCode
				
			}
			//.with(\.leadingTrivia, .newline)
		}
		do_stmt.catchClauses = catchClauseList
		return do_stmt
	}
	
	private var calledExpr: MemberAccessExprSyntax {
		//.init(stringLiteral: ".init")
		.init(declName: .init(baseName: .identifier("init")))
	}
	
	private var  pyCallType: TupleExprElementListSyntax {
		
		.init {
			switch function._args_.count {
			case 1: "_oneArg".tuplePExprElement(function.name)
			case 2...: "_withArgs".tuplePExprElement(function.name)
			default: "_noArgs".tuplePExprElement(function.name)
			}
		}
	}
	
	private var signature: ClosureSignatureSyntax {
		var args = [function.wrap_class == nil ? "_" : "__self__"]
		switch function._args_.count {
		case 1:
			if let arg = function._args_.first {
				args.append(arg.name)
			}
		case 2...:
			args.append("__args__")
			args.append("__nargs__")
		default: args.append("_")
		}
		return args.closureSignature
	}
	
	var FunctionCallExprSyntax: FunctionCallExprSyntax {
		
		var f = SwiftSyntax.FunctionCallExprSyntax (
			calledExpression: calledExpr,
			leftParen: .leftParenToken(),
			argumentList: pyCallType,
			rightParen: .rightParenToken()
		)
		
		//        f.trailingClosure = .init(signature: signature.with(\.leadingTrivia, .newline)) {
		//            if function.wrap_class != nil || args.count > 0 {
		//				if defaults_count > 0 {
		//					doCatchCase().with(\.leadingTrivia, .newline)
		//					ReturnStmtSyntax(stringLiteral: "return nil")
		//				} else {
		//					doCatch.with(\.leadingTrivia, .newline)
		//					ReturnStmtSyntax(stringLiteral: "return nil")
		//				}
		//            } else {
		//                functionCode.with(\.leadingTrivia, .newline)
		//            }
		//
		//
		//        }
		f.trailingClosure = .init(signature: signature.with(\.trailingTrivia, .newline)) {
			if function.wrap_class != nil || args.count > 0 {
				if defaults_count > 0 {
					doCatchCase().with(\.trailingTrivia, .newline)
					//ReturnStmtSyntax(stringLiteral: "return nil")
					"return nil"
				} else {
					doCatch.with(\.trailingTrivia, .newline)
					//ReturnStmtSyntax(stringLiteral: "return nil")
					"return nil"
				}
			} else {
				functionCode.with(\.trailingTrivia, .newline)
			}
			
			
		}
		
		return f
	}
	
	var functionDecl: FunctionDeclSyntax {
		
		let f = FunctionDeclSyntax(identifier: .identifier(function.name), signature: function.signature) {
			doCatch
		}
		return f
	}
	
	var globalFunction: FunctionDeclSyntax {
		let f = FunctionDeclSyntax(identifier: .identifier(function.name), signature: function.signature) {
			doCatch
		}
		return f
	}
	
	var string: String {
		functionDecl.formatted().description
	}
	
	
	
}
extension PySwiftClosure: WithCodeBlockSyntax {
	var body: SwiftSyntax.CodeBlockSyntax {
		get {
			.init(statements: statements)
		}
		set(newValue) {
			
		}
	}
	
	//	var body: SwiftSyntax.CodeBlockSyntax {
	//		.init(statements: statements)
	//	}
	
	func withBody(_ newChild: SwiftSyntax.CodeBlockSyntax?) -> Self {
		self
	}
	
	
}

extension PySwiftClosure: WithStatementsSyntax {
	var statements: SwiftSyntax.CodeBlockItemListSyntax {
		get {
			.init {
				//FunctionCallExprSyntax
				if function.wrap_class != nil || args.count > 0 {
					if defaults_count > 0 {
						doCatchCase().with(\.trailingTrivia, .newline)
						//ReturnStmtSyntax(stringLiteral: "return nil")
						"return nil"
					} else {
						doCatch.with(\.trailingTrivia, .newline)
						//ReturnStmtSyntax(stringLiteral: "return nil")
						"return nil"
					}
				} else {
					functionCode.with(\.trailingTrivia, .newline)
				}
			}
		}
		set(newValue) {
			
		}
	}
	
	//    var statements: SwiftSyntax.CodeBlockItemListSyntax {
	//        .init {
	//            FunctionCallExprSyntax
	//        }
	//    }
	
	func withStatements(_ newChild: SwiftSyntax.CodeBlockItemListSyntax?) -> Self {
		self
	}
	
	var _syntaxNode: SwiftSyntax.Syntax {
		fatalError()
	}
	
	static var structure: SwiftSyntax.SyntaxNodeStructure {
		.choices([])
	}
	
	func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
		nil
	}
	
	
}

import SwiftSyntaxBuilder

extension PythonType {
	public var inheritedType: InheritedTypeSyntax {
		//InheritedTypeSyntax(typeName: SimpleTypeIdentifier(stringLiteral: rawValue))
		InheritedTypeSyntax(type: IdentifierTypeSyntax(name: .identifier(rawValue)))
	}
}
