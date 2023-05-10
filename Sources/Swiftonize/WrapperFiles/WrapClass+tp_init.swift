//
//  File.swift
//  
//
//  Created by MusicMaker on 05/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder


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
    var __init__: WrapFunction { cls.init_function! }
    
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
    
    var code: CodeBlockItemList {

        return .init {
            
            DoStmt(catchClauses: catchClauseList) {
                initVars
                nkwargs
                CodeBlockItemSyntax.if_nkwargs(args: args) {
                    //else
                    nargs
                    GuardStmt.nargs_kwargs(args.count)
                    handle_args_n_kwargs
                    //__init__.pyCall
                    
                }
                setPointer()
                //Expr(stringLiteral: #"print("setted pointer - \#(cls.title)", PySwiftObject_Cast(__self__).pointee.swift_ptr)"#)
            }
            //ReturnStmtSyntax(stringLiteral: "return -1")
        }
    }
    
    
    
    var nkwargs: VariableDecl {
        return .init(stringLiteral: """
        let nkwargs = (kw == nil) ? 0 : _PyDict_GET_SIZE(kw)
        """)
    }
    
    var nargs: VariableDecl {
        return .init(stringLiteral: """
        let nargs = _PyTuple_GET_SIZE(_args_)
        """)
    }
    
    var initVars: CodeBlockItemList {
        
        
        return .init {
            for arg in args {
                VariableDecl(
                    .let,
                    name: IdentifierPattern(stringLiteral: arg.name),
                    type: arg.typeAnnotation
                )
            }
        }
    }
    
    var handle_args_n_kwargs: CodeBlockItemList {
        
        return .init {
            for arg in args {
                let con_list = ConditionElementList {
                    .init {
                        SequenceExpr(elements: .init {
                            IdentifierExpr(stringLiteral: "nargs")
                            BinaryOperatorExpr(operatorToken: .rightAngle)
                            IntegerLiteralExpr(integerLiteral: arg.idx)
                        })
                    }
                }
                IfStmt(leadingTrivia: .newline, conditions: con_list) {
                    SequenceExpr(pyTuple: arg)
                } elseBody: {
                    SequenceExpr(pyDict: arg)
                    
                }

            }
        }
        
        
    }
    
    func setPointer() -> SequenceExprSyntax {
        let unmanaged = IdentifierExpr(stringLiteral: "Unmanaged")
        let _passRetained = MemberAccessExpr(base: unmanaged, dot: .period, name: .identifier("passRetained"))
        let passRetained = FunctionCallExpr(callee: _passRetained) {
            .init(expression: initPySwiftTarget().withLeadingTrivia(.newline))
        }.withRightParen(.rightParen.withLeadingTrivia(.newline))
        let toOpaque = FunctionCallExpr(callee: MemberAccessExpr(
            base: passRetained,
            dot: .period,
            name: .identifier("toOpaque")
        ))
        
        
        return .init {
            Expr(stringLiteral: "PySwiftObject_Cast(__self__).pointee.swift_ptr")
            AssignmentExpr()
            toOpaque
        }
    }
    
    func initPySwiftTarget() -> FunctionCallExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier(cls.title))
        
        let tuple = TupleExprElementList {
            //TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
            for arg in args {
                TupleExprElementSyntax(label: arg.label, expression: .init(stringLiteral: arg.name))
            }
            
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen
        )
        return f_exp
        
        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    
}

extension SequenceExpr {
    
    init(pyDict arg: WrapArgProtocol) {
        self.init(elements: .init(itemsBuilder: {
            IdentifierExpr(stringLiteral: arg.name)
            AssignmentExpr()
            TryExpr.pyDict_GetItem("kw", arg.name)
        }))
    }
    
    init(pyTuple arg: WrapArgProtocol) {
        self.init(elements: .init(itemsBuilder: {
            IdentifierExpr(stringLiteral: arg.name)
            AssignmentExpr()
            TryExpr.pyTuple_GetItem("_args_", arg.idx)
        }))
    }
}

fileprivate extension CodeBlockItemList {
    static func handleKWArgs(_ args: [WrapArgProtocol]) -> Self {
        
        return .init {
            for arg in args {
                SequenceExpr(elements: .init(itemsBuilder: {
                    IdentifierExpr(stringLiteral: arg.name)
                    AssignmentExpr()
                    TryExpr.pyDict_GetItem("kw", arg.name)
                }))
            }
        }
    }
    static func handleArgs(_ args: [WrapArgProtocol]) -> Self {
        
        return .init {
            for arg in args {
                SequenceExpr(elements: .init(itemsBuilder: {
                    IdentifierExpr(stringLiteral: arg.name)
                    AssignmentExpr()
                    TryExpr.pyDict_GetItem("kw", arg.name)
                }))
            }
        }
    }
}

