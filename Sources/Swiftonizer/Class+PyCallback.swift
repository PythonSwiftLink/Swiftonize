//
//  File.swift
//  
//
//  Created by CodeBuilder on 20/03/2024.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser
import PyWrapper

public struct PythonCall {
	
	private var callable_name: String?
	var cls: PyWrap.Class?
	var function: PyWrap.Function
	
	
	init(function: PyWrap.Function) {
		self.function = function
		self.cls = function.class
	}
	
	
	var wrap_class: PyWrap.Class {
		if let wrap_cls = function.class { return wrap_cls }
		//if let wrap_cls = wrap_cls { return wrap_cls }
		fatalError()
	}
	
	var call_target: String {
		if let call_target = function.call_target { return call_target }
		return function.name ?? "ErrorName"
	}
	
	var name: String {
		
		if let callable_name = callable_name {
			return callable_name
		}
		return function.name
	}
	
	var functionDecl: FunctionDeclSyntax {
	
		var signature = FunctionSignatureSyntax.init(parameterClause: .init(parameters: function.args.parameterList))
		if let returns = function.returns as? ArgTypeSyntax {
			signature.returnClause = .init(type: returns.typeSyntax)
		}
		return .init(name: .identifier(name), signature: signature) {
			//"var gil: PyGILState_STATE?"
			//"if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }"
			DoStmtSyntax(
				body: .init {
					py_call
				},
				catchClauses: .init {
					//CatchClauseSyntax(stringLiteral: "catch let err as PythonError {\n// python errors\n}")
					"catch let err as PythonError {\n// python errors\n}"
					"catch {\n// other errors\n}"
				}
			)
			if function.returns != nil {
				"fatalError()"
			}
			//"Py_DecRef(\(raw: name)_result)"
			//"if let gil = gil { PyGILState_Release(gil) }"
		}
	}
	
	private var py_call: CodeBlockItemListSyntax { .init {
		let returns = function.returns == nil ? "" : "return "
		if function.args.isEmpty {
			"\(raw: returns)try PythonCallWithGil(call: _\(raw: function.name))"
		} else {
			"\(raw: returns)try PythonCallWithGil(call: _\(raw: function.name), \(raw: function.args.map(\.name).joined(separator: ", ")))"
		}
	}}
	
}

extension PyWrap.Function {
	var pythonCall: PythonCall { .init(function: self) }
}


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
				.init(name: .keyword(.private))
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
	
	let cls: PyWrap.Class.Callbacks
	
	public init(cls: PyWrap.Class.Callbacks) {
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
					for f in cls.functions {
						CreateDeclMember(.var, name: "_\(f.name)", type: .init(type: TypeSyntax(stringLiteral: "PyPointer")), _private: true)
						//CreateDeclMember(.var, name: <#T##String#>, type: <#T##TypeAnnotationSyntax#>)
					}
					
					_init.with(\.leadingTrivia, .newlines(2))
					//.with(\.leadingTrivia, .newlines(2))
					
					_deinit.with(\.leadingTrivia, .newline)
					for f in cls.functions {
						PythonCall(function: f).functionDecl
						
						//.with(\.leadingTrivia, .newline)
					}
				}.with(\.leadingTrivia, .newline)
			}
		
		return cls_dect
	}
	
}
