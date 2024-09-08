

import Foundation
import SwiftSyntax
import WrapContainers

fileprivate extension String {
	func asLabeledExpr(_ expression: ExprSyntaxProtocol) -> LabeledExprSyntax {
		.init(label: self, expression: expression)
	}
	func asExpr() -> ExprSyntax { .init(stringLiteral: self)}
}



struct PyAsyncMethodsGenerator {
	
	let cls: WrapClass
	
	
	var variDecl: VariableDeclSyntax {
		let call = FunctionCallExprSyntax(name: ".init") {
			_am_await(cls: cls).labeledExpr().with(\.leadingTrivia, .newline).newLineTab
			_am_aiter(cls: cls).labeledExpr().newLineTab
			_am_anext(cls: cls).labeledExpr().newLineTab
			_am_send(cls: cls).labeledExpr()
		}.with(\.rightParen, .rightParenToken(leadingTrivia: .newline))
		
		return .init(
			leadingTrivia: .lineComment("// #### PyAsyncMethods ####").appending(.newlines(2) as Trivia),
			modifiers: [.fileprivate, .static], .var,
			name: .init(stringLiteral: "tp_as_async"),
			type: .init(type: TypeSyntax(stringLiteral: "PyAsyncMethods")),
			initializer: .init(value: call)
		).with(\.trailingTrivia, .newlines(2))
		
	}
	
	var methods: [any PyAsyncMethodProtocol] {
		return [
			_am_await(cls: cls),
			_am_aiter(cls: cls),
			_am_anext(cls: cls),
			_am_send(cls: cls)
		]
	}
	
	init(cls: WrapClass) {
		self.cls = cls
	}
	
}
func unsafeBitCast(pymethod: ClosureExprSyntax, from type: String, to: String) -> FunctionCallExprSyntax {
	.init(
		calledExpression: DeclReferenceExprSyntax(baseName: .identifier("unsafeBitCast")),
		leftParen: .leftParenToken(),
		arguments: .init {
			LabeledExprSyntax(expression: AsExprSyntax(
				expression: pymethod.with(\.leftBrace, .leftBraceToken(leadingTrivia: .newline)),
				type: TypeSyntax(stringLiteral: type)
			))
			LabeledExprSyntax(label: "to", expression: ExprSyntax(stringLiteral: to))
		},
		rightParen: .rightParenToken(leadingTrivia: .newline)
	)
}
protocol PyAsyncMethodProtocol {
	var label: String { get }
	var cls: WrapClass { get }
	var type: PyType_typedefs { get }
	func closureExpr() -> ClosureExprSyntax
	func _protocol() -> FunctionDeclSyntax
}

extension PyAsyncMethodProtocol {
	func labeledExpr() -> LabeledExprSyntax {
		label.asLabeledExpr(unsafeBitCast(pymethod: closureExpr(), from: "\(swift_type)", to: "\(type).self"))
	}
	var swift_type: String { "PySwift_\(type)" }
}
fileprivate func unPackSelf(_ cls: WrapClass) -> String {
	"Unmanaged<\(cls.title)>.fromOpaque(s.pointee.swift_ptr).takeUnretainedValue()"
}
extension PyAsyncMethodsGenerator {
	
	
	
	struct _am_await: PyAsyncMethodProtocol {
		let label = "am_await"
		let cls: WrapClass
		let type: PyType_typedefs = .unaryfunc
		
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__am_await__()
				}
				"""
				"return nil"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax {
			try! .init("""
			func __am_await__() -> PyPointer?
			""")
		}
	}
	
	struct _am_aiter: PyAsyncMethodProtocol {
		let label = "am_aiter"
		let cls: WrapClass
		let type: PyType_typedefs = .unaryfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__am_aiter__()
				}
				"""
				"return nil"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax {
			try! .init("""
			func __am_aiter__() -> PyPointer?
			""")
		}
	}
	
	struct _am_anext: PyAsyncMethodProtocol {
		let label = "am_anext"
		let cls: WrapClass
		let type: PyType_typedefs = .unaryfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__am_anext__()
				}
				"""
				"return nil"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax {
			try! .init("""
			func __am_anext__() -> PyPointer?
			""")
		}
	}
	
	struct _am_send: PyAsyncMethodProtocol {
		let label = "am_send"
		let cls: WrapClass
		let type: PyType_typedefs = .sendfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__am_send__(x, y).result()
				}
				"""
				"return PYGEN_ERROR"
			}
			
			return closure
		}
		func _protocol() -> FunctionDeclSyntax {
			try! .init("""
			func __am_send__(_ arg: PyPointer?,_ kwargs: UnsafeMutablePointer<PyPointer?>?) -> PySendResultFlag
			""")
		}
	}
	
	
}

