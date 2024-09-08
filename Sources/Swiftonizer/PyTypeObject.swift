import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

import PyWrapper
import PyAst
import PySwiftCore

func TPBaseType(t: String) -> ExprSyntax {
	switch t {
	case "str":
		return .init(stringLiteral: ".PyUnicode")
	default: return .init(stringLiteral: "\(t).PyType")
	}
	return .init(nilOrExpression: nil)
}

fileprivate extension String {
	func asLabeledExpr(_ expression: ExprSyntaxProtocol?, newline: Bool = true) -> LabeledExprSyntax {
		
		if newline {
			return .init(label: self, expression: ExprSyntax(nilOrExpression: expression)).newLineTab
		}
		return .init(label: self, expression: ExprSyntax(nilOrExpression: expression))
		
		
	}
	
	var asNilLabel: LabeledExprSyntax { .init(label: self, nilOrExpression: nil)}
	
	func asExpr() -> ExprSyntax { .init(stringLiteral: self)}
}
extension LabeledExprSyntax {
	var newLineTab: Self { self.with(\.trailingComma, .commaToken(trailingTrivia: .newline))}
	var newLine: Self { self.with(\.trailingComma, .commaToken(trailingTrivia: .newline))}
}

extension PyTypeObjectLabels {
	var nilLabel: LabeledExprSyntax { .init(label: rawValue, nilOrExpression: nil)}
	func asLabeledExpr(_ expression: ExprSyntaxProtocol?, newline: Bool = true) -> LabeledExprSyntax {
		
		if newline {
			return .init(label: rawValue, expression: ExprSyntax(nilOrExpression: expression)).newLineTab
		}
		return .init(label: rawValue, expression: ExprSyntax(nilOrExpression: expression))
		
		
	}
}

extension Array where Element == any ExprProtocol {
	func first(name: String) -> (any ExprProtocol)? {
		self.first { expr in
			if let expr = expr as? AST.Name {
				return expr.id == name
			}
			return false
		}
	}
}

struct PyTypeObjectGenerator {
	
	var cls: PyWrap.Class
	
	var cls_name: String
	
	var typevar: String?
	
	init(cls: PyWrap.Class, target: String? = nil, typevar: String? = nil) {
		self.cls = cls
		self.cls_name = target ?? cls.name
		self.typevar = typevar
	}
	
	var tp_base: ExprSyntax {
//		if let name_ast = cls.ast?.bases.first as? AST.Name {
//			return TPBaseType(t: name_ast.id)
//		}
		if cls.options.generic_mode {
			return .init(stringLiteral: "BaseType")
		}
		if let first = cls.base_types.first {
			if let target = first.options.target {
				return .init(stringLiteral: target)
			}
			//return TPBaseType(t: first.name)
			return "\(raw: first.name)"
		}
		return .init(nilOrExpression: nil)
	}
	
