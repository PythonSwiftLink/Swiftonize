import Foundation
import PyWrapper
import SwiftSyntaxBuilder
import SwiftSyntax



class ObjectInitializer {
	
	weak var _cls: PyWrap.Class?
	var cls: PyWrap.Class { _cls! }
	var args: [AnyArg] = []
	var cls_name: String
	
	init(_cls: PyWrap.Class? = nil, generic_target: String? = nil) {
		self._cls = _cls
		if let __init__ = _cls?.__init__ {
			args = __init__.args
			
			print(args)
		} else if let __init__ = _cls!.functions?.first(where: { $0.name == "__init__" }) {
			args = __init__.args
        } else if _cls?.new_class ?? false {
            args = [
                PyWrap.PyObjectArg(ast: .init(label: "callback"), type: .init(from: .init(id: "object"), type: .object))
            ]
        }
		cls_name = generic_target ?? _cls?.name ?? ""
	}
}





extension ObjectInitializer {
	
	var initVars: [VariableDeclSyntax] {
//        if cls.new_class {
//            [
//                VariableDeclSyntax(.var, name: .init(stringLiteral: "callback"), type: .init(type: TypeSyntax(stringLiteral: "PyPointer")))
//            ]
//        } else {
            args.map { arg in
                VariableDeclSyntax(.var, name: .init(stringLiteral: arg.optional_name ?? arg.name), type: .init(type: arg._typeSyntax))
            }
        //}
	}
	
	var codeBlock: SwiftSyntax.CodeBlockItemListSyntax { .init {
        if cls.options.py_init {
            if args.count > 0 {
                DoStmtSyntax(catchClauses: catchClauses) {
                    for initvar in initVars { initvar }
                    "let nkwargs = (kw == nil) ? 0 : PyDict_Size(kw)"
                    if_nkwargs(elseCode: .init {
                        "let nargs = PyTuple_Size(_args_)"
                        GuardStmtSyntax.nargs_kwargs(args.count)
                        handle_args_n_kwargs
                        
                    })
                    setPointer()
                    "return 0"
                }
                "return -1"
            } else {
                setPointer()
                //"return 0"
            }
        } else if cls.new_class {
            DoStmtSyntax(catchClauses: catchClauses) {
                for initvar in initVars { initvar }
                "let nkwargs = (kw == nil) ? 0 : PyDict_Size(kw)"
                if_nkwargs(elseCode: .init {
                    "let nargs = PyTuple_Size(_args_)"
                    GuardStmtSyntax.nargs_kwargs(args.count)
                    handle_args_n_kwargs
                    
                })
                setPointer()
                "return 0"
            }
            "return -1"
        } else {
		"""
		PyErr_SetString(PyExc_NotImplementedError,"\(raw: cls_name) can only be inited from swift")
		"""
		"return -1"
		}
	}}
	
	func if_nkwargs(elseCode: CodeBlockItemListSyntax) -> IfExprSyntax {
		let if_con = ConditionElementListSyntax {
			ExprSyntax(stringLiteral: "nkwargs >= \(args.count)")
		}
		return .init(
			conditions: if_con,
			body: .init(statements: handleKWArgs() ),
			elseKeyword: .keyword(.else),
			elseBody: .codeBlock(.init(statements: elseCode))
		)
	}
	
	func handleKWArgs() -> CodeBlockItemListSyntax {
		
		return .init {
			for arg in args {
				let arg_name = arg.optional_name ?? arg.name
				SequenceExprSyntax(elements: .init(itemsBuilder: {
					//IdentifierExpr(stringLiteral: arg.name)
					ExprSyntax(stringLiteral: "\( arg_name)")
					AssignmentExprSyntax()
					TryExprSyntax.pyDict_GetItem("kw", "\(arg_name)")
				}))
			}
		}
	}
	
