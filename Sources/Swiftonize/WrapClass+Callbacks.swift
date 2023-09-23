//
//  File.swift
//  
//
//  Created by MusicMaker on 24/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyAstParser
import PythonSwiftCore
//import SwiftSyntaxParser
import SwiftParser
import WrapContainers

extension TypeAnnotation {
    static let pythonObject = TypeAnnotation(type: SimpleTypeIdentifier(stringLiteral: "PythonObject"))
    static let pyPointer = TypeAnnotation(type: SimpleTypeIdentifier(stringLiteral: "PyPointer"))
}

//extension TypeSyntaxProtocol {
//    static let pyPointer = TypeSyntax(stringLiteral: "PyPointer")
//}

func CreateDeclMember(_ token: Token, name: String, type: TypeAnnotation, _private: Bool = false, initializer: InitializerClause? = nil) -> MemberDeclListItem {
    return .init(decl: createClassDecl(
        token,
        name: name,
        type: type,
        _private: _private,
        initializer: initializer
    ))
}

func createClassDecl(_ token: Token, name: String, type: TypeAnnotation, _private: Bool = false, initializer: InitializerClause? = nil) -> VariableDeclSyntax {
    return .init(
        modifiers: _private ? .init(arrayLiteral: .init(name: .private)) : nil,
        token,
        name: .init(identifier: .identifier(name)),
        type: type,
        initializer: initializer
    )
}

public class PyCallbacksGenerator {
    
    let cls: WrapClass
    
    public init(cls: WrapClass) {
        self.cls = cls
        
    }
    
    var assignCallback: SequenceExpr {
        .init {
            .init {
                IdentifierExpr(stringLiteral: "_pycall")
                AssignmentExpr()
                FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .period, name: "init")) {
                    "ptr"._tuplePExprElement("callback")
                }
            }
        }
    }
    var assignCallbackKeep: SequenceExpr {
        .init {
            .init {
                IdentifierExpr(stringLiteral: "_pycall")
                AssignmentExpr()
                FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .period, name: "init")) {
                    "ptr"._tuplePExprElement("callback")
                    "keep_alive"._tuplePExprElement("true")
                }
            }
        }
    }
    
    var initializeCallbacks: CodeBlockItemList { .init {
        let conditions = ConditionElementList {
            FunctionCallExprSyntax(stringLiteral: "PythonDict_Check(callback)")
        }
        IfStmt(conditions: conditions) {
            assignCallback
            for cp in cls.callbacks {
                cp.assignFromDict
            }
        } elseBody: {
            assignCallbackKeep
            for cp in cls.callbacks {
                cp.assignFromClass
            }
        }.withLeadingTrivia(.newlines(2))

    }}
    
    
    var _init: InitializerDecl {
        let sig = FunctionSignature(input: .init(
            parameterList: .init(itemsBuilder: {
                .init(
                    firstName: .identifier("callback"),
                    colon: .colon,
                    type: SimpleTypeIdentifier(stringLiteral: "PyPointer"))
            })
        ))
        
        return .init(signature: sig) {
            initializeCallbacks
        }
    }
    
    var _deinit: DeinitializerDecl {
        .init("deinit") {
            
        }
    }
    
    public var code: ClassDeclSyntax {
        let new_callback = ( cls.bases.count == 0)
        let inher: TypeInheritanceClauseSyntax? = new_callback ? nil : .init {
            for base in cls.bases { base.inheritedType }
            for cp in cls.callback_protocols { cp.inheritedType }
        }
        let cls_title = cls.new_class ?  cls.title : "\(cls.title)PyCallback"
        let cls_dect = ClassDeclSyntax(
            attributes: nil,
			modifiers: [.init(name: .public)],
            identifier: cls_title,
            inheritanceClause: inher) {
                .init {
                    
                    CreateDeclMember(.var, name: "_pycall", type: .pythonObject).withLeadingTrivia(.newlines(2))
                    for f in cls.callbacks {
                        CreateDeclMember(.var, name: "_\(f.name)", type: .pyPointer, _private: true)
                    }
                    
                    _init.withLeadingTrivia(.newlines(2))
                    
                    _deinit.withTrailingTrivia(.newline)
                    for f in cls.callbacks {
						PythonCall(function: f).functionDecl.withTrailingTrivia(.newline)
                    }
                }.withTrailingTrivia(.newline)
            }
        
        return cls_dect
    }
    
}
