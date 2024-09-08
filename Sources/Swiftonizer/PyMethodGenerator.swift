//
//  File.swift
//  
//
//  Created by CodeBuilder on 15/02/2024.
//

import Foundation
import PyWrapper
import SwiftSyntax
import SwiftSyntaxBuilder




public struct PyMethodGenerator {
	
	var cls: PyWrap.Class?
	
	var function: PyWrap.Function
	
	var args: [ArgSyntax]
	
	var default_names: [String]
	
	var maxArgs: Int { args.count - default_names.count }
	
	init(cls: PyWrap.Class? = nil, function: PyWrap.Function) {
		self.cls = cls
		self.function = function
		args = function.args.map({$0 as! ArgSyntax})
		default_names = function.defaults_name
		
	}
	
}




extension PyMethodGenerator {
	var f: PyWrap.Function { function }
	
	var meth_or_func: PyWrap.Function.FunctionFlag  { cls != nil ? .method : .function }
	
//	var closure: ClosureExprSyntax { .init(
//		signature: f.getPyMethodDefSignature(flag: meth_or_func, keywords: false),
//		statements: PySwiftClosure(function: f).statements)
//	}
	
	var functionBlock: CodeBlockItemListSyntax { .init {
		switch f.returns?.py_type {
		case .void, .None, .none:
			if f.throws {
				//TryExprSyntax(expression: function.pyCallDefault(maxArgs: maxArgs))
				TryExprSyntax(expression: pyCallDefault(maxArgs: maxArgs))
			} else {
				pyCallDefault(maxArgs: maxArgs)
			}
		default:
			pyCallDefaultReturn(maxArgs: maxArgs)
		}
	}}
	
	var callBlock: ClosureExprSyntax { .init(
		signature: f.getPyMethodDefSignature(flag: meth_or_func, keywords: false)) {
			PyMethodClosure(function: function, functionCall: functionBlock).output
//			var fcall: CodeBlockItemListSyntax = .init {
//				switch f.returns?.py_type {
//				case .void, .None, .none:
//					if f.throws {
//						//TryExprSyntax(expression: function.pyCallDefault(maxArgs: maxArgs))
//						TryExprSyntax(expression: pyCallDefault(maxArgs: maxArgs))
//					} else {
//						pyCallDefault(maxArgs: maxArgs)
//					}
//				default:
//					pyCallDefaultReturn(maxArgs: maxArgs)
//				}
//			}
//			fcall
		}
	}
	
	var functionCall: FunctionCallExprSyntax {
		Self.pyMethodDef(
			name: f.name,
			doc: "yo",
			flag: f.getFlag(flag: meth_or_func, keywords: false),
			ftype: f.getMethodType(),
			pymethod: callBlock
		)
	}
	
	var asArrayElement: ArrayElementSyntax {
		.init(expression: functionCall)
	}
	
	var call_target: String { f.call_target ?? f.name }
	var call_targetToken: TokenSyntax { .identifier(call_target) }
	func callTargetResult() -> PatternSyntax { .init(stringLiteral: "\(call_target)_result")}
	var `throws`: Bool { f.throws }
	
	
//	private var functionCode: CodeBlockItemListSyntax {
//		.init {
//			for extract in extracts {
//				extract
//			}
//			switch function.returns?.py_type {
//			case .void, .None:
//				if function.throws {
//					//TryExprSyntax(expression: function.pyCall )
//					//TryExprSyntax(expression: .p)
//				} else {
//					//function.pyCall
//					PyMethodGenerator().pyCall
//				}
//			default:
//				function.pyCallReturn
//				
//			}
//			function.pyReturnStmt.with(\.leadingTrivia, .newline)
//		}
//	}
}

extension ExprSyntaxProtocol where Self == FunctionCallExprSyntax {
	fileprivate static func unsafeBitCast(pymethod: ClosureExprSyntax, ftype: String) -> Self {
		FCallExpr.unsafeBitCast(pymethod: pymethod, from: ftype)
	}
}

extension PyMethodGenerator {
	
	
	
