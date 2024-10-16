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

//fileprivate let R_Generic = GenericParameterSyntaxClauseSyntax(stringLiteral: "<R: ConvertibleFromPython>")

fileprivate extension GenericParameterClauseSyntax {
    init(letters: [String], rtype: GenericPyCall.RType) {
		self.init(parameters: .init {
			for letter in letters {
				GenericParameterSyntax(name: .init(stringLiteral: letter))
			}
			
			if rtype == .PyEncodable {
				GenericParameterSyntax(name: "R")
			}
		})
//        self.init(GenericParameterListSyntax: .init(itemsBuilder: {
//            
//            for letter in letters {
//                GenericParameterSyntax(name: letter)
//            }
//            
//            if rtype == .PyEncodable {
//                GenericParameterSyntax(name: "R")
//            }
//        }))
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
    
    var parameters: FunctionParameterClauseSyntax {
		return .init {
			if let pyPointer = pyPointer {
				FunctionParameterSyntax(
					firstName: .identifier(pyPointer),
					//secondName: <#T##TokenSyntax?#>,
					colon: .colonToken(),
					type: IdentifierTypeSyntax(name: .identifier(pyPointer))
				)
			}
			for i in 0..<arg_count {
				
				FunctionParameterSyntax(
					firstName: .identifier("_ "),
					secondName: .identifier(LETTERS[i].lowercased()),
					colon: .colonToken(),
					type: IdentifierTypeSyntax(name: .identifier(LETTERS[i]))
				)//.withLeadingTrivia(arg_count > 2 ? .newline + .tab : .zero)
			}
		}
//        return .init(parameterList: .init {
//            if let pyPointer = pyPointer {
//                FunctionParameterSyntax(
//                    secondName: .identifier(pyPointer),
//                    colon: .colon,
//                    type: SimpleTypeIdentifier(stringLiteral: "PyPointer")
//					//type: IdentifierTypeSyntax(name: .identifier("PyPointer"))
//                )
//            }
//            for i in 0..<arg_count {
//                
//                FunctionParameterSyntax(
//                    firstName: .identifier("_ "),
//                    secondName: .identifier(LETTERS[i].lowercased()),
//                    colon: .colon,
//                    type: SimpleTypeIdentifier(stringLiteral: LETTERS[i])
//                )//.withLeadingTrivia(arg_count > 2 ? .newline + .tab : .zero)
//            }
//        })//.withRightParen(arg_count > 2 ? .rightParen.withLeadingTrivia(.newline + .tab) : .rightParen)
    }
    
    var returnClause: ReturnClauseSyntax? {
        switch returnType {
            
        case .PyPointer:
			return .init(type: TypeSyntax(stringLiteral: "PyPointer"))
			//return .init(returnType: SimpleTypeIdentifier(stringLiteral: "PyPointer" ))
        case .PyEncodable:
			return .init(type: TypeSyntax(stringLiteral: "R"))
            //return .init(returnType: SimpleTypeIdentifier(stringLiteral: "R" ))
        case .none:
            return nil
        }
        
    }
    
    var functionSignature: FunctionSignatureSyntax {
		
		return .init( parameterClause: parameters,
					  effectSpecifiers: .init(throwsSpecifier: .stringSegment("throws"))
		)
//        return .init(
//            input: parameters,
//            throwsOrRethrowsKeyword: .throws.withLeadingTrivia(.space),
//            output: returnClause
//        )
    }
    
    public func functionDecl(_ title: String) -> FunctionDeclSyntax {
		let variDecl = VariableDeclSyntax(bindingSpecifier: "let", bindings: PatternBindingListSyntax {
			let f_exp = FunctionCallExprSyntax(calledExpression: try! MemberAccessExprSyntax(name: .identifier("VectorCallArgs.allocate")), arguments: .init {
				.init(label: "capacity", expression: IntegerLiteralExprSyntax(integerLiteral: arg_count))
			})
			PatternBindingSyntax(pattern: IdentifierPatternSyntax(identifier: ""), initializer: .init(value: f_exp))
		})
//        let variDecl = VariableDeclSyntax(letOrVarKeyword: .let, bindings: PatternBindingListSyntax {
//			let f_expr = FunctionCallExprSyntax(callee: try! MemberAccessExprSyntax("VectorCallArgs.allocate")) {
//                .init(label: "capacity", expression: .init(literal: arg_count))
//            }
//            PatternBinding(pattern: IdentifierPattern(stringLiteral: arg_count > 1 ? "args" : "arg"), initializer: .init(value: f_expr))
//        })
        let post_args: CodeBlockItemListSyntax = .init {
            if arg_count > 0 {
                if arg_count > 1 {
                    for i in 0..<arg_count {
                        FunctionCallExprSyntax.Py_DecRef("args[\(i)]")
                    }
                    argsDealloc
                } else {
                    FunctionCallExprSyntax._Py_DecRef("__arg__")
                }
            }
        }
        let generics: GenericParameterClauseSyntax? = (arg_count > 0 || returnType == .PyEncodable) ?
			.init(letters: .init(LETTERS[0..<arg_count]), rtype: returnType) : nil
			//.init(letters: .init(LETTERS[0..<arg_count]), rtype: returnType) : nil
        
        var whereClause: GenericWhereClauseSyntax? {
            guard arg_count > 0 || returnType == .PyEncodable else { return nil }
            return .init {
                for letter in LETTERS[0..<arg_count] {
					GenericRequirementSyntax(requirement: .conformanceRequirement(.init(leftType: TypeSyntax(stringLiteral: letter), rightType: TypeSyntax(stringLiteral: "PyEncodable"))))
						.with(\.leadingTrivia, .newline + .tab)
//                    GenericRequirement(body: .conformanceRequirement(.init(leftTypeIdentifier: SimpleTypeIdentifier(stringLiteral: letter), rightTypeIdentifier: SimpleTypeIdentifier(stringLiteral: "PyEncodable"))))
//                        .withLeadingTrivia(.newline + .tab)
                }
                if returnType == .PyEncodable {
//                    GenericRequirement(body: .conformanceRequirement(.init(leftTypeIdentifier: SimpleTypeIdentifier(stringLiteral: "R"), rightTypeIdentifier: SimpleTypeIdentifier(stringLiteral: "PyDecodable"))))
//                        .withLeadingTrivia(.newline + .tab)
					GenericRequirementSyntax(requirement: .conformanceRequirement(.init(leftType: TypeSyntax(stringLiteral: "R"), rightType: TypeSyntax(stringLiteral: "PyDecodable"))))
						.with(\.leadingTrivia, .newline + .tab)
                }
            }//.withLeadingTrivia(.newline + .tab)
        }
        var attributeList: AttributeListSyntax? {
            guard returnType == .PyPointer else { return nil }
            return .init {
				AttributeSyntax(stringLiteral: "_disfavoredOverload")
                //CustomAttributeSyntax(.init(stringLiteral: "_disfavoredOverload"))
			}.with(\.leadingTrivia, .newline)//.with(\.leadingTrivia, .newline)
        }
        //returnType == .ConvertibleFromPython ? .R : nil
		let bodyList:  CodeBlockItemListSyntax = .init {
			let gil = self.gil_mode == .enabled
			if gil {
				if returnType == .PyPointer {
					ExprSyntax(stringLiteral: "_ = PyGILState_Ensure()")
					
					
				} else {
					VariableDeclSyntax(.let, name: PatternSyntax(stringLiteral: "gil"), initializer: .init(value: FunctionCallExprSyntax(callee: ExprSyntax(stringLiteral: "PyGILState_Ensure"))))
//					VariableDeclSyntax(.let) {
//						PatternBindingSyntax(pattern: PatternSyntax(stringLiteral: "gil"), initializer: .init(value: FunctionCallExprSyntax(callee: ExprSyntax(stringLiteral: "PyGILState_Ensure"))))
//					}
				}
			}
			if arg_count > 0 {
				if arg_count > 1 {
					variDecl
					for i in 0..<arg_count {
						SequenceExprSyntax.setArg(i, LETTERS[i])
					}
				} else {
					VariableDeclSyntax.setArg("a")
				}
			}
			
			
			GuardStmtSyntax.pyResult(arg_count, self: pyPointer ?? "self") {
				pyErr_Print
				post_args
				
				//ThrowStmtSyntax(stringLiteral: "throw PythonError.call")
				ThrowStmtSyntax(expression: ExprSyntax(stringLiteral: "PythonError.call"))
			}
			post_args
			
			
			switch returnType {
			case .PyEncodable:
				handleReturn
				FunctionCallExprSyntax._Py_DecRef("result")
				if gil {
					//FunctionCallExprSyntax(stringLiteral: "PyGILState_Release(gil)")
					ExprSyntax(stringLiteral: "PyGILState_Release(gil)")
				}
				//ReturnStmtSyntax(stringLiteral: "return rtn")
				ExprSyntax(stringLiteral: "return nil")
			case .PyPointer:
				//ReturnStmtSyntax(stringLiteral: "return result")
				ExprSyntax(stringLiteral: "return result")
			case .none:
				if gil {
					//FunctionCallExprSyntax(stringLiteral: "PyGILState_Release(gil)")
					ExprSyntax(stringLiteral: "PyGILState_Release(gil)")
				}
				FunctionCallExprSyntax._Py_DecRef("result")
			}
			
		}
		let body = CodeBlockSyntax(statements: bodyList)
        let public_mod = ModifierListSyntax {
            DeclModifierSyntax(name: .identifier("public "))
        }
		
		if let attributeList = attributeList {
			return .init(
				attributes: attributeList,
				modifiers: public_mod,
				name: .identifier(title),
				genericParameterClause: generics,
				signature: functionSignature,
				genericWhereClause: whereClause,
				body: body
			)
		}
		return .init(
			modifiers: public_mod,
			name: .identifier(title),
			genericParameterClause: generics,
			signature: functionSignature,
			genericWhereClause: whereClause,
			body: body
		)

//        return .init(
//            attributes: attributeList,
//            modifiers: public_mod,
//            identifier: .identifier(title),
//            GenericParameterSyntaxClauseSyntax: generics,
//            signature: functionSignature,
//            genericWhereClause: whereClause) {
//            let gil = self.gil_mode == .enabled
//            if gil {
//                if returnType == .PyPointer {
//                    SequenceExprSyntax(stringLiteral: "_ = PyGILState_Ensure()")
//                    
//                } else {
//                    VariableDeclSyntax(letOrVarKeyword: .let) {
//                        PatternBinding(pattern: IdentifierPattern(stringLiteral: "gil"), initializer: .init(value: FunctionCallExprSyntax(callee: IdentifierExpr(stringLiteral: "PyGILState_Ensure"))))
//                    }
//                }
//            }
//            if arg_count > 0 {
//                if arg_count > 1 {
//                    variDecl
//                    for i in 0..<arg_count {
//                        SequenceExpr.setArg(i, LETTERS[i])
//                    }
//                } else {
//                    VariableDeclSyntax.setArg("a")
//                }
//            }
//      
//            
//            GuardStmtSyntax.pyResult(arg_count, self: pyPointer ?? "self") {
//                pyErr_Print
//                post_args
//                
//                ThrowStmtSyntax(stringLiteral: "throw PythonError.call")
//            }
//            post_args
//            
//            
//            switch returnType {
//            case .PyEncodable:
//                handleReturn
//                FunctionCallExprSyntax._Py_DecRef("result")
//                if gil {
//                    FunctionCallExprSyntax(stringLiteral: "PyGILState_Release(gil)")
//                }
//                ReturnStmtSyntax(stringLiteral: "return rtn")
//            case .PyPointer:
//                ReturnStmtSyntax(stringLiteral: "return result")
//            case .none:
//                if gil {
//                    FunctionCallExprSyntax(stringLiteral: "PyGILState_Release(gil)")
//                }
//                FunctionCallExprSyntax._Py_DecRef("result")
//            }
//            
//        }
    }
    
    var pyErr_Print: FunctionCallExprSyntax {
        .init(callee: ExprSyntax(stringLiteral: "PyErr_Print"))
		//.init(calledExpression: DeclReferenceExprSyntax(baseName: .identifier("PyErr_Print")), arguments: .init {
    }
    
    
    var argsDealloc: FunctionCallExprSyntax {
        //.init(stringLiteral: "args.deallocate()")
		.init(callee: ExprSyntax(stringLiteral: "args.deallocate()"))
    }
    
    var handleReturn: VariableDeclSyntax {
        let tryExpr = TryExprSyntax(expression: FunctionCallExprSyntax(callee: ExprSyntax(stringLiteral: "R"), argumentList: {
			TupleExprElementSyntax(label: "object", expression: ExprSyntax(stringLiteral: "result"))
        }))
        let initializer = InitializerClauseSyntax(value: tryExpr)
		return .init(.let, name: .init(stringLiteral: "rtn"), initializer: initializer)
        //return .init(.let, name: IdentifierPattern(stringLiteral: "rtn"), initializer: initializer)
    }
}
fileprivate extension VariableDeclSyntax {
    
    static func setArg(_ label: String) -> Self {
//        let initializer = InitializerClauseSyntax(value: MemberAccessExprSyntax(stringLiteral: "\(label).pyPointer"))
		let initializer = InitializerClauseSyntax(value: ExprSyntax(stringLiteral: "\(label).pyPointer"))
		return .init(.let, name: .init(stringLiteral: "__arg__"), initializer: initializer)
    }
    
}

fileprivate extension SequenceExprSyntax {
    static func setArg(_ i: Int, _ label: String) -> Self {
        //if many {
		return .init(elements: ExprListSyntax([
			.init(stringLiteral: "args[\(i)] = \(label.lowercased()).pyPointer")
		]))
        //return .init(stringLiteral: "args[\(i)] = \(label.lowercased()).pyPointer")
        //}
        //return .init(stringLiteral: "arg = \(label).pyPointer")
    }
}

fileprivate extension FunctionCallExprSyntax {
    
    static func noArg( src: String) -> Self {
//        return .init(callee: IdentifierExpr(stringLiteral: "PyObject_CallNoArgs")) {
//            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: src))
//        }
		return .init(callee: ExprSyntax(stringLiteral: "PyObject_CallNoArgs")) {
			TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: src))
		}
    }
    
    static func oneArg( src: String) -> Self {
//        return .init(callee: IdentifierExpr(stringLiteral: "PyObject_CallOneArg")) {
//            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: src))
//            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: "arg"))
//        }
		return .init(callee: ExprSyntax(stringLiteral: "PyObject_CallOneArg")) {
			TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: src))
			TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: "__arg__"))
		}
    }
    
    static func vectorCall(_ i: Int, src: String) -> Self {
        
        return .init(callee: ExprSyntax(stringLiteral: "PyObject_Vectorcall")) {
            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: src))
            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: "__args__"))
            TupleExprElementSyntax(expression: ExprSyntax(literal: i))
            TupleExprElementSyntax(expression: NilLiteralExprSyntax())
        }
    }
    
    static func Py_DecRef(_ label: String) -> Self {
		return .init(callee: ExprSyntax(stringLiteral: "Py_DecRef")) {
			TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: label) )
		}
