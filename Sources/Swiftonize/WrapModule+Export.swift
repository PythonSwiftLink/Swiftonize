//
//  WrapModule+Export.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 13/03/2022.
//

import Foundation
import SwiftSyntax
import WrapContainers

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
//        import PythonSwiftCore
//        import PythonLib
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
    
    
    public var code: CodeBlockItemListSyntax {
        
        return .init {
            .init {
                "Foundation"._import
                if swiftui_mode {
                    "PythonSwiftCore"._import
                    "PythonLib"._import
                }
                for imp in swift_import_list {
                    imp._import
                }
                
                
                for cls in classes {
                    cls.code
                }
                if expose_module_functions {
                    exposedPyMethodDefHandler
                }
                createModuleDefHandler.withLeadingTrivia(.newlines(2))
                createPyInit.withLeadingTrivia(.newlines(2))
            }
        }
    }
    
    
}

extension WrapModule {
    
    public var methods: ExprSyntax {
        if functions.isEmpty { return .init(NilLiteralExprSyntax()) }
        return .init(createPyMethodDefHandler(functions: functions))
    }
    
    fileprivate var exposedPyMethodDefHandler: VariableDeclSyntax {
        
        let funcs = createPyMethodDefHandler(functions: functions)
        
        return VariableDeclSyntax(
            modifiers: .init(arrayLiteral: .init(name: .public, trailingTrivia: .space)),
            .let,
            name: .init(stringLiteral: "\(filename)_module_functions"),
            initializer: .init(value: funcs.withRightParen(.rightParen.withLeadingTrivia(.newline)))
            
        )
    }
    
    fileprivate var createModuleDefHandler: VariableDeclSyntax {
        let _func: FunctionCallExprSyntax
        if expose_module_functions {
            _func = FunctionCallExprSyntax(
                callee: IdentifierExprSyntax(stringLiteral: "PyModuleDefHandler")) {
                    TupleExprElementSyntax(label: "name", expression: .init(StringLiteralExprSyntax(stringLiteral: "\"\(filename)\"")))
                        .withLeadingTrivia(.newline)
                    TupleExprElementSyntax(label: "methods", expression: .init(stringLiteral: "\(filename)_module_functions"))
                        .withLeadingTrivia(.newline)
                    
                }
            
        } else {
             _func = FunctionCallExprSyntax(
                callee: IdentifierExprSyntax(stringLiteral: "PyModuleDefHandler")) {
                    TupleExprElementSyntax(label: "name", expression: .init(StringLiteralExprSyntax(stringLiteral: "\"\(filename)\"")))
                        .withLeadingTrivia(.newline)
                    TupleExprElementSyntax(label: "methods", expression: methods)
                        .withLeadingTrivia(.newline)
                    
                }
        }
        return VariableDeclSyntax(
            modifiers: .init(arrayLiteral: .init(name: .fileprivate, trailingTrivia: .space)),
            .let,
            name: .init(stringLiteral: "\(filename)_module"),
            initializer: .init(value: _func.withRightParen(.rightParen.withLeadingTrivia(.newline)))
            
        )
    }
    
    fileprivate func PyModule_AddType(cls: WrapClass) -> FunctionCallExprSyntax {
        
        
        return .init(callee: IdentifierExprSyntax(stringLiteral: "PyModule_AddType")) {
            .init {
                TupleExprElementSyntax(expression: .init(stringLiteral: "m"))
                TupleExprElementSyntax(expression: "\(raw: cls.title)PyType.pytype")
            }
        }
    }
    
    fileprivate var createPyInit: FunctionDeclSyntax {
        
        
        let sig = FunctionSignatureSyntax(
            input: .init(parameterList: .init([])),
            output: .init(returnType: OptionalTypeSyntax(stringLiteral: "PyPointer?"))
        )
        let f_expr = FunctionCallExprSyntax(
            callee: IdentifierExprSyntax(stringLiteral: "PyModule_Create2")) {
                TupleExprElementSyntax(expression: .init(stringLiteral: "\(filename)_module.module"))
                TupleExprElementSyntax(expression: IntegerLiteralExprSyntax(integerLiteral: 3))
            }
        
        let initializer = InitializerClauseSyntax(value: f_expr)
        
        return .init(
            identifier: .identifier("PyInit_\(filename)"),
            signature: sig) {
                let pattern = IdentifierPatternSyntax(stringLiteral: "m")
                let con = ConditionElementListSyntax {
                    OptionalBindingConditionSyntax(letOrVarKeyword: .let, pattern: pattern, initializer: initializer)
                }
                let ifstmt = IfStmtSyntax(conditions: con) {
                    for cls in classes {
                        PyModule_AddType(cls: cls)
                    }
                    ReturnStmtSyntax(stringLiteral: "return m")
                }
                ifstmt
                ReturnStmtSyntax(stringLiteral: "return nil")
            }
    }
}