	func catchItem(_ label: String) -> CatchItemListSyntax {
		.init(
			arrayLiteral: .init(pattern: IdentifierPatternSyntax(identifier: .identifier(label)))
		)
	}
//	private var catchClauses: CatchClauseListSyntax { 
//		let arg_count = args.count
//		return .init {
//            CatchClauseSyntax(catchItem("let err as PyStandardException")) {
//                "setPyException(type: err, message: \(literal: cls_name))"
//            }
//			CatchClauseSyntax(catchItem("let err as PythonError")) {
//				if arg_count > 1 {
//					"""
//					switch err {
//					case .call: err.triggerError("\(raw: cls_name) __init__ Error")
//					default: err.triggerError("hmmmmmm")
//					}
//					"""
//				} else {
//					"""
//					switch err {
//					case .call: err.triggerError("arg type Error")
//					default: err.triggerError("hmmmmmm")
//					}
//					"""
//				}
//			}
//			CatchClauseSyntax(catchItem("let other_error")) {
//				"other_error.anyErrorException()"
//			}
//	}}
    private var catchClauses: CatchClauseListSyntax {
        .standardPyCatchClauses
    }
	
	var handle_args_n_kwargs: CodeBlockItemListSyntax {
		
		return .init {
			for arg in args {
				let con_list = ConditionElementListSyntax {
					.init {
						SequenceExprSyntax(elements: .init {
							//IdentifierExpr(stringLiteral: "__nargs__")
							ExprSyntax(stringLiteral: "nargs")
							BinaryOperatorExprSyntax(operator: .rightAngleToken(leadingTrivia: .space))
							IntegerLiteralExprSyntax(integerLiteral: 0)
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
		//let _throws_ = __init__?.throws ?? false
		let _throws_ = false
		let cls_unretained = false
		//let unmanaged = IdentifierExpr(stringLiteral: "Unmanaged")
		let unmanaged = ExprSyntax(stringLiteral: "Unmanaged")
//		let _passRetained = MemberAccessExprSyntax(base: unmanaged, dot: .periodToken(), name: .identifier(cls_unretained ? "passUnretained" : "passRetained"))
        let _passRetained = MemberAccessExprSyntax(base: unmanaged, period: .periodToken(), name: .identifier(cls_unretained ? "passUnretained" : "passRetained"))
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
		
		let toOpaque = FunctionCallExprSyntax(callee: MemberAccessExprSyntax(
			base: pass,
			period: .periodToken(),
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
        let id = DeclReferenceExprSyntax(baseName: .identifier(cls_name))
		
        let tuple = LabeledExprListSyntax {
			//LabeledExprSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
			//let many = args.count > 1
			for arg in args {
				let arg_name = arg.optional_name ?? arg.name
				let label = arg.no_label ? nil : arg_name
				
				LabeledExprSyntax(label: label, expression: ExprSyntax(stringLiteral: arg_name))
//				if let _arg = arg as? ArgSyntax {
//					_arg.callTupleElement(many: many)
//				}
			}
			
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			arguments: tuple,
			rightParen: .rightParenToken()
		)
		return f_exp
		
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
	}
	
	func initPySwiftTargetThrows() -> TryExprSyntax {
        let id = DeclReferenceExprSyntax(baseName: .identifier(cls_name))
		
        let tuple = LabeledExprListSyntax {
			//LabeledExprSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
			for arg in args {
                LabeledExprSyntax(label: arg.name, expression: ExprSyntax(stringLiteral: arg.name))
			}
			
		}
		let f_exp = FunctionCallExprSyntax(
			calledExpression: id,
			leftParen: .leftParenToken(),
			arguments: tuple,
			rightParen: .rightParenToken()
		)
		return .init(expression: f_exp)
		
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
	}
    
    func initNewPySwiftClassThrows() -> TryExprSyntax {
        let id = DeclReferenceExprSyntax(baseName: .identifier(cls_name))
        
        let tuple = LabeledExprListSyntax {
            //LabeledExprSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
            //for arg in args {
                //LabeledExprSyntax(label: arg.label, expression: ExprSyntax(stringLiteral: arg.name))
                LabeledExprSyntax(label: "callback", expression: ExprSyntax(stringLiteral: "__arg__"))
            //}
            
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParenToken(),
            arguments: tuple,
            rightParen: .rightParenToken()
        )
        return .init(expression: f_exp)
        
        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
	
}



