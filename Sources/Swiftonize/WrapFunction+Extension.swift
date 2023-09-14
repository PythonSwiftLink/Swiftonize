//
//  WrapFunction+Extension.swift
//  PythonSwiftLink
//
//  Created by MusicMaker on 26/12/2022.
//  Copyright © 2022 Example Corporation. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

import WrapContainers

extension WrapArgProtocol {
    
    var _typeSyntax: TypeSyntax { (self as! WrapArgSyntax).typeSyntax }
    
    var functionParameter: FunctionParameterSyntax {
        var secondName: TokenSyntax? {
//            if options.contains(.) {
//                return .init(.identifier("_"))?.withTrailingTrivia(.space)
//            }
            if let optional_name = optional_name {
                return .init(.identifier(optional_name))?.withTrailingTrivia(.space)
            }
            return nil
        }
        if no_label {
            return .init(
                firstName: .identifier("_ "),
                secondName: .identifier(name),
                colon: .colon,
                type: _typeSyntax
            )
        }
        return .init(
            firstName: secondName,
            secondName: .identifier(name),
            colon: .colon,
            type: _typeSyntax
        )
        
//        var arg_string: String {
//            if let extract = self as? PyCallbackExtactable {
//                return extract.function_arg
//            }
//            if options.contains(.alias) {
//                return "\(optional_name ?? "") \(swift_callback_func_arg)"
//            }
//            return swift_callback_func_arg
//        }
//        return arg_string.functionParameter
    }
//    var typeSyntax: TypeSyntaxProtocol {
//        
//        switch self {
//        case let array as collectionArg:
//            return ArrayType(stringLiteral: array.__argType__)
//        default:
//            return SimpleTypeIdentifier(stringLiteral: __argType__ )
//        }
//        
//    }
    
    
}



public extension WrapFunction {
    
    var pyReturnStmt: ReturnStmtSyntax {
        switch _return_.type {
        case .None, .void:
            return .init(expression: MemberAccessExprSyntax(name: "PyNone"))
        case .object:
            return .init(expression: IdentifierExpr(stringLiteral: "\(name)_result"))
        default:
            return .init(expression: MemberAccessExprSyntax(base: .init(stringLiteral: "\(name)_result"), name: "pyPointer"))
        }
        
    }
    
    var returnClause: ReturnClauseSyntax? {
        switch _return_.type {
        case .None, .void:
            return nil
        default:
            return ReturnClause(arrow: .arrow, returnType: (_return_ as! WrapArgSyntax).typeSyntax)
        }
    }
    
    var signature: FunctionSignatureSyntax {
        .init(input: _args_.parameterClause, output: returnClause)
    }
    
    var csignature: ClosureSignature {
        //.init(input: _args_.parameterClause, output: returnClause)
        .init(input: .input(_args_.parameterClause), output: returnClause, inTok: .in)
    }
    
    var function_header: FunctionDeclSyntax {
        .init(identifier: .identifier(call_target ?? name), signature: signature)
    }
    
    func withCodeLines(_ lines: [String]) -> FunctionDecl {
        var header = function_header
        header.body = lines.codeBlock
        return header
    }
    
    func withCodeLines(_ lines: [String]) -> ClosureExpr {
        var header = ClosureExpr(signature: csignature)
        header.statements = lines.codeBlockList
        return header
    }
    
    func withCodeLines(_ lines: [String]) -> String {
        var header = function_header
        header.body = lines.codeBlock
        return header.formatted().description
//        FunctionDeclSyntax(
//            identifier: .identifier(call_target ?? name),
//            signature: signature,
//            body: lines.codeBlock
//        ).formatted().description
    }
    
    
    
    
    
}
