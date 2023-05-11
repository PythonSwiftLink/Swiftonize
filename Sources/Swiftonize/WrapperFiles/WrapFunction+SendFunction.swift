//
//  File.swift
//  
//
//  Created by MusicMaker on 27/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftParser




class PySwiftFunction {
    
    let _function: WrapFunction?
    var function: WrapFunction { _function! }
    //var guard_line: String = ""
    var code: [String] = []
    var args: [WrapArgProtocol] { function._args_ }
    var arg_count: Int { args.count }
    
    init(function: WrapFunction) {
        self._function = function
//        if function._args_.count > 1 {
//            guard_line = "guard nargs > 1, let _args_ = _args_, let s = s else { throw PythonError.call }"
//        } else if function._args_.count == 1 {
//            let arg = function._args_.first!
//            guard_line = "guard let \(arg.name) = \(arg.name), let s = s else { throw PythonError.call }"
//        }
    }
    
    required init?<S>(_ node: S) where S : SyntaxProtocol {
        self._function = nil
    }
    
    //private var codeBlock: CodeBlockSyntax { ([guard_line] + code).codeBlock }
    
    private func catchItem(_ label: String) -> CatchItemListSyntax {
        .init(
            arrayLiteral: .init(pattern: IdentifierPatternSyntax(identifier: .identifier(label)))
        )
    }
    
    private var catchClauseList: CatchClauseListSyntax {
        
        .init {
            CatchClauseSyntax(catchItem("let err as PythonError")) {
                if arg_count > 1 {
                    #"""
                    switch err {
                    case .call: err.triggerError("wanted 2 got \(nargs)")
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
    private var _guard: GuardStmtSyntax {
        let conditions = ConditionElementListSyntax {
            let arg_count = function._args_.count
            if arg_count > 1 {
                countCompare("nargs", " == ", arg_count)
                "_args_".optionalGuardUnwrap
            } else {
                for arg in function._args_.argConditions {
                    arg
                }
            }
            if function.wrap_class != nil {
                "_self_".optionalGuardUnwrap
            }
        }
        return .init(
            conditions: conditions,
            elseKeyword: .elseKeyword(leadingTrivia: .space),
            body: .init(statements: .init([
            .init(item: .init(ThrowStmtSyntax(stringLiteral: "throw PythonError.call")) )
        ])))
    }
    private var completionHandlers: ExprSyntax {
        
        
       
        
        .init(stringLiteral: "")
    }
    private var extracts: [CodeBlockItemSyntax] {
        let many = arg_count > 1
        return args.compactMap { arg in
            switch arg {
            case let call as callableArg:
                if many {
                    return .init(
                        item: .decl(.init(stringLiteral: "let _\(call.name) = _args_[\(call.idx)]!"))
                    )
                }
                return .init(
                    item: .decl(.init(stringLiteral: "let _\(call.name) = \(call.name)"))
                )
            default: return nil
            }
        }
    }
    
    private var functionCode: CodeBlockItemListSyntax {
        .init {
            for extract in extracts {
                extract
            }
            switch function._return_.type {
            case .void, .None:
                function.pyCall
            default:
                function.pyCallReturn
            }
            
            function.pyReturnStmt.withTrailingTrivia(.newline)
        }
    }
    
    private var doCatch: DoStmtSyntax {
        var do_stmt = DoStmtSyntax {
            CodeBlockItemListSyntax {
                
                _guard.codeBlockItem.withTrailingTrivia(.newline)
                functionCode
                
            }
            //.withLeadingTrivia(.newline)
        }
        do_stmt.catchClauses = catchClauseList
        return do_stmt
    }
    
    private var calledExpr: MemberAccessExprSyntax {
        .init(stringLiteral: ".init")
    }
    
    private var  pyCallType: TupleExprElementListSyntax {
        
        .init {
            switch function._args_.count {
            case 1: "_oneArg".tuplePExprElement(function.name)
            case 2...: "_withArgs".tuplePExprElement(function.name)
            default: "_noArgs".tuplePExprElement(function.name)
            }
        }
    }
    
    private var signature: ClosureSignatureSyntax {
        var args = [function.wrap_class == nil ? "_" : "_self_"]
        switch function._args_.count {
        case 1:
            if let arg = function._args_.first {
                args.append(arg.name)
            }
        case 2...:
            args.append("_args_")
            args.append("nargs")
        default: args.append("_")
        }
        return args.closureSignature
    }
    
    var functionCallExpr: FunctionCallExprSyntax {
        
        var f = FunctionCallExprSyntax(
            calledExpression: calledExpr,
            leftParen: .leftParen,
            argumentList: pyCallType,
            rightParen: .rightParen
        )

        f.trailingClosure = .init(signature: signature.withTrailingTrivia(.newline)) {
            if function.wrap_class != nil || args.count > 0 {
                doCatch.withTrailingTrivia(.newline)
                ReturnStmtSyntax(stringLiteral: "return nil")
            } else {
                functionCode.withTrailingTrivia(.newline)
            }
            
           
        }

        return f
    }
    
    var functionDecl: FunctionDeclSyntax {
        
        let f = FunctionDeclSyntax(identifier: .identifier(function.name), signature: function.signature) {
            doCatch
        }
        return f
    }
    
    var globalFunction: FunctionDeclSyntax {
        let f = FunctionDeclSyntax(identifier: .identifier(function.name), signature: function.signature) {
            doCatch
        }
        return f
    }
    
    var string: String {
        functionDecl.formatted().description
    }
    
    
    
}
extension PySwiftFunction: WithStatementsSyntax {
    var statements: SwiftSyntax.CodeBlockItemListSyntax {
        .init {
            functionCallExpr
        }
    }
    
    func withStatements(_ newChild: SwiftSyntax.CodeBlockItemListSyntax?) -> Self {
        self
    }
    
    var _syntaxNode: SwiftSyntax.Syntax {
        fatalError()
    }
    
    static var structure: SwiftSyntax.SyntaxNodeStructure {
        .choices([])
    }
    
    func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
        nil
    }
    
    
}
