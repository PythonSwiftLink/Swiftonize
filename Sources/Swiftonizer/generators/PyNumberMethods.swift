import Foundation
import SwiftSyntax
import PyWrapper

fileprivate extension String {
	func asLabeledExpr(_ expression: ExprSyntaxProtocol) -> LabeledExprSyntax {
		.init(label: self, expression: expression)
	}
	func asExpr() -> ExprSyntax { .init(stringLiteral: self)}
}


enum PyNumberMethodsEnum: String, CaseIterable {
	case nb_add
	case nb_subtract
	case nb_multiply
	case nb_remainder
	case nb_divmod
	case nb_power
	case nb_negative
	case nb_positive
	case nb_absolute
	case nb_bool
	case nb_invert
	case nb_lshift
	case nb_rshift
	case nb_and
	case nb_xor
	case nb_or
	case nb_int
	case nb_reserved
	case nb_float
	case nb_inplace_add
	case nb_inplace_subtract
	case nb_inplace_multiply
	case nb_inplace_remainder
	case nb_inplace_power
	case nb_inplace_lshift
	case nb_inplace_rshift
	case nb_inplace_and
	case nb_inplace_xor
	case nb_inplace_or
	case nb_floor_divide
	case nb_true_divide
	case nb_inplace_floor_divide
	case nb_inplace_true_divide
	case nb_index
	case nb_matrix_multiply
	case nb_inplace_matrix_multiply
}
extension PyNumberMethodsEnum {
	func getTypeDef() -> PyType_typedefs {
		switch self {
		case .nb_add, .nb_subtract, .nb_multiply, .nb_remainder, .nb_divmod,
				.nb_lshift, .nb_rshift, .nb_and, .nb_xor, .nb_or,
				.nb_inplace_add, .nb_inplace_subtract, .nb_inplace_multiply, .nb_inplace_remainder,
				.nb_inplace_lshift, .nb_inplace_rshift, .nb_inplace_and, .nb_inplace_xor, .nb_inplace_or,
				.nb_floor_divide, .nb_true_divide, .nb_inplace_floor_divide, .nb_inplace_true_divide,
				.nb_matrix_multiply, .nb_inplace_matrix_multiply:
			// Handle binary functions
			return .binaryfunc
		case .nb_power, .nb_inplace_power:
			// Handle ternary function
			return .ternaryfunc
		case .nb_negative, .nb_positive, .nb_absolute, .nb_invert, .nb_int, .nb_float, .nb_index:
			// Handle unary functions
			return .unaryfunc
		case .nb_bool:
			// Handle inquiry function
			return .inquiry
		case .nb_reserved:
			// Handle reserved case
			return .void
		}
	}
	
	
	
}

protocol PyNumberMethodProtocol {
	var label: String { get }
	var cls: PyWrap.Class { get }
	var type: PyType_typedefs { get }
	func closureExpr() -> ClosureExprSyntax
	func _protocol() -> FunctionDeclSyntax?
}

extension PyNumberMethodProtocol {
	func labeledExpr() -> LabeledExprSyntax {
		//label.asLabeledExpr(closureExpr())
		label.asLabeledExpr(unsafeBitCast(pymethod: closureExpr(), from: "PySwift_\(type)", to: "\(type).self"))
	}
}

struct PyNumberMethodsGenerator {
	
	let cls: PyWrap.Class
	
	var methods: [PyNumberMethodProtocol] {
		var out: [PyNumberMethodProtocol] = []
		for _case in PyNumberMethodsEnum.allCases {
			let typeDef = _case.getTypeDef()
			switch typeDef {
			case .binaryfunc:
				out.append(_binaryfunc(label: _case.rawValue, cls: cls))
			case .ternaryfunc:
				out.append(_ternaryfunc(label: _case.rawValue, cls: cls))
			case .unaryfunc:
				out.append(_unaryfunc(label: _case.rawValue, cls: cls))
			case .inquiry:
				out.append(_inquiry(label: _case.rawValue, cls: cls))
			case .void:
				out.append(_void(label: _case.rawValue, cls: cls))
			default: continue
			}
		}
		return out
	}
	
	var variDecl: VariableDeclSyntax {
		let call = FunctionCallExprSyntax(name: ".init") {
			let size = methods.count - 1
			for (i, method) in methods.enumerated() {
				switch i {
				case 0: method.labeledExpr().newLineTab.with(\.leadingTrivia, .newline)
				case size:
					method.labeledExpr()
					
				default: 
					
					if method.label != "nb_reserved" {
						method.labeledExpr().newLineTab
					} else {
						method.label.asLabeledExpr(NilLiteralExprSyntax())
					}
				}
			}
			
		}.with(\.rightParen, .rightParenToken(leadingTrivia: .newline))
		return .init(
			leadingTrivia: .lineComment("// #### PyNumberMethods ####").appending(.newlines(2) as Trivia),
			modifiers: [.fileprivate, .static], .var,
			name: .init(stringLiteral: "tp_as_number"),
			type: .init(type: TypeSyntax(stringLiteral: "PyNumberMethods")),
			initializer: .init(value: call)
		).with(\.trailingTrivia, .newlines(2))
		
	}
	
}



fileprivate func unPackSelf(_ cls: PyWrap.Class) -> String {
	"Unmanaged<\(cls.name)>.fromOpaque(s.pointee.swift_ptr).takeUnretainedValue()"
}
extension PyNumberMethodsGenerator {
	struct _binaryfunc: PyNumberMethodProtocol {
		let label: String
		let cls: PyWrap.Class
		let type: PyType_typedefs = .binaryfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__\(raw: label)__(o)
				}
				"""
				"return nil"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax? {
			try! .init("""
			func __\(raw: label)__(_ other: PyPointer?) -> PyPointer?
			""")
		}
	}
	
	struct _ternaryfunc: PyNumberMethodProtocol {
		let label: String
		let cls: PyWrap.Class
		let type: PyType_typedefs = .ternaryfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
				 return \(raw: unPackSelf(cls))
				  .__\(raw: label)__(o, kw)
				}
				"""
				"return nil"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax? {
			try! .init("""
			func __\(raw: label)__(_ other: PyPointer?,_ kw: PyPointer?) -> PyPointer?
			""")
		}
	}
	
	struct _unaryfunc: PyNumberMethodProtocol {
		let label: String
		let cls: PyWrap.Class
		let type: PyType_typedefs = .unaryfunc
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__\(raw: label)__()
				}
				"""
				"return nil"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax? {
			try! .init("""
			func __\(raw: label)__() -> PyPointer?
			""")
		}
	}
	
	// inquiry
	struct _inquiry: PyNumberMethodProtocol {
		let label: String
		let cls: PyWrap.Class
		let type: PyType_typedefs = .inquiry
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					return \(raw: unPackSelf(cls))
						.__\(raw: label)__()
				}
				"""
				"return 0"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax? {
			try! .init("""
			func __\(raw: label)__() -> Int32
			""")
		}
	}
	
	// void
	struct _void: PyNumberMethodProtocol {
		let label: String
		let cls: PyWrap.Class
		let type: PyType_typedefs = .void
		
		func closureExpr() -> ClosureExprSyntax {
			var closure = type.closureExpr
			closure.statements = .init {
				"""
				if let s = s {
					\(raw: unPackSelf(cls))
						.__\(raw: label)__()
				}
				"""
				//"return 0"
			}
			
			return closure
		}
		
		func _protocol() -> FunctionDeclSyntax? {
			nil
		}
	}
}
