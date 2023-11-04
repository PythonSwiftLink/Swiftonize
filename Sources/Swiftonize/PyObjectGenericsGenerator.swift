//
//  File.swift
//  
//
//  Created by MusicMaker on 09/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder



fileprivate let LETTERS = ["A","B","C","D","E","F","G","H","I"]

//fileprivate let R_Generic = GenericParameterClause(stringLiteral: "<R: ConvertibleFromPython>")

fileprivate extension GenericParameterClause {
    init(letters: [String], rtype: GenericPyCall.RType) {
        
        self.init(genericParameterList: .init(itemsBuilder: {
            
            for letter in letters {
                GenericParameter(name: letter)
            }
            
            if rtype == .PyEncodable {
                GenericParameter(name: "R")
            }
        }))
    }
}


public class GenericPyCall {
    
    public enum RType: String {
        case PyPointer
        case PyEncodable
        case none
    }
    
    public enum GILMode {
        case none
        case enabled
        case external
    }
    
    var arg_count: Int
    
    var pyPointer: String?
    
    var returnType: RType
    
    //var gil: Bool
    
    var gil_mode: GILMode
    
    public init(arg_count: Int, pyPointer: String?=nil,gil_mode: GILMode = .none, rtn: RType) {
        self.arg_count = arg_count
        self.pyPointer = pyPointer
        self.returnType = rtn
        //self.gil = gil
        self.gil_mode = gil_mode
    }
    
    var parameters: ParameterClause {
        return .init(parameterList: .init {
            if let pyPointer = pyPointer {
                FunctionParameterSyntax(
                    secondName: .identifier(pyPointer),
                    colon: .colon,
                    type: SimpleTypeIdentifier(stringLiteral: "PyPointer")
                )
            }
            for i in 0..<arg_count {
                
                FunctionParameterSyntax(
                    firstName: .identifier("_ "),
                    secondName: .identifier(LETTERS[i].lowercased()),
                    colon: .colon,
                    type: SimpleTypeIdentifier(stringLiteral: LETTERS[i])
                )//.withLeadingTrivia(arg_count > 2 ? .newline + .tab : .zero)
            }
        })//.withRightParen(arg_count > 2 ? .rightParen.withLeadingTrivia(.newline + .tab) : .rightParen)
    }
    
    var returnClause: ReturnClause? {
        switch returnType {
            
        case .PyPointer:
			return .init(returnType: SimpleTypeIdentifier(stringLiteral: "PyPointer" ))
        case .PyEncodable:
            return .init(returnType: SimpleTypeIdentifier(stringLiteral: "R" ))
        case .none:
            return nil
        }
        
    }
    
    var functionSignature: FunctionSignature {
        return .init(
            input: parameters,
            throwsOrRethrowsKeyword: .throws.withLeadingTrivia(.space),
            output: returnClause
        )
    }
    