//        return .init(callee: IdentifierExpr(stringLiteral: "Py_DecRef")) {
//            TupleExprElementSyntax(expression: SubscriptExpr(stringLiteral: label) )
//        }
    }
    static func _Py_DecRef(_ label: String) -> Self {
		return .init(callee: ExprSyntax(stringLiteral: "Py_DecRef")) {
			TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: label) )
		}
//        return .init(callee: IdentifierExpr(stringLiteral: "Py_DecRef")) {
//            TupleExprElementSyntax(expression: IdentifierExpr(stringLiteral: label) )
//        }
    }
}

fileprivate extension GuardStmtSyntax {
    static func pyResult(_ i: Int, self: String, @CodeBlockItemListBuilder bodyBuilder: () -> CodeBlockItemListSyntax) -> Self {
        var call: FunctionCallExprSyntax {
            switch i {
            case 0: return .noArg(src: self)
            case 1: return .oneArg(src: self)
            default: return .vectorCall(i, src: self)
            }
            
        }
//        let cons = ConditionElementListSyntax {
//            ConditionElementSyntax(condition: .optionalBinding(.init(
//                letOrVarKeyword: .let,
//                pattern: IdentifierPatternSyntax(stringLiteral: "result"),
//                initializer: .init(value: call)
//            )))
//        }
		let cons = ConditionElementListSyntax {
			ConditionElementSyntax(condition: .optionalBinding(
				.init(
					bindingSpecifier: .init(stringLiteral: "let"),
					pattern: PatternSyntax(stringLiteral: "result"),
					initializer: .init(value: call)
				)
			
			))
//			ConditionElementSyntax(condition: .optionalBinding(.init(
//				letOrVarKeyword: .let,
//				pattern: ExprSyntax(stringLiteral: "result"),
//				initializer: .init(value: call)
//			)))
		}
        //return .init(conditions: cons, bodyBuilder: bodyBuilder).withElseKeyword(.elseKeyword(leadingTrivia: .space))
		return .init(conditions: cons, bodyBuilder: bodyBuilder)
    }
    
}


