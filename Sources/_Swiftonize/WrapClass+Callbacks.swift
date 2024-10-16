//
//  File.swift
//  
//
//  Created by MusicMaker on 24/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyAst
import PySwiftCore
//import SwiftSyntaxParser
import SwiftParser
import WrapContainers

extension TypeAnnotationSyntax {
//    static let pythonObject = TypeAnnotationSyntax(type: SimpleTypeIdentifier(stringLiteral: "PythonObject"))
	static let pythonObject = TypeAnnotationSyntax(type: TypeSyntax(stringLiteral: "PythonObject"))
    static let pyPointer = TypeAnnotationSyntax(type: TypeSyntax(stringLiteral: "PyPointer"))
}

//extension TypeSyntaxProtocol {
//    static let pyPointer = TypeSyntax(stringLiteral: "PyPointer")
//}

func CreateDeclMember(_ token: Keyword, name: String, type: TypeAnnotationSyntax, _private: Bool = false, initializer: InitializerClauseSyntax? = nil) -> MemberDeclListItemSyntax {
    return .init(decl: createClassDecl(
        token,
        name: name,
        type: type,
        _private: _private,
        initializer: initializer
    ))
}

func createClassDecl(_ token: Keyword, name: String, type: TypeAnnotationSyntax, _private: Bool = false, initializer: InitializerClauseSyntax? = nil) -> VariableDeclSyntax {
	return .init(
		modifiers: .init {
			if _private {
				.init(name: .keyword(._private))
			}
		},
		token,
		name: .init(stringLiteral: name),
		type: type,
		initializer: initializer
	)
//    return .init(
//        modifiers: _private ? .init(arrayLiteral: .init(name: .private)) : nil,
//        token,
//        name: .init(identifier: .identifier(name)),
//        type: type,
//        initializer: initializer
//    )
}

public class PyCallbacksGenerator {
    
    let cls: WrapClass
    
    public init(cls: WrapClass) {
        self.cls = cls
        
    }
    
    var assignCallback: SequenceExprSyntax {
        .init {
            .init {
                //IdentifierExpr(stringLiteral: "_pycall")
				ExprSyntax(stringLiteral: "_pycall")
                AssignmentExprSyntax()
                FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .periodToken(), name: "init")) {
                    "ptr"._tuplePExprElement("callback")
                }
            }
        }
    }
    var assignCallbackKeep: SequenceExprSyntax {
        .init {
            .init {
                ExprSyntax(stringLiteral: "_pycall")
                AssignmentExprSyntax()
                FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .periodToken(), name: "init")) {
                    "ptr"._tuplePExprElement("callback")
                    "keep_alive"._tuplePExprElement("true")
                }
            }
        }
    }
    
    var initializeCallbacks: CodeBlockItemListSyntax { .init {
        let conditions = ConditionElementListSyntax {
            ExprSyntax(stringLiteral: "PythonDict_Check(callback)")
        }
		IfExprSyntax(
			leadingTrivia: .newlines(2),
			conditions: conditions,
			body: .init {
				assignCallback
				for cp in cls.callbacks {
					cp.assignFromDict
				}
			},
			elseBody: .init(CodeBlockSyntax {
				assignCallbackKeep
				for cp in cls.callbacks {
					cp.assignFromClass
				}
			})
		)
//		IfExprSyntax(conditions: conditions) {
//            assignCallback
//            for cp in cls.callbacks {
//                cp.assignFromDict
//            }
//        } elseBody: {
//            assignCallbackKeep
//            for cp in cls.callbacks {
//                cp.assignFromClass
//            }
//        }//.with(\.leadingTrivia, .newlines(2))

    }}
    
    
    var _init: InitializerDeclSyntax {
        let sig = FunctionSignatureSyntax(input: .init(
            parameterList: .init(itemsBuilder: {
                .init(
                    firstName: .identifier("callback"),
                    colon: .colonToken(),
                    type: TypeSyntax(stringLiteral: "PyPointer"))
            })
        ))
        
        return .init(signature: sig) {
            initializeCallbacks
        }
    }
    
    var _deinit: DeinitializerDeclSyntax {
        try! .init("deinit") {
		
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

			//modifiers: [.init(name: .publictok)],
			modifiers: .init(itemsBuilder: {
				.init(name: .keyword(.public))
			}),
			identifier: .identifier(cls_title),
            inheritanceClause: inher) {
                .init {
                    
					CreateDeclMember(.var, name: "_pycall", type: .pythonObject)
						.with(\.leadingTrivia, .newlines(2))
						//.with(\.leadingTrivia, .newlines(2))
                    for f in cls.callbacks {
						CreateDeclMember(.var, name: "_\(f.name)", type: .pyPointer, _private: true)
                    }
                    
					_init.with(\.leadingTrivia, .newlines(2))
						//.with(\.leadingTrivia, .newlines(2))
                    
                    _deinit.with(\.leadingTrivia, .newline)
                    for f in cls.callbacks {
						PythonCall(function: f).functionDecl
							
							//.with(\.leadingTrivia, .newline)
                    }
                }.with(\.leadingTrivia, .newline)
            }
        
        return cls_dect
    }
    
}
