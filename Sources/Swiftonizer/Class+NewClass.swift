import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser
import PyWrapper



public class NewClassGenerator {
	
	let cls: PyWrap.Class
	
	public init(cls: PyWrap.Class) {
		self.cls = cls
		
	}
	
	var assignCallback: SequenceExprSyntax {
		.init {
			.init {
				//IdentifierExpr(stringLiteral: "_pycall")
				ExprSyntax(stringLiteral: "_pycall")
				AssignmentExprSyntax()
				//				FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .periodToken(), name: "init")) {
				//					"ptr"._tuplePExprElement("callback")
				//				}
				ExprSyntax(stringLiteral: "callback.xINCREF")
				//				FunctionCallExprSyntax(callee: MemberAccessExprSyntax(period: .periodToken(), name: .identifier("init"))) {
				//
				//				}
			}
		}
	}
	var assignCallbackKeep: SequenceExprSyntax {
		.init {
			.init {
				ExprSyntax(stringLiteral: "_pycall")
				AssignmentExprSyntax()
				//				FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .periodToken(), name: "init")) {
				//					"ptr"._tuplePExprElement("callback")
				//					"keep_alive"._tuplePExprElement("true")
				//				}
				ExprSyntax(stringLiteral: "callback.xINCREF")
			}
		}
	}
	
	var initializeCallbacks: CodeBlockItemListSyntax { .init {
		let conditions = ConditionElementListSyntax {
			ExprSyntax(stringLiteral: "PyDict_Check(callback)")
		}
		let cls = cls.callbacks!
		IfExprSyntax(
			leadingTrivia: .newlines(2),
			conditions: conditions,
			body: .init {
				assignCallback
				for cp in cls.functions {
					cp.assignFromDict
				}
			},
			elseKeyword: .keyword(.else),
			elseBody: .init(CodeBlockSyntax {
				assignCallbackKeep
				for cp in cls.functions {
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
        let sig = FunctionSignatureSyntax(parameterClause: .init(
			parameters: .init(itemsBuilder: {
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
			"Py_DecRef(_pycall)"
		}
	}
    
    private var attributes: AttributeListSyntax {
        .init {
            AttributeSyntax.dynamicMemberLookup
        }
    }
    
    private var inheritanceClause:  InheritanceClauseSyntax? {
        let bases = cls.bases()
        
        if bases.isEmpty { return nil }
        return cls.new_class ? .init(inheritedTypes: .init {
            let bases = cls.bases()
            for base in bases.filter({$0 == .NSObject}) {
                base.rawValue.inheritanceType
            }
        }) : nil
    }
	
    private var modifiers: DeclModifierListSyntax {
        [
            .public
        ]
    }
        
    public var code: ClassDeclSyntax {
        
        let cls_title = cls.new_class ?  cls.name : "PyCallback"
        return ClassDeclSyntax(
            leadingTrivia: .newline,
            attributes: attributes,
            modifiers: modifiers,
            name: .identifier(cls_title),
            inheritanceClause: inheritanceClause
        ) { .init {
            
            CreateDeclMember(.var, name: "_pycall", type: .init(type: TypeSyntax(stringLiteral: "PyPointer")))
                .with(\.leadingTrivia, .newlines(2))
            
            for f in cls.callbacks?.functions ?? [] {
                CreateDeclMember(.var, name: "_\(f.name)", type: .init(type: TypeSyntax(stringLiteral: "PyPointer")), _private: true)
            }
            
            _init.with(\.leadingTrivia, .newlines(2))
            
            _deinit.with(\.leadingTrivia, .newline)
            for f in cls.callbacks?.functions ?? [] {
                PythonCall(function: f).functionDecl
            }
            
            DynamicMemberLookup(cls_var: "_pycall").code
        }}
    }
//		let cls_dect = ClassDeclSyntax(
//			
//			//modifiers: [.init(name: .publictok)],
//			modifiers: .init(itemsBuilder: {
//				.init(name: .keyword(.public))
//			}),
//			identifier: .identifier(cls_title),
//			inheritanceClause: inher) {
//				.init {
//					
//					CreateDeclMember(.var, name: "_pycall", type: .init(type: TypeSyntax(stringLiteral: "PyPointer")))
//						.with(\.leadingTrivia, .newlines(2))
//					//.with(\.leadingTrivia, .newlines(2))
//					for f in cls.callbacks?.functions ?? [] {
//						CreateDeclMember(.var, name: "_\(f.name)", type: .init(type: TypeSyntax(stringLiteral: "PyPointer")), _private: true)
//						//CreateDeclMember(.var, name: <#T##String#>, type: <#T##TypeAnnotationSyntax#>)
//					}
//					
//					_init.with(\.leadingTrivia, .newlines(2))
//					//.with(\.leadingTrivia, .newlines(2))
//					
//					_deinit.with(\.leadingTrivia, .newline)
//					for f in cls.callbacks?.functions ?? [] {
//						PythonCall(function: f).functionDecl
//						
//						//.with(\.leadingTrivia, .newline)
//					}
//				}.with(\.leadingTrivia, .newline)
//			}
//		
//		return cls_dect
	
	
}
