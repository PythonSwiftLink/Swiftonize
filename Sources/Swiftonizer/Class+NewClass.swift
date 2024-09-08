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
		IfExprSyntax(
			leadingTrivia: .newlines(2),
			conditions: conditions,
			body: .init {
				assignCallback
				for cp in cls.functions ?? [] {
					cp.assignFromDict
				}
			},
			elseKeyword: .keyword(.else),
			elseBody: .init(CodeBlockSyntax {
				assignCallbackKeep
				for cp in cls.functions ?? [] {
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
			"Py_DecRef(_pycall)"
		}
	}
	
	public var code: ClassDeclSyntax {
		let bases = cls.bases()
		//guard let cls = cls else { fatalError() }
		let new_callback = true //( bases.count == 0)
		let inher: TypeInheritanceClauseSyntax? = new_callback ? nil : .init {
			//for base in bases { base.rawValue.inheritedType }
			//for cp in cls.callback_protocols { cp.inheritedType }
		}
		//		let cls_title = cls.new_class ?  cls.name : "\(cls.name)PyCallback"
		let cls_title = cls.new_class ?  cls.name : "PyCallback"
		let cls_dect = ClassDeclSyntax(
			
			//modifiers: [.init(name: .publictok)],
			modifiers: .init(itemsBuilder: {
				.init(name: .keyword(.public))
			}),
			identifier: .identifier(cls_title),
			inheritanceClause: inher) {
				.init {
					
					CreateDeclMember(.var, name: "_pycall", type: .init(type: TypeSyntax(stringLiteral: "PyPointer")))
						.with(\.leadingTrivia, .newlines(2))
					//.with(\.leadingTrivia, .newlines(2))
					for f in cls.functions ?? [] {
						CreateDeclMember(.var, name: "_\(f.name)", type: .init(type: TypeSyntax(stringLiteral: "PyPointer")), _private: true)
						//CreateDeclMember(.var, name: <#T##String#>, type: <#T##TypeAnnotationSyntax#>)
					}
					
					_init.with(\.leadingTrivia, .newlines(2))
					//.with(\.leadingTrivia, .newlines(2))
					
					_deinit.with(\.leadingTrivia, .newline)
					for f in cls.functions ?? [] {
						PythonCall(function: f).functionDecl
						
						//.with(\.leadingTrivia, .newline)
					}
				}.with(\.leadingTrivia, .newline)
			}
		
		return cls_dect
	}
	
}
