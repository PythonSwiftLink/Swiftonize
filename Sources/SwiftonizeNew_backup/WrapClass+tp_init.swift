//
//  File.swift
//  
//
//  Created by MusicMaker on 05/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import WrapContainers

@resultBuilder
struct ArgsUnpacker {
    
    
    
    static func buildBlock(_ components: WrapArgProtocol...) -> [WrapArgProtocol] {
        components
    }
    
}

class createTP_Init {
    weak var _cls: WrapClass?
    var cls: WrapClass { _cls! }
    var args: [WrapArgProtocol]
    var __init__: WrapFunction? { cls.init_function }
    
    //init(@ArgsUnpacker args: () -> [WrapArgProtocol]) {
    init(cls: WrapClass, args: [WrapArgProtocol]) {
        self._cls = cls
        self.args = args
        
        
    }
    
    private var catchClauseList: CatchClauseListSyntax {
        func catchItem(_ label: String) -> CatchItemListSyntax {
            .init(
                arrayLiteral: .init(pattern: IdentifierPatternSyntax(identifier: .identifier(label)))
            )
        }
        let arg_count = args.count
        return .init {
            CatchClauseSyntax(catchItem("let err as PythonError")) {
                if arg_count > 1 {
                    #"""
                    switch err {
                    case .call: err.triggerError("\#(cls.title) __init__ Error")
                    default: err.triggerError("hmmmmmm")
                    }
                    """#.codeBlockItem
                } else {
                    #"""
                    switch err {
                    case .call: err.triggerError("arg type Error")
                    default: err.triggerError("hmmmmmm")
                    }
                    """#.codeBlockItem
                }
            }
            CatchClauseSyntax(catchItem("let other_error")) {
                "other_error.pyExceptionError()".codeBlockItem
            }
            
        }
    }
    
    var code: CodeBlockItemListSyntax {

        return .init {
            
            DoStmtSyntax(catchClauses: catchClauseList) {
                initVars
                nkwargs
                CodeBlockItemSyntax.if_nkwargs(args: args) {
                    //else
					
                    nargs
                    GuardStmtSyntax.nargs_kwargs(args.count)
                    handle_args_n_kwargs
                    //__init__.pyCall
                    
                }
                setPointer()
                //Expr(stringLiteral: #"print("setted pointer - \#(cls.title)", PySwiftObject_Cast(__self__).pointee.swift_ptr)"#)
            }
            //ReturnStmtSyntax(stringLiteral: "return -1")
        }
    }
    
    
    
    var nkwargs: VariableDeclSyntax {
		return try! .init("""
        let nkwargs = (kw == nil) ? 0 : PyDict_Size(kw)
        """)
    }
    
    var nargs: VariableDeclSyntax {
		return try! .init("""
        let nargs = PyTuple_Size(_args_)
        """)
    }
    
    var initVars: CodeBlockItemListSyntax {
        
        
        return .init {
            for arg in args {
                VariableDeclSyntax(
                    .let,
					name: PatternSyntax(stringLiteral: arg.name),
                    type: (arg as! WrapArgSyntax).typeAnnotation
                )
            }
        }
    }
    
    var handle_args_n_kwargs: CodeBlockItemListSyntax {
        
        return .init {
            for arg in args {
                let con_list = ConditionElementListSyntax {
                    .init {
                        SequenceExprSyntax(elements: .init {
                            //IdentifierExpr(stringLiteral: "__nargs__")
							ExprSyntax(stringLiteral: "nargs")
							BinaryOperatorExprSyntax(operatorToken: .rightAngleToken(leadingTrivia: .space))
                            IntegerLiteralExprSyntax(integerLiteral: arg.idx)
                        })
                    }
                }
				IfExprSyntax(
					conditions: con_list,
					body: .init {
						SequenceExprSyntax(pyTuple: arg)
					},
					elseKeyword: .keyword(.else),
					elseBody: .codeBlock(.init {
						SequenceExprSyntax(pyDict: arg)
					})
				)
//                IfStmt(leadingTrivia: .newline, conditions: con_list) {
//                    SequenceExprSyntax(pyTuple: arg)
//                } elseBody: {
//                    SequenceExprSyntax(pyDict: arg)
//                    
//                }

            }
        }
        
        
    }
    
    func setPointer() -> SequenceExprSyntax {
		let _throws_ = __init__?.throws ?? false
        //let unmanaged = IdentifierExpr(stringLiteral: "Unmanaged")
		let unmanaged = ExprSyntax(stringLiteral: "Unmanaged")
        let _passRetained = MemberAccessExprSyntax(base: unmanaged, dot: .periodToken(), name: .identifier(cls.unretained ? "passUnretained" : "passRetained"))
		var initExpr: ExprSyntaxProtocol {
			if _throws_ {
				return initPySwiftTargetThrows().with(\.leadingTrivia, .newline)
			} else {
				return initPySwiftTarget().with(\.leadingTrivia, .newline)
			}
		}
		
		let pass = FunctionCallExprSyntax(
			calledExpression: _passRetained,
			leftParen: .leftParenToken(),
			arguments: [.init(expression: initExpr)],
			rightParen: .rightParenToken(leadingTrivia: .newline)
		)
//		let pass = FunctionDeclSyntax(name: .identifier(cls.unretained ? "passUnretained" : "passRetained"), signature: .init(
//			parameterClause: .init(
//				leftParen: .leftParenToken(trailingTrivia: .newline), parameters: .init([])
//			)
//		)) {
//			initExpr
//		}
		
//        let passRetained = FunctionCallExprSyntax(
//			callee: _passRetained,
//			leftParen: .left,
//		) {
//			.init(expression: initExpr)
//		}//.with(\.rightParen, .rightParenToken(leadingTrivia: .newline))
        let toOpaque = FunctionCallExprSyntax(callee: MemberAccessExprSyntax(
            base: pass,
            dot: .periodToken(),
            name: .identifier("toOpaque")
        ))
        
        
        return .init {
            //Expr(stringLiteral: "PySwiftObject_Cast(__self__).pointee.swift_ptr")
//			ExprSyntax(stringLiteral: "PySwiftObject_Cast(__self__).pointee.swift_ptr")
			"__self__?.pointee.swift_ptr".expr
            AssignmentExprSyntax()
            toOpaque
        }
    }
    
    func initPySwiftTarget() -> FunctionCallExprSyntax {
		let id = IdentifierExprSyntax(identifier: .identifier(cls.title))
        
        let tuple = TupleExprElementListSyntax {
            //TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
            for arg in args {
                TupleExprElementSyntax(label: arg.label, expression: ExprSyntax(stringLiteral: arg.name))
            }
            
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken()
		)
		return f_exp
        
        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
	
	func initPySwiftTargetThrows() -> TryExprSyntax {
		let id = IdentifierExprSyntax(identifier: .identifier(cls.title))
		
		let tuple = TupleExprElementListSyntax {
			//TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
			for arg in args {
				TupleExprElementSyntax(label: arg.label, expression: ExprSyntax(stringLiteral: arg.name))
			}
			
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			argumentList: tuple,
			rightParen: .rightParenToken()
		)
		return .init(expression: f_exp)
		
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
	}
    
}

extension SequenceExprSyntax {
    
    init(pyDict arg: WrapArgProtocol) {
        self.init(elements: .init(itemsBuilder: {
            //IdentifierExpr(stringLiteral: arg.name)
			ExprSyntax(stringLiteral: arg.name)
            AssignmentExprSyntax()
            TryExprSyntax.pyDict_GetItem("kw", arg.name)
        }))
    }
    
    init(pyTuple arg: WrapArgProtocol) {
        self.init(elements: .init(itemsBuilder: {
//            IdentifierExpr(stringLiteral: arg.name)
			ExprSyntax(stringLiteral: arg.name)
            AssignmentExprSyntax()
            TryExprSyntax.pyTuple_GetItem("_args_", arg.idx)
        }))
    }
}

fileprivate extension CodeBlockItemListSyntax {
    static func handleKWArgs(_ args: [WrapArgProtocol]) -> Self {
        
        return .init {
            for arg in args {
                SequenceExprSyntax(elements: .init(itemsBuilder: {
                    //IdentifierExpr(stringLiteral: arg.name)
					ExprSyntax(stringLiteral: arg.name)
                    AssignmentExprSyntax()
                    TryExprSyntax.pyDict_GetItem("kw", arg.name)
                }))
            }
        }
    }
    static func handleArgs(_ args: [WrapArgProtocol]) -> Self {
        
        return .init {
            for arg in args {
                SequenceExprSyntax(elements: .init(itemsBuilder: {
                    //IdentifierExpr(stringLiteral: arg.name)
					ExprSyntax(stringLiteral: arg.name)
                    AssignmentExprSyntax()
                    TryExprSyntax.pyDict_GetItem("kw", arg.name)
                }))
            }
        }
    }
}

extension CodeBlockItemSyntax {
    static var nkwargs: Self {
//        .init(item: .init(VariableDeclSyntax(stringLiteral: """
//        let nkwargs = (kw == nil) ? 0 : _PyDict_GET_SIZE(kw)
//        """)))
		.init(stringLiteral: """
			let nkwargs = (kw == nil) ? 0 : PyDict_Size(kw)
			"""
		)
    }
    static func if_nkwargs(args: [WrapArgProtocol],  @CodeBlockItemListBuilder elseCode: () -> CodeBlockItemListSyntax) -> Self {
		let if_con = ConditionElementListSyntax {
			.init {
				ExprSyntax(stringLiteral: "nkwargs >= \(args.count)")
			}
		}
//        let if_con = ConditionElementListSyntax {
//            .init {
//                //SequenceExprSyntax(stringLiteral: "nkwargs >= \(args.count)")
//				try! SequenceExprSyntax("nkwargs >= \(args.count)")
//            }
//        }
		let ifexpr = IfExprSyntax(
			conditions: if_con,
			elseKeyword: .keyword(.else),
			elseBody: .codeBlock( .init(statements: elseCode() ) )) {
				CodeBlockItemListSyntax.handleKWArgs(args)
			}
//		if let ifexpr = IfExprSyntax(if_con, bodyBuilder: {
//			CodeBlockItemListSyntax.handleKWArgs(args)
//		}, else: {
//			elseCode()
//		})
//        let ifst = IfStmtSyntax(conditions: if_con) {
//            CodeBlockItemList.handleKWArgs(args)
//        } elseBody: {
//            elseCode()
//        }

        return .init(item: .init(ifexpr))
    }
    
//    static func _handleKWArgs(_ args: [WrapArgProtocol]) -> Self {
//        let blocklist = CodeBlockItemList {
//
//        }
//        return CodeBlockItemSyntax(item: .stmt(.init(fromProtocol: blocklist)) )
//        //return SyntaxFactory.makeCodeBlockItem(item: .init(blocklist) , semicolon: nil, errorTokens: nil)
//    }
    
    static func handleKWArgs(_ args: [WrapArgProtocol]) -> Self {
        let clist = ConditionElementListSyntax {
            for arg in args {
				
				OptionalBindingConditionSyntax(
					leadingTrivia: .newline + .tab,
					bindingSpecifier: .keyword(.let),
					pattern: PatternSyntax(stringLiteral: "_\(arg.name)"),
					initializer: .init(value: FunctionCallExprSyntax(
						callee: ExprSyntax(stringLiteral: "PyDict_GetItem"),
						argumentList: {
							LabeledExprSyntax.pyDictElement(key: "kw", type: .label)
							LabeledExprSyntax.pyDictElement(key: arg.name, type: .string)
						}
					))
				)
				
//                OptionalBindingConditionSyntax(
//                    letOrVarKeyword: .let,
//                    pattern: ExprSyntax(stringLiteral: "_\(arg.name)"),
//                    initializer: InitializerClauseSyntax(value: FunctionCallExprSyntax(
//                        callee: ExprSyntax(stringLiteral: "PyDict_GetItem"), argumentList: {
//                            LabeledExprSyntax.pyDictElement(key: "kw", type: .label)
//                            LabeledExprSyntax.pyDictElement(key: arg.name, type: .string)
//                        })
//                    )
//                    
//                ).withLeadingTrivia(.newline + .tab)
            }
        }.with(\.leadingTrivia, .newline)
   
        
        let gstmt = GuardStmtSyntax(conditions: clist, body: .init(statementsBuilder: {
            FunctionCallExprSyntax.pyErr_SetString("Args missing needed \(args.count)")
            //ReturnStmtSyntax(stringLiteral: "return -1")
			"return -1"
        }))
        
        
        return gstmt.codeBlockItem
    }
}


fileprivate extension GuardStmtSyntax {
    static func nargs_kwargs(_ n: Int) -> Self {
        
		return try! .init("guard nkwargs + nargs >= \(raw: n) else") {
            FunctionCallExprSyntax.pyErr_SetString("Args missing needed \(n)")
            //ReturnStmtSyntax(stringLiteral: "return -1")
			"return -1"
        }
    }
}



extension LabeledExprSyntax {
    enum pyDictElementType {
        case string
        case int
        case label
    }
    
    static func pyDictElement(key: String, type: pyDictElementType) -> Self {
        
        switch type {
        case .label:
            return .init(expression: ExprSyntax(stringLiteral: key))
        case .int:
            return .init(expression: ExprSyntax(stringLiteral: key))
        case .string:
            //return .init(expression: StringLiteralExprSyntax(stringLiteral: #""\#(key)""#))
			return .init(expression: StringLiteralExprSyntax(content: #""\#(key)""#))
        }
    }
}


fileprivate extension TupleExprElementListSyntax {
    
    static func PyDict_GetItem(o: String, key: String) -> Self {
        return .init {
			LabeledExprSyntax.pyDictElement(key: o, type: .label)
			LabeledExprSyntax.pyDictElement(key: key, type: .string)
        }
    }
    
}

fileprivate extension FunctionCallExprSyntax {
    
    static func pyErr_SetString(_ string: String) -> Self {
        
		return .init(callee: ExprSyntax(stringLiteral: "PyErr_SetString") ) {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: "PyExc_IndexError"))
			LabeledExprSyntax(expression: StringLiteralExprSyntax(content: "\(string)"))
		}
//        return .init(callee: IdentifierExpr(unicodeScalarLiteral: "PyErr_SetString") ) {
//            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: "PyExc_IndexError"))
//            TupleExprElementSyntax(expression: StringLiteralExprSyntax(stringLiteral: #""\#(string)""#))
//        }
    }
    
    static func pyDict_GetItem(_ o: String, _ key: String) -> Self {
        
		return .init(callee: ExprSyntax(stringLiteral: "PyDict_GetItem") ) {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: o))
			LabeledExprSyntax(expression: StringLiteralExprSyntax(content: "\(key)"))
		}
//        return .init(callee: IdentifierExpr(unicodeScalarLiteral: "PyDict_GetItem") ) {
//            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: o))
//            TupleExprElementSyntax(expression: StringLiteralExprSyntax(stringLiteral: #""\#(key)""#))
//        }
    }
    
    static func pyTuple_GetItem(_ o: String, _ key: Int) -> Self {
        
		return .init(callee: ExprSyntax(stringLiteral: "PyTuple_GetItem") ) {
			LabeledExprSyntax(expression: ExprSyntax(stringLiteral: o))
			//LabeledExprSyntax(expression: StringLiteralExprSyntax(content: "\(key)"))
			LabeledExprSyntax(expression: IntegerLiteralExprSyntax(key) )
		}
//        return .init(callee: IdentifierExpr(unicodeScalarLiteral: "PyTuple_GetItem") ) {
//            TupleExprElementSyntax(expression: ExprSyntax(stringLiteral: o))
//            TupleExprElementSyntax(expression: IntegerLiteralExprSyntax(integerLiteral: key))
//        }
    }
    
}

fileprivate extension TryExprSyntax {
    
    static func pyDict_GetItem(_ o: String, _ key: String) -> Self {
        
        return .init(expression: FunctionCallExprSyntax.pyDict_GetItem(o, key))
    }
    
    static func pyTuple_GetItem(_ o: String, _ key: Int) -> Self {
        
        return .init(expression: FunctionCallExprSyntax.pyTuple_GetItem(o, key))
    }
}