public class GenerateCallables {
    
    public init() {
        
    }
    
    var importer: IfConfigDeclSyntax {
		return .init(clauses: .init {
			
		})
//        return .init(clauses: .init {
//            .init(poundKeyword: .poundIf,condition: IdentifierExpr(stringLiteral: "BEEWARE"), elements: .statements(.init(itemsBuilder: {
//                ImportDecl(stringLiteral: "//import PythonLib").with(\.leadingTrivia, .newline)
//            })))
//        }).with(\.leadingTrivia, .newline)
    }
    public var asFunctions: CodeBlockItemListSyntax {.init {
        importer
        //ImportDeclSyntax(stringLiteral: "import Foundation")
        try! ImportDeclSyntax("import Foundation")
    }}
	public var code: CodeBlockItemListSyntax {
		.init {
			importer
			try! ImportDeclSyntax("import Foundation")
			try! ExtensionDeclSyntax("extension PyPointer") {
				.init {
					let use_gil: GenericPyCall.GILMode = .none
					//                    for use_gil in [false, true] {
					for i in 0...9 {
						MemberDeclListItemSyntax(
							leadingTrivia: .newlines(2),
							decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .PyEncodable).functionDecl("callAsFunction")
						)
						//                            MemberDeclListItem(
						//                                decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .PyPointer).functionDecl("callAsFunction")
						//                            ).with(\.leadingTrivia, .newlines(2))
						MemberDeclListItemSyntax(
							leadingTrivia: .newlines(2),
							decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .none).functionDecl("callAsFunction")
						)
						
					}
					//                    }
				}
			}.with(\.trailingTrivia, .newline)
			for use_gil in [GenericPyCall.GILMode.none, .enabled] {
				for i in 0...9 {
					let call_title = "PythonCall\(use_gil == .enabled ? "WithGil" : "")"
					GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .PyEncodable).functionDecl(call_title)
					
						.with(\.leadingTrivia , .newlines(2))
					//                    GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .PyPointer).functionDecl(call_title)
					//                        .with(\.leadingTrivia, .newlines(2))
					GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .none).functionDecl(call_title)
						.with(\.leadingTrivia , .newlines(2))
				}
				
			}
		}
	}
