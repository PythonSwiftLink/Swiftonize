//
//  WrapModule+Export.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 13/03/2022.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import WrapContainers
import SwiftParser

extension WrapModule {
    
    
//    
//    public var pySwiftCode: String {
//        
//        """
//        //
//        // \(filename).swift
//        //
//        
//        import Foundation
//        \(if: swiftui_mode, """
//        import PySwiftCore
//        //import PythonLib
//        """)
//        
//        \(swift_import_list.joined(separator: newLine))
//        
//        \(classes.map(\.swift_string).joined(separator: newLine))
//
//        \(if: false, generateSwiftPythonObjectCallbackWrap)
//        
//        \(generatePyModule)
//        """
//    }
    
    
//    public var code: CodeBlockItemListSyntax {
//        
//        return .init {
//            .init {
//                "Foundation"._import
//                if swiftui_mode {
//                    "PythonSwiftCore".import
//                    //"PythonLib"._import
//					"PySwiftObject".import
//					//"PythonTypeAlias".import
//                }
//                for imp in swift_import_list {
//                    imp._import
//                }
//                
//                
//                for cls in classes {
//                    cls.code
//                }
//                if expose_module_functions {
//                    exposedPyMethodDefHandler
//                }
//                createModuleDefHandler
//					.with(\.leadingTrivia, .newlines(2))
//					//.with(\.leadingTrivia, .newlines(2))
//                createPyInit.with(\.leadingTrivia, .newlines(2))
//            }
//        }
//    }
//    
	public var extensionFile: SwiftSyntax.SourceFileSyntax {
		.init(statements: .init(itemsBuilder: {
			
			"Foundation"._import
			"PythonSwiftCore".import
			"PySwiftObject".import
			if swiftui_mode {
				
				//"PythonLib"._import
				//"PySwiftObject".import
				//"PythonTypeAlias".import
			}
			for imp in swift_import_list {
				imp._import
			}
			
			
			for cls in classes {
				cls.extension
			}
//			if expose_module_functions {
//				exposedPyMethodDefHandler
//			}
//			createModuleDefHandler.with(\.leadingTrivia, .newlines(2))
//			createPyInitExt.with(\.leadingTrivia, .newlines(2))
			
		}), eofToken: .endOfFileToken())
	}
    
}

extension WrapModule {
    
    public var methods: ExprSyntax {
        if functions.isEmpty { return .init(NilLiteralExprSyntax()) }
		fatalError()
        //return .init(createPyMethodDefHandler(functions: functions))
    }
    
    fileprivate var exposedPyMethodDefHandler: VariableDeclSyntax {
        fatalError()
        //let funcs = createPyMethodDefHandler(functions: functions)
        
//        return VariableDeclSyntax(
//			modifiers: .init(arrayLiteral: .init(name: .keyword(.public), trailingTrivia: .space)),
//            .let,
//            name: .init(stringLiteral: "\(filename)_module_functions"),
//            //initializer: .init(value: funcs.withRightParen(.rightParen.with(\.leadingTrivia, .newline)))
//			initializer: .init(value: funcs.with(\.rightParen, .rightParenToken(leadingTrivia: .newline)))
//        )
    }
    
    fileprivate var createModuleDefHandler: VariableDeclSyntax {
        let _func: FunctionCallExprSyntax
        if expose_module_functions {
			_func = .init(callee: ExprSyntax(stringLiteral: "PyModuleDefHandler")) {
				LabeledExprSyntax(label: "name", expression: ExprSyntax(stringLiteral: "\"\(filename)\""))
					.with(\.leadingTrivia, .newline)
				LabeledExprSyntax(
					label: "methods",
					expression: ExprSyntax(stringLiteral: "\(filename)_module_functions")
				).with(\.leadingTrivia, .newline)
			}
			
//            _func = FunctionCallExprSyntax(
//                callee: IdentifierExprSyntax(stringLiteral: "PyModuleDefHandler")) {
//                    TupleExprElementSyntax(label: "name", expression: .init(StringLiteralExprSyntax(stringLiteral: "\"\(filename)\"")))
//                        .with(\.leadingTrivia, .newline)
//                    TupleExprElementSyntax(label: "methods", expression: ExprSyntax(stringLiteral: "\(filename)_module_functions"))
//                        .with(\.leadingTrivia, .newline)
//                    
//                }
            
        } else {
			_func = .init(callee: ExprSyntax(stringLiteral: "PyModuleDefHandler")) {
				LabeledExprSyntax(label: "name", expression: ExprSyntax(stringLiteral: "\"\(filename)\""))
					.with(\.leadingTrivia, .newline)
				LabeledExprSyntax(
					label: "methods",
					expression: methods
				).with(\.leadingTrivia, .newline)
			}
//             _func = FunctionCallExprSyntax(
//                callee: IdentifierExprSyntax(stringLiteral: "PyModuleDefHandler")) {
//                    TupleExprElementSyntax(label: "name", expression: .init(StringLiteralExprSyntax(stringLiteral: "\"\(filename)\"")))
//                        .with(\.leadingTrivia, .newline)
//                    TupleExprElementSyntax(label: "methods", expression: methods)
//                        .with(\.leadingTrivia, .newline)
//                    
//                }
        }
        return VariableDeclSyntax(
			modifiers: .init(arrayLiteral: .init(name: .keyword(.fileprivate), trailingTrivia: .space)),
            .let,
            name: .init(stringLiteral: "\(filename)_module"),
            //initializer: .init(value: _func.withRightParen(.rightParen.with(\.leadingTrivia, .newline)))
			initializer: .init(value: _func.with(\.rightParen, .rightParenToken(leadingTrivia: .newline)))
        )
    }
    