    public func functionDecl(_ title: String) -> FunctionDeclSyntax {
  
        let variDecl = VariableDecl(letOrVarKeyword: .let, bindings: PatternBindingList {
            let f_expr = FunctionCallExpr(callee: MemberAccessExpr(stringLiteral: "VectorCallArgs.allocate")) {
                .init(label: "capacity", expression: .init(literal: arg_count))
            }
            PatternBinding(pattern: IdentifierPattern(stringLiteral: arg_count > 1 ? "args" : "arg"), initializer: .init(value: f_expr))
        })
        let post_args: CodeBlockItemList = .init {
            if arg_count > 0 {
                if arg_count > 1 {
                    for i in 0..<arg_count {
                        FunctionCallExpr.Py_DecRef("args[\(i)]")
                    }
                    argsDealloc
                } else {
                    FunctionCallExpr._Py_DecRef("arg")
                }
            }
        }
        let generics: GenericParameterClause? = (arg_count > 0 || returnType == .PyEncodable) ? .init(letters: .init(LETTERS[0..<arg_count]), rtype: returnType) : nil
        
        var whereClause: GenericWhereClause? {
            guard arg_count > 0 || returnType == .PyEncodable else { return nil }
            return .init {
                for letter in LETTERS[0..<arg_count] {
                    GenericRequirement(body: .conformanceRequirement(.init(leftTypeIdentifier: SimpleTypeIdentifier(stringLiteral: letter), rightTypeIdentifier: SimpleTypeIdentifier(stringLiteral: "PyEncodable"))))
                        .withLeadingTrivia(.newline + .tab)
                }
                if returnType == .PyEncodable {
                    GenericRequirement(body: .conformanceRequirement(.init(leftTypeIdentifier: SimpleTypeIdentifier(stringLiteral: "R"), rightTypeIdentifier: SimpleTypeIdentifier(stringLiteral: "PyDecodable"))))
                        .withLeadingTrivia(.newline + .tab)
                }
            }//.withLeadingTrivia(.newline + .tab)
        }
        var attributeList: AttributeListSyntax? {
            guard returnType == .PyPointer else { return nil }
            return .init {
                CustomAttributeSyntax(.init(stringLiteral: "_disfavoredOverload"))
            }.withTrailingTrivia(.newline)
        }
        //returnType == .ConvertibleFromPython ? .R : nil
        let public_mod = ModifierList {
            DeclModifier(name: .identifier("public "))
        }
        return .init(
            attributes: attributeList,
            modifiers: public_mod,
            identifier: .identifier(title),
            genericParameterClause: generics,
            signature: functionSignature,
            genericWhereClause: whereClause) {
            let gil = self.gil_mode == .enabled
            if gil {
                if returnType == .PyPointer {
                    SequenceExpr(stringLiteral: "_ = PyGILState_Ensure()")
                    
                } else {
                    VariableDecl(letOrVarKeyword: .let) {
                        PatternBinding(pattern: IdentifierPattern(stringLiteral: "gil"), initializer: .init(value: FunctionCallExpr(callee: IdentifierExpr(stringLiteral: "PyGILState_Ensure"))))
                    }
                }
            }
            if arg_count > 0 {
                if arg_count > 1 {
                    variDecl
                    for i in 0..<arg_count {
                        SequenceExpr.setArg(i, LETTERS[i])
                    }
                } else {
                    VariableDecl.setArg("a")
                }
            }
      
            
            GuardStmtSyntax.pyResult(arg_count, self: pyPointer ?? "self") {
                pyErr_Print
                post_args
                
                ThrowStmt(stringLiteral: "throw PythonError.call")
            }
            post_args
            
            
            switch returnType {
            case .PyEncodable:
                handleReturn
                FunctionCallExpr._Py_DecRef("result")
                if gil {
                    FunctionCallExpr(stringLiteral: "PyGILState_Release(gil)")
                }
                ReturnStmt(stringLiteral: "return rtn")
            case .PyPointer:
                ReturnStmt(stringLiteral: "return result")
            case .none:
                if gil {
                    FunctionCallExpr(stringLiteral: "PyGILState_Release(gil)")
                }
                FunctionCallExpr._Py_DecRef("result")
            }
            
        }
    }
    
    var pyErr_Print: FunctionCallExpr {
        .init(callee: IdentifierExpr(stringLiteral: "PyErr_Print"))
    }
    
    
    var argsDealloc: FunctionCallExpr {
        .init(stringLiteral: "args.deallocate()")
    }
    
    var handleReturn: VariableDecl {
        let tryExpr = TryExpr(expression: FunctionCallExpr(callee: IdentifierExpr(stringLiteral: "R"), argumentList: {
            TupleExprElement(label: "object", expression: .init(stringLiteral: "result"))
        }))
        let initializer = InitializerClauseSyntax(value: tryExpr)
        return .init(.let, name: IdentifierPattern(stringLiteral: "rtn"), initializer: initializer)
    }
}
fileprivate extension VariableDecl {
    
    static func setArg(_ label: String) -> Self {
        let initializer = InitializerClause(value: MemberAccessExprSyntax(stringLiteral: "\(label).pyPointer"))
        return .init(.let, name: .init(stringLiteral: "arg"), initializer: initializer)
    }
    
}

fileprivate extension SequenceExpr {
    static func setArg(_ i: Int, _ label: String) -> Self {
        //if many {
        return .init(stringLiteral: "args[\(i)] = \(label.lowercased()).pyPointer")
        //}
        //return .init(stringLiteral: "arg = \(label).pyPointer")
    }
}