extension CodeBlockItemSyntax {
    static var nkwargs: Self {
        .init(item: .init(VariableDecl(stringLiteral: """
        let nkwargs = (kw == nil) ? 0 : _PyDict_GET_SIZE(kw)
        """)))
    }
    static func if_nkwargs(args: [WrapArgProtocol],  @CodeBlockItemListBuilder elseCode: () -> CodeBlockItemList) -> Self {
        let if_con = ConditionElementList {
            .init {
                SequenceExpr(stringLiteral: "nkwargs >= \(args.count)")
            }
        }
        
        let ifst = IfStmtSyntax(conditions: if_con) {
            CodeBlockItemList.handleKWArgs(args)
        } elseBody: {
            elseCode()
        }

        return .init(item: .init(ifst))
    }
    
//    static func _handleKWArgs(_ args: [WrapArgProtocol]) -> Self {
//        let blocklist = CodeBlockItemList {
//
//        }
//        return CodeBlockItemSyntax(item: .stmt(.init(fromProtocol: blocklist)) )
//        //return SyntaxFactory.makeCodeBlockItem(item: .init(blocklist) , semicolon: nil, errorTokens: nil)
//    }
    
    static func handleKWArgs(_ args: [WrapArgProtocol]) -> Self {
        let clist = ConditionElementList {
            for arg in args {
                OptionalBindingConditionSyntax(
                    letOrVarKeyword: .let,
                    pattern: IdentifierPattern(stringLiteral: "_\(arg.name)"),
                    initializer: InitializerClause(value: FunctionCallExprSyntax(
                        callee: IdentifierExpr(stringLiteral: "PyDict_GetItem"), argumentList: {
                            TupleExprElement.pyDictElement(key: "kw", type: .label)
                            TupleExprElement.pyDictElement(key: arg.name, type: .string)
                        })
                    )
                    
                ).withLeadingTrivia(.newline + .tab)
            }
        }.withTrailingTrivia(.newline)
   
        
        let gstmt = GuardStmt(conditions: clist, body: .init(statementsBuilder: {
            FunctionCallExprSyntax.pyErr_SetString("Args missing needed \(args.count)")
            ReturnStmtSyntax(stringLiteral: "return -1")
        }))
        
        
        return gstmt.codeBlockItem
    }
}


fileprivate extension GuardStmt {
    static func nargs_kwargs(_ n: Int) -> Self {
        
        return .init("guard nkwargs + nargs >= \(n) else") {
            FunctionCallExprSyntax.pyErr_SetString("Args missing needed \(n)")
            ReturnStmtSyntax(stringLiteral: "return -1")
        }
    }
}



extension TupleExprElement {
    enum pyDictElementType {
        case string
        case int
        case label
    }
    
    static func pyDictElement(key: String, type: pyDictElementType) -> Self {
        
        switch type {
        case .label:
            return .init(expression: .init(stringLiteral: key))
        case .int:
            return .init(expression: .init(stringLiteral: key))
        case .string:
            return .init(expression: StringLiteralExprSyntax(stringLiteral: #""\#(key)""#))
        }
    }
}


fileprivate extension TupleExprElementListSyntax {
    
    static func PyDict_GetItem(o: String, key: String) -> Self {
        return .init {
            TupleExprElement.pyDictElement(key: o, type: .label)
            TupleExprElement.pyDictElement(key: key, type: .string)
        }
    }
    
}

fileprivate extension FunctionCallExprSyntax {
    
    static func pyErr_SetString(_ string: String) -> Self {
        
        
        return .init(callee: IdentifierExpr(unicodeScalarLiteral: "PyErr_SetString") ) {
            TupleExprElement(expression: .init(stringLiteral: "PyExc_IndexError"))
            TupleExprElement(expression: StringLiteralExprSyntax(stringLiteral: #""\#(string)""#))
        }
    }
    
    static func pyDict_GetItem(_ o: String, _ key: String) -> Self {
        
        
        return .init(callee: IdentifierExpr(unicodeScalarLiteral: "PyDict_GetItem") ) {
            TupleExprElement(expression: .init(stringLiteral: o))
            TupleExprElement(expression: StringLiteralExprSyntax(stringLiteral: #""\#(key)""#))
        }
    }
    
    static func pyTuple_GetItem(_ o: String, _ key: Int) -> Self {
        
        
        return .init(callee: IdentifierExpr(unicodeScalarLiteral: "PyTuple_GetItem") ) {
            TupleExprElement(expression: .init(stringLiteral: o))
            TupleExprElement(expression: IntegerLiteralExpr(integerLiteral: key))
        }
    }
    
}

fileprivate extension TryExpr {
    
    static func pyDict_GetItem(_ o: String, _ key: String) -> Self {
        
        return .init(expression: FunctionCallExpr.pyDict_GetItem(o, key))
    }
    
    static func pyTuple_GetItem(_ o: String, _ key: Int) -> Self {
        
        return .init(expression: FunctionCallExpr.pyTuple_GetItem(o, key))
    }
}