	func args() -> LabeledExprListSyntax {
		//guard let cls = cls else { fatalError() }
		let bases = cls.bases()
		let cases = PyTypeObjectLabels.allCases
		
		var use_getsets: Bool {
			if let properties = cls.properties {
				return properties.isEmpty
			}
			return false
		}
		var tp_name: String {
			if cls.options.generic_mode {
				if let typevar = typevar {
					return "\(cls.name)_\(typevar)"
				}
			}
			
			return cls_name
		}
		
		return .init {
			for label in cases {
				switch label {
				case .ob_base:
					LabeledExprSyntax(label: label.rawValue, expression: ExprSyntax(stringLiteral: ".init()"))
						.newLineTab
				case .tp_name:
					label.asLabeledExpr(FunctionCallExprSyntax.cString(tp_name))
				case .tp_basicsize:
					//label.rawValue.asLabeledExpr(ExprSyntax(stringLiteral: "PySwiftObject_size"))
					label.asLabeledExpr("MemoryLayout<PySwiftObject>.stride".expr)
				case .tp_itemsize:
					label.asLabeledExpr(0.makeLiteralSyntax())
				case .tp_dealloc:
					label.asLabeledExpr(cls.options.unretained ? nil : "unsafeBitCast(\(cls_name).\(label), to: destructor.self)".asExpr())
					//label.asLabeledExpr("unsafeBitCast(\(cls_name).\(label), to: destructor.self)".asExpr())
				case .tp_vectorcall_offset:
					label.asLabeledExpr(0.makeLiteralSyntax())
				case .tp_getattr:
					label.nilLabel.newLine
				case .tp_setattr:
					label.nilLabel.newLine
				case .tp_as_async:
					label.asLabeledExpr(
						bases.contains(.AsyncGenerator) ? ".init(&\(cls_name).\(label))".asExpr() : nil
					)
				case .tp_repr:
					label.asLabeledExpr(
						bases.contains(.Str) ? "unsafeBitCast(\(cls_name).\(label), to: reprfunc.self)".asExpr() : nil
					)
				case .tp_as_number:
					label.asLabeledExpr(
						bases.contains(.Number) ? ".init(&\(cls_name).\(label))".asExpr() : nil
					)
				case .tp_as_sequence:
					label.asLabeledExpr(
						bases.contains(.Sequence) ? ".init(&\(cls_name).\(label))".asExpr() : nil
					)
				case .tp_as_mapping:
					label.asLabeledExpr(
						bases.contains(.Mapping) ? ".init(&\(cls_name).\(label))".asExpr() : nil
					)
				case .tp_hash:
					label.asLabeledExpr(
						bases.contains(.Hashable) ? "unsafeBitCast(\(cls_name).\(label), to: hashfunc.self)".asExpr() : nil
					)
				case .tp_call:
					label.asLabeledExpr(
						bases.contains(.Callable) ? ".init(&\(cls_name).\(label))".asExpr() : nil
					)
				case .tp_str:
					label.asLabeledExpr(
						bases.contains(.Str) ? "unsafeBitCast(\(cls_name).\(label), to: reprfunc.self)".asExpr() : nil
					)
				case .tp_getattro:
					if cls.overloads.contains(.__getattr__) {
						label.asLabeledExpr("unsafeBitCast(\(cls_name).getattr, to: getattrofunc.self)".asExpr())
					} else {
						label.asLabeledExpr("PyObject_GenericGetAttr".asExpr())
					}
				case .tp_setattro:
					if cls.overloads.contains(.__setattr__) {
						label.asLabeledExpr("unsafeBitCast(\(cls_name).setattr, to: setattrofunc.self)".asExpr())
					} else {
						label.asLabeledExpr("PyObject_GenericSetAttr".asExpr())
					}
				case .tp_as_buffer:
					label.nilLabel.newLine
				case .tp_flags:
					label.asLabeledExpr("NewPyObjectTypeFlag.DEFAULT".asExpr())
				case .tp_doc:
					label.nilLabel.newLine
				case .tp_traverse:
					label.nilLabel.newLine
				case .tp_clear:
					label.nilLabel.newLine
				case .tp_richcompare:
					label.nilLabel.newLine
				case .tp_weaklistoffset:
					label.asLabeledExpr(0.makeLiteralSyntax())
				case .tp_iter:
					label.nilLabel.newLine
				case .tp_iternext:
					label.nilLabel.newLine
				case .tp_methods:
					label.asLabeledExpr(
						cls.functions != nil
						? ".init(&\(cls_name).PyMethods)".asExpr() : nil
					)
//					label.nilLabel
				case .tp_members:
					label.nilLabel.newLine
				case .tp_getset:
					label.asLabeledExpr(
						cls.properties != nil
						? ".init(&\(cls_name).asPyGetSet)".asExpr() : nil
					)
				case .tp_base:
					//label.nilLabel.newLine.newLine
					label.asLabeledExpr(tp_base)
				case .tp_dict:
					label.nilLabel.newLine
				case .tp_descr_get:
					label.nilLabel.newLine
				case .tp_descr_set:
					label.nilLabel.newLine
				case .tp_dictoffset:
					//label.rawValue.asLabeledExpr("PySwiftObject_dict_offset".asExpr())
					label.asLabeledExpr("MemoryLayout<PySwiftObject>.stride - MemoryLayout<PyObject>.stride".expr)
				case .tp_init:
					label.asLabeledExpr("unsafeBitCast(\(cls_name).tp_init, to: initproc.self)".asExpr())
				case .tp_alloc:
					label.asLabeledExpr("PyType_GenericAlloc".asExpr())
				case .tp_new:
					//label.nilLabel.newLine
					label.asLabeledExpr("\(cls_name).tp_new".asExpr())
				case .tp_free, .tp_is_gc, .tp_bases, .tp_mro, .tp_cache, .tp_subclasses, .tp_weaklist, .tp_del:
					label.nilLabel.newLine
				case .tp_version_tag:
					label.asLabeledExpr(11.makeLiteralSyntax())
				case .tp_finalize:
					label.nilLabel.newLine
				case .tp_vectorcall:
					label.asLabeledExpr(nil, newline: false)
				}
			}
		}
		
	}
	
	func functionCallExpr() -> FunctionCallExprSyntax {
		.init(
			calledExpression: ExprSyntax(stringLiteral: ".init"),
			leftParen: .leftParenToken(),//(trailingTrivia: .newline), //.appending(.tab)
			arguments: args().with(\.leadingTrivia, .newline),
			rightParen: .rightParenToken(leadingTrivia: .newline)
		)
	}
	
	
}
