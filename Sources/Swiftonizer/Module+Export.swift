

import Foundation
import PyWrapper
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser


extension PyWrap.Module {
	public func file() throws -> SourceFileSyntax {
		.init(statements: try .init {
			"Foundation".import
			"PySwiftCore".import
			"PySwiftObject".import
			"PythonCore".import
			"PyUnpack".import
			"PySerializing".import
            "PyDeserializing".import
			"PyCallable".import
			"PyDictionary".import
			"PyTuples".import
			for imp in imports {
				imp.import
			}
			for cls in classes {
				try cls.codeBlock()
			}
			PyMethods(methods: functions, is_public: true, custom_title: "\(filename)PyMethods").output
			createPyModuleDef
			createPyInitExt
			importModuleExt
		})
		
		
	}
}



extension PyWrap.Module {
	
	fileprivate func PyModule_AddType(ext cls: PyWrap.Class) -> FunctionCallExprSyntax {
		
		
		return .init(callee: ExprSyntax(stringLiteral: "PyModule_AddType")) {
			.init {
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "m"))
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\(cls.name).PyType"))
			}
		}
	}
	
	fileprivate func PyModule_AddType(target: String) -> FunctionCallExprSyntax {
		
		
		return .init(callee: ExprSyntax(stringLiteral: "PyModule_AddType")) {
			.init {
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "m"))
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\(target)"))
			}
		}
	}
	
	fileprivate var createPyModuleDef: VariableDeclSyntax {
		.init(.var, name: "\(raw: self.filename)_module", type: .init(type:TypeSyntax(stringLiteral: "PyModuleDef")), initializer: .init(value: ExprSyntax(stringLiteral: """
		.init(
			m_base: _PyModuleDef_HEAD_INIT,
			m_name: cString("\(filename)"),
			m_doc: nil,
			m_size: -1,
			m_methods: .init(&\(filename)PyMethods),
			m_slots: nil,
			m_traverse: nil,
			m_clear: nil,
			m_free: nil
		)
		""")))
	}
	
	fileprivate var createPyInitExt: FunctionDeclSyntax {
		
		
        let sig = FunctionSignatureSyntax(
            parameterClause: .init(parameters: .init([])),
            returnClause: .init(type: OptionalTypeSyntax(wrappedType: TypeSyntax(stringLiteral: "PyPointer")))
		)
		let f_expr = FunctionCallExprSyntax(name: "PyModule_Create2") {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: ".init(&\(filename)_module)"))
			LabeledExprSyntax(expression: IntegerLiteralExprSyntax(integerLiteral: 3))
		}
		let initializer = InitializerClauseSyntax(value: f_expr)
        //return .init(modifiers: <#T##DeclModifierListSyntax#>, name: <#T##TokenSyntax#>, signature: <#T##FunctionSignatureSyntax#>)
		return .init(
			modifiers: [.init(name: .keyword(.public))],
			name: .identifier("PyInit_\(filename)"),
			signature: sig) {
				let pattern = PatternSyntax(stringLiteral: "m")
				let con = ConditionElementListSyntax {
					OptionalBindingConditionSyntax(bindingSpecifier: .keyword(.let), pattern: pattern, initializer: initializer)
				}
				IfExprSyntax(conditions: con) {
					for cls in classes.filter({!$0.options.generic_mode}) {
						PyModule_AddType(ext: cls)
					}
					for cls in classes.filter(\.options.generic_mode) {
						PyModule_AddType(target: "\(cls.name)_PyType")
						for typevar in cls.options.generic_typevar?.types ?? [] {
							PyModule_AddType(target: "\(cls.name)<\(typevar)>.PyType")
						}
					}
					"return m"
				}

				"return nil"
			}
	}
	
	var importModuleExt: ExtensionDeclSyntax {
		.init(modifiers: [.public], extendedType: TypeSyntax(stringLiteral: "PySwiftModuleImport"), memberBlock: .init{
			"static let \(raw: filename) = PySwiftModuleImport(name: \(literal: filename), module: PyInit_\(raw: filename))"
		})
	}
}