//    public var code: CodeBlockItemList {
//        .init {
//            importer
//            ImportDecl(stringLiteral: "import Foundation")
//            ExtensionDecl("extension PyPointer") {
//                .init {
//                    let use_gil: GenericPyCall.GILMode = .none
////                    for use_gil in [false, true] {
//                        for i in 0...9 {
//                            MemberDeclListItem(
//                                decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .PyEncodable).functionDecl("callAsFunction")
//                            ).with(\.leadingTrivia, .newlines(2))
////                            MemberDeclListItem(
////                                decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .PyPointer).functionDecl("callAsFunction")
////                            ).with(\.leadingTrivia, .newlines(2))
//                            MemberDeclListItem(
//                                decl: GenericPyCall(arg_count: i, gil_mode: use_gil, rtn: .none).functionDecl("callAsFunction")
//                            ).with(\.leadingTrivia, .newlines(2))
//                            
//                        }
////                    }
//                }
//            }.with(\.leadingTrivia, .newline)
//            for use_gil in [GenericPyCall.GILMode.none, .enabled] {
//                for i in 0...9 {
//                    let call_title = "PythonCall\(use_gil == .enabled ? "WithGil" : "")"
//                    GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .PyEncodable).functionDecl(call_title)
//                    
//                        .with(\.leadingTrivia, .newlines(2))
////                    GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .PyPointer).functionDecl(call_title)
////                        .with(\.leadingTrivia, .newlines(2))
//                    GenericPyCall(arg_count: i, pyPointer: "call", gil_mode: use_gil, rtn: .none).functionDecl(call_title)
//                        .with(\.leadingTrivia, .newlines(2))
//                }
//                
//            }
//        }
//    }
    
}