    fileprivate func PyModule_AddType(cls: WrapClass) -> FunctionCallExprSyntax {
        
        
        return .init(callee: ExprSyntax(stringLiteral: "PyModule_AddType")) {
            .init {
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "m"))
				//LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\(cls.title)PyType.pytype"))
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\(cls.title).pyType"))
            }
        }
    }
	
	fileprivate func PyModule_AddType(ext cls: WrapClass) -> FunctionCallExprSyntax {
		
		
		return .init(callee: ExprSyntax(stringLiteral: "PyModule_AddType")) {
			.init {
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "m"))
//				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\(cls.title)PyType.pytype"))
				LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\(cls.title).pyType"))
			}
		}
	}
    
    fileprivate var createPyInit: FunctionDeclSyntax {
        
        
        let sig = FunctionSignatureSyntax(
            input: .init(parameterList: .init([])),
            //output: .init(returnType: OptionalTypeSyntax(stringLiteral: "PyPointer?"))
			output: .init(type: OptionalTypeSyntax(wrappedType: TypeSyntax(stringLiteral: "PyPointer")))
        )
		let f_expr = FunctionCallExprSyntax(name: "PyModule_Create2") {
			LabeledExprSyntax("\(filename)_module.module")
			LabeledExprSyntax(expression: IntegerLiteralExprSyntax(integerLiteral: 3))
		}
//        let f_expr = FunctionCallExprSyntax(
//            callee: IdentifierExprSyntax(stringLiteral: "PyModule_Create2")) {
//                TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: "\(filename)_module.module"))
//                TupleExprElementSyntax(expression: IntegerLiteralExprSyntax(integerLiteral: 3))
//            }
        
        let initializer = InitializerClauseSyntax(value: f_expr)
        
        return .init(
			modifiers: [.init(name: .keyword(.public))],
            identifier: .identifier("PyInit_\(filename)"),
            signature: sig) {
                //let pattern = IdentifierPatternSyntax(stringLiteral: "m")
				let pattern = PatternSyntax(stringLiteral: "m")
                let con = ConditionElementListSyntax {
					OptionalBindingConditionSyntax(bindingSpecifier: .keyword(.let), pattern: pattern, initializer: initializer)
                    //OptionalBindingConditionSyntax(letOrVarKeyword: .let, pattern: pattern, initializer: initializer)
                }
				let ifstmt = IfExprSyntax(conditions: con) {
					for cls in classes {
						PyModule_AddType(cls: cls)
					}
					"return m"
				}
//                let ifstmt = IfStmtSyntax(conditions: con) {
//                    for cls in classes {
//                        PyModule_AddType(cls: cls)
//                    }
//                    ReturnStmtSyntax(stringLiteral: "return m")
//                }
                //ReturnStmtSyntax(stringLiteral: "return nil")
				"return nil"
            }
    }
	
	fileprivate var createPyInitExt: FunctionDeclSyntax {
		
		
		let sig = FunctionSignatureSyntax(
			input: .init(parameterList: .init([])),
			output: .init(returnType: OptionalTypeSyntax(wrappedType: TypeSyntax(stringLiteral: "PyPointer")))
		)
		let f_expr = FunctionCallExprSyntax(name: "PyModule_Create2") {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "\(filename)_module.module"))
			LabeledExprSyntax(expression: IntegerLiteralExprSyntax(integerLiteral: 3))
		}
//		let f_expr = FunctionCallExprSyntax(
//			callee: IdentifierExprSyntax(stringLiteral: "PyModule_Create2")) {
//				TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: "\(filename)_module.module"))
//				TupleExprElementSyntax(expression: IntegerLiteralExprSyntax(integerLiteral: 3))
//			}
//		
		let initializer = InitializerClauseSyntax(value: f_expr)
		
		return .init(
			modifiers: [.init(name: .keyword(.public))],
			identifier: .identifier("PyInit_\(filename)"),
			signature: sig) {
				//let pattern = IdentifierPatternSyntax(stringLiteral: "m")
				let pattern = PatternSyntax(stringLiteral: "m")
				let con = ConditionElementListSyntax {
					OptionalBindingConditionSyntax(bindingSpecifier: .keyword(.let), pattern: pattern, initializer: initializer)
					//OptionalBindingConditionSyntax(letOrVarKeyword: .let, pattern: pattern, initializer: initializer)
				}
				IfExprSyntax(conditions: con) {
					for cls in classes {
						PyModule_AddType(ext: cls)
					}
					"return m"
				}
//				let ifstmt = IfStmtSyntax(conditions: con) {
//					for cls in classes {
//						PyModule_AddType(ext: cls)
//					}
//					ReturnStmtSyntax(stringLiteral: "return m")
//				}
//				ifstmt
				"return nil"
				//ReturnStmtSyntax(stringLiteral: "return nil")
			}
	}
}