fileprivate extension FunctionCallExpr {
    
    static func noArg( src: String) -> Self {
        return .init(callee: IdentifierExpr(stringLiteral: "PyObject_CallNoArgs")) {
            TupleExprElement(expression: .init(stringLiteral: src))
        }
    }
    
    static func oneArg( src: String) -> Self {
        return .init(callee: IdentifierExpr(stringLiteral: "PyObject_CallOneArg")) {
            TupleExprElement(expression: .init(stringLiteral: src))
            TupleExprElement(expression: .init(stringLiteral: "arg"))
        }
    }
    
    static func vectorCall(_ i: Int, src: String) -> Self {
        
        return .init(callee: IdentifierExpr(stringLiteral: "PyObject_Vectorcall")) {
            TupleExprElement(expression: .init(stringLiteral: src))
            TupleExprElement(expression: .init(stringLiteral: "args"))
            TupleExprElement(expression: .init(literal: i))
            TupleExprElement(expression: NilLiteralExpr())
        }
    }
    
    static func Py_DecRef(_ label: String) -> Self {
         
        return .init(callee: IdentifierExpr(stringLiteral: "Py_DecRef")) {
            TupleExprElement(expression: SubscriptExpr(stringLiteral: label) )
        }
    }
    static func _Py_DecRef(_ label: String) -> Self {
        
        return .init(callee: IdentifierExpr(stringLiteral: "Py_DecRef")) {
            TupleExprElement(expression: IdentifierExpr(stringLiteral: label) )
        }
    }
}

fileprivate extension GuardStmtSyntax {
    static func pyResult(_ i: Int, self: String, @CodeBlockItemListBuilder bodyBuilder: () -> CodeBlockItemListSyntax) -> Self {
        var call: FunctionCallExpr {
            switch i {
            case 0: return .noArg(src: self)
            case 1: return .oneArg(src: self)
            default: return .vectorCall(i, src: self)
            }
            
        }
        let cons = ConditionElementList {
            ConditionElement(condition: .optionalBinding(.init(
                letOrVarKeyword: .let,
                pattern: IdentifierPatternSyntax(stringLiteral: "result"),
                initializer: .init(value: call)
            )))
        }
        return .init(conditions: cons, bodyBuilder: bodyBuilder).withElseKeyword(.elseKeyword(leadingTrivia: .space))
    }
    
}


public class GenerateCallables {
    
    public init() {
        
    }
    
    var importer: IfConfigDecl {
        
        return .init(clauses: .init {
            .init(poundKeyword: .poundIf,condition: IdentifierExpr(stringLiteral: "BEEWARE"), elements: .statements(.init(itemsBuilder: {
                ImportDecl(stringLiteral: "//import PythonLib").withTrailingTrivia(.newline)
            })))
        }).withTrailingTrivia(.newline)
    }
    public var asFunctions: CodeBlockItemList {.init {
        importer
        ImportDecl(stringLiteral: "import Foundation")
        
    }}
    public var code: CodeBlockItemList {
        .init {
            importer
            ImportDecl(stringLiteral: "import Foundation")
            ExtensionDecl("extension PyPointer") {
                .init {
                    let use_gil: GenericPyCall.GILMode = .none
//                    for use_gil in [false, true] {
                        for i in 0...9 {
                            MemberDeclListItem(
                                decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .PyEncodable).functionDecl("callAsFunction")
                            ).withLeadingTrivia(.newlines(2))
//                            MemberDeclListItem(
//                                decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .PyPointer).functionDecl("callAsFunction")
//                            ).withLeadingTrivia(.newlines(2))
                            MemberDeclListItem(
                                decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .none).functionDecl("callAsFunction")
                            ).withLeadingTrivia(.newlines(2))
                            
                        }
//                    }
                }
            }.withTrailingTrivia(.newline)
            for use_gil in [GenericPyCall.GILMode.none, .enabled] {
                for i in 0...9 {
                    let call_title = "PythonCall\(use_gil == .enabled ? "WithGil" : "")"
                    GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .PyEncodable).functionDecl(call_title)
                    
                        .withLeadingTrivia(.newlines(2))
//                    GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .PyPointer).functionDecl(call_title)
//                        .withLeadingTrivia(.newlines(2))
                    GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .none).functionDecl(call_title)
                        .withLeadingTrivia(.newlines(2))
                }
                
            }
        }
    }
    
}
