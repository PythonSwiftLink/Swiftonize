import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

import WrapContainers
import PyAst
import PySwiftCore

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

struct PyTypeObjectGenerator {
	
	var cls: WrapClass
	
	init(cls: WrapClass) {
		self.cls = cls
	}
	
	func args() -> LabeledExprListSyntax {
		//guard let cls = cls else { fatalError() }
		
		let cases = PyTypeObjectLabels.allCases
		return .init {
			for label in cases {
				switch label {
				case .ob_base:
					LabeledExprSyntax(label: label.rawValue, expression: ExprSyntax(stringLiteral: ".init()"))
						.newLineTab
				case .tp_name:
					label.asLabeledExpr(FunctionCallExprSyntax.cString(cls.title))
				case .tp_basicsize:
					//label.rawValue.asLabeledExpr(ExprSyntax(stringLiteral: "PySwiftObject_size"))
					label.asLabeledExpr("MemoryLayout<PySwiftObject>.stride".expr)
				case .tp_itemsize:
					label.asLabeledExpr(0.makeLiteralSyntax())
				case .tp_dealloc:
					label.asLabeledExpr("unsafeBitCast(\(cls.title).\(label), to: destructor.self)".asExpr())
				case .tp_vectorcall_offset:
					label.asLabeledExpr(0.makeLiteralSyntax())
				case .tp_getattr:
					label.nilLabel.newLine
				case .tp_setattr:
					label.nilLabel.newLine
				case .tp_as_async:
					label.asLabeledExpr(
						cls.bases.contains(.AsyncGenerator) ? ".init(&\(cls.title).\(label))".asExpr() : nil
					)
				case .tp_repr:
					label.asLabeledExpr(
						cls.bases.contains(.Str) ? "unsafeBitCast(\(cls.title).\(label), to: reprfunc.self)".asExpr() : nil
					)
				case .tp_as_number:
					label.asLabeledExpr(
						cls.bases.contains(.Number) ? ".init(&\(cls.title).\(label))".asExpr() : nil
					)
				case .tp_as_sequence:
					label.asLabeledExpr(
						cls.bases.contains(.Sequence) ? ".init(&\(cls.title).\(label))".asExpr() : nil
					)
				case .tp_as_mapping:
					label.asLabeledExpr(
						cls.bases.contains(.Mapping) ? ".init(&\(cls.title).\(label))".asExpr() : nil
					)
				case .tp_hash:
					label.asLabeledExpr(
						cls.bases.contains(.Hashable) ? "unsafeBitCast(\(cls.title).\(label), to: hashfunc.self)".asExpr() : nil
					)
				case .tp_call:
					label.asLabeledExpr(
						cls.bases.contains(.Callable) ? ".init(&\(cls.title).\(label))".asExpr() : nil
					)
				case .tp_str:
					label.asLabeledExpr(
						cls.bases.contains(.Str) ? "unsafeBitCast(\(cls.title).\(label), to: reprfunc.self)".asExpr() : nil
					)
				case .tp_getattro:
					label.asLabeledExpr("PyObject_GenericGetAttr".asExpr())
				case .tp_setattro:
					label.asLabeledExpr("PyObject_GenericSetAttr".asExpr())
				case .tp_as_buffer:
					label.nilLabel.newLine
				case .tp_flags:
					label.asLabeledExpr("SwiftPyType.TpFlag.DEFAULT.rawValue".asExpr())
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
						cls.send_functions.isEmpty 
						? nil : ".init(&\(cls.title).PyMethods)".asExpr()
					)
				case .tp_members:
					label.nilLabel.newLine
				case .tp_getset:
					label.asLabeledExpr(
						cls.properties.isEmpty
						? nil : ".init(&\(cls.title).asPyGetSet)".asExpr()
					)
				case .tp_base:
					label.nilLabel.newLine.newLine
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
					label.asLabeledExpr("unsafeBitCast(\(cls.title).tp_init, to: initproc.self)".asExpr())
				case .tp_alloc:
					label.asLabeledExpr("PyType_GenericAlloc".asExpr())
				case .tp_new:
					//label.nilLabel.newLine
					label.asLabeledExpr("\(cls.title).tp_new".asExpr())
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
			leftParen: .leftParenToken(trailingTrivia: .newline.appending(.tab)),
			arguments: args(),
			rightParen: .rightParenToken(leadingTrivia: .newline)
		)
	}
	
	
}
