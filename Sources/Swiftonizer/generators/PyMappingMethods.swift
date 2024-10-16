

import Foundation
import SwiftSyntax
import PyWrapper

fileprivate extension String {
	func asLabeledExpr(_ expression: ExprSyntaxProtocol) -> LabeledExprSyntax {
		.init(label: self, expression: expression)
	}
	func asExpr() -> ExprSyntax { .init(stringLiteral: self)}
}



struct PyMappingMethodsGenerator {
	
	let cls: PyWrap.Class
	
	var methods: [any PyMappingMethodProtocol] {
		return [
			_mp_length(cls: cls),
			_mp_subscript(cls: cls),
			_mp_ass_subscript(cls: cls),
		]
	}
	
	var variDecl: VariableDeclSyntax {
		let call = FunctionCallExprSyntax(name: ".init") {
			_mp_length(cls: cls).labeledExpr().with(\.leadingTrivia, .newline).newLineTab
			_mp_subscript(cls: cls).labeledExpr().newLineTab
			_mp_ass_subscript(cls: cls).labeledExpr()
		}.with(\.rightParen, .rightParenToken(leadingTrivia: .newline))
		
		return .init(
			leadingTrivia: .lineComment("// #### PyMappingMethods ####").appending(.newlines(2) as Trivia),
			modifiers: [.fileprivate, .static], .var,
			name: .init(stringLiteral: "tp_as_mapping"),
			type: .init(type: TypeSyntax(stringLiteral: "PyMappingMethods")),
			initializer: .init(value: call)
		).with(\.trailingTrivia, .newlines(2))
		
	}
	
	init(cls: PyWrap.Class) {
		self.cls = cls
	}
	
}

protocol PyMappingMethodProtocol {
	var label: String { get }
	var cls: PyWrap.Class { get }
	var type: PyType_typedefs { get }
	func closureExpr() -> ClosureExprSyntax
	func _protocol() -> FunctionDeclSyntax
}

extension PyMappingMethodProtocol {
	func labeledExpr() -> LabeledExprSyntax {
		label.asLabeledExpr(unsafeBitCast(pymethod: closureExpr(), from: "PySwift_\(type)", to: "\(type).self"))
	}
}
fileprivate func unPackSelf(_ cls: PyWrap.Class) -> String {
	"Unmanaged<\(cls.name)>.fromOpaque(s.pointee.swift_ptr).takeUnretainedValue()"
}
extension PyMappingMethodsGenerator {
	
	
	
	struct _mp_length: PyMappingMethodProtocol {
		let label = "mp_length"
		let cls: PyWrap.Class
		let type: PyType_typedefs = .lenfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__len__()
				}
				"""
				"return 0"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax {
			try! .init("""
			func __len__() -> Int
			""")
		}
	}
	
	struct _mp_subscript: PyMappingMethodProtocol {
		let label = "mp_subscript"
		let cls: PyWrap.Class
		let type: PyType_typedefs = .binaryfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__getitem__(o)
				}
				"""
				"return nil"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax {
			try! .init("""
			func __getitem__(_ key: PyPointer?) -> PyPointer?
			""")
		}
	}
	
	struct _mp_ass_subscript: PyMappingMethodProtocol {
		let label = "mp_ass_subscript"
		let cls: PyWrap.Class
		let type: PyType_typedefs = .objobjargproc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__setitem__(x, y)
				}
				"""
				"return 0"
			}
			
			return closure
		}
		func _protocol() -> FunctionDeclSyntax {
			try! .init("""
			func __setitem__(_ key: PyPointer?,_ item: PyPointer?) -> Int32
			""")
		}
	}
	
	
}