	static func pyMethodDef(name: String, doc: String, flag: String, ftype: String, pymethod: ClosureExprSyntax) -> FunctionCallExprSyntax {
		
		return .init(callee: ExprSyntax(stringLiteral: "PyMethodDef")) {
			LabeledExprSyntax(
				label: "ml_name",
				expression: FCallExpr.cString(name)
			).with(\.trailingComma, .commaToken(trailingTrivia: .newline)).with(\.leadingTrivia, .newline)
			LabeledExprSyntax(
				label: "ml_meth",
				expression: .unsafeBitCast(pymethod: pymethod, ftype: ftype)
			).with(\.trailingComma, .commaToken(trailingTrivia: .newline))
			//			LabeledExprSyntax(
			//				label: "ml_flags",
			//				expression: DeclReferenceExprSyntax.METH_O
			//			).with(\.trailingComma, .commaToken(trailingTrivia: .newline))
			LabeledExprSyntax(
				label: "ml_flags",
				expression: flag.expr
			).with(\.trailingComma, .commaToken(trailingTrivia: .newline))
			LabeledExprSyntax(
				label: "ml_doc",
				expression: FCallExpr.cString(multi: doc)
			)
		}
		.with(\.leftParen, .leftParenToken())
		.with(\.rightParen, .rightParenToken(leadingTrivia: .newline))
	}
	
	
	var pyCall: FunctionCallExprSyntax {
		if let wrap_class = self.cls {
			let src_member = MemberAccessExprSyntax(
				base: TryExprSyntax.unPackPySwiftObject(with: "__self__", as: wrap_class.name),
				dot: .periodToken(),
				name: call_targetToken
			)
			let call = FunctionCallExprSyntax.pyCall(
				src_member,
				args: args,
				cls: wrap_class
			)
			return call.with(\.rightParen, args.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
		}
		let call = FunctionCallExprSyntax.pyCall(
			call_target,
			args: args.compactMap({$0 as! ArgSyntax})
		)
		return call.with(\.rightParen, args.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
	}
	
	func pyCallDefault(maxArgs: Int) -> FunctionCallExprSyntax {
		let args = Array(args[0..<maxArgs])
		if let wrap_class = self.cls {
			let src_member = MemberAccessExprSyntax(
				base: TryExprSyntax.unPackPySwiftObject(with: "__self__", as: wrap_class.name),
				dot: .periodToken(),
				name: .identifier(call_target)
			)
			let call = FunctionCallExprSyntax.pyCall(
				src_member,
				args: args.compactMap({$0 as? ArgSyntax}),
				cls: wrap_class
			)
			return call.with(\.rightParen, args.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
		}
		let call = FunctionCallExprSyntax.pyCall(
			call_target,
			args: args.compactMap({$0 as! ArgSyntax})
		)
		return call.with(\.rightParen, args.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
	}
	
	
	var returnPattern: PatternBindingSyntax {
		let pattern = PatternSyntax(stringLiteral: "\(call_target)_result")
		return .init(pattern: pattern, initializer: nil)
	}
	
	var pyCallReturn: VariableDeclSyntax {
		let call: ExprSyntaxProtocol = self.throws ? TryExprSyntax(expression: pyCall) : pyCall
		let _var = VariableDeclSyntax(
			.let,
			name: callTargetResult(),
			initializer: .init(equal: .equalToken(), value: call)
		)
		
		return _var.with(\.trailingTrivia, .newline)
	}
	
	func pyCallDefaultReturn(maxArgs: Int) -> VariableDeclSyntax {
		let _var: VariableDeclSyntax
		if self.throws {
			
			_var = .init(
				.let,
				name: callTargetResult(),
				initializer: .init(equal: .equalToken(), value: pyCallDefault(maxArgs: maxArgs))
			)
		} else {
			_var = .init(
				.let,
				name: callTargetResult(),
				initializer: .init(value: pyCallDefault(maxArgs: maxArgs))
			)
		}
		return _var.with(\.trailingTrivia, .newline)
	}
}
