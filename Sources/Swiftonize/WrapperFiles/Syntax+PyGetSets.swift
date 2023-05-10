//
//  File.swift
//  
//
//  Created by MusicMaker on 01/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxParser

class PyGetSetProperty {
    
    weak var _property: WrapClassProperty?
    var property: WrapClassProperty { _property! }
    weak var _cls: WrapClass?
    var cls: WrapClass { _cls! }
    
    init(_property: WrapClassProperty? = nil, _cls: WrapClass? = nil) {
        self._property = _property
        self._cls = _cls
    }
    
    var getter: ClosureExprSyntax {
        let closure = ClosureExprSyntax(stringLiteral: "{s,clossure in }")
        var line = "UnPackPySwiftObject(with: s, as: \(cls.title).self).\(property.name)"
        if property.name == "delegate" && property.arg_type is optionalArg {
            line += " as? \(property.arg_type.swiftType)"
        }
        if property.name == "py_callback" {
            line += "?._pycall"
        }
        if property.arg_type is optionalArg || property.name == "py_callback" { line = "optionalPyPointer( \(line) )"}
        else { line += ".pyPointer" }
        
        return closure.withStatements(.init {
            ExprSyntax(stringLiteral: line)
        })
    }
    
    
    var setter_assign: String {
        let arg_type = property.arg_type
        let name = property.name
            switch arg_type {
            case _ where name == "delegate":
                return  "try UnPackOptionalPyPointer(with: \(arg_type.swiftType)PyType.pytype, from: v, as: \(arg_type.swiftType).self)"
            case _ where name == "py_callback":
                return "\(cls.title)PyCallback(callback: v)"
            case _ as optionalArg:
                return "optionalPyCast(from: v)"
            default:
                return "try pyCast(from: v)"
            }
    }
    
    private var doCatch: DoStmtSyntax {
        func catchItem(_ label: String) -> CatchItemListSyntax {
            .init(
                arrayLiteral: .init(pattern: IdentifierPatternSyntax(identifier: .identifier(label)))
            )
        }
        var catchClauseList: CatchClauseListSyntax {
            
            .init {
                CatchClauseSyntax(catchItem("let err as PythonError")) {
            
                    #"""
                    switch err {
                    case .call: err.triggerError("type Error")
                    default: err.triggerError("hmmmmmm")
                    }
                    """#.codeBlockItem
                    
                }
                CatchClauseSyntax(catchItem("let other_error")) {
                    "other_error.pyExceptionError()".codeBlockItem
                }
                
            }
        }
        let line = "UnPackPySwiftObject(with: s, as: \(cls.title).self).\(property.name) = \(setter_assign)"
        let extra =  CodeBlockItemListSyntax {
            if property.name == "py_callback" {
                GuardStmtSyntax(stringLiteral: "guard let v = v else { throw PythonError.attribute }")
            }
            
        }
        var do_stmt = DoStmtSyntax {
            CodeBlockItemListSyntax {
                extra
                ExprSyntax(stringLiteral: line)
                ReturnStmtSyntax(stringLiteral: "return 0")
            }//.withLeadingTrivia(.newline)
        }
        do_stmt.catchClauses = catchClauseList
        return do_stmt
    }
    
    var setter: ClosureExprSyntax {
        let closure = ClosureExprSyntax(stringLiteral: "{ s, v, clossure in }")
        let line = "UnPackPySwiftObject(with: s, as: \(cls.title).self).\(property.name) = \(setter_assign)"
        
//        if property.arg_type is optionalArg { line += "optionalPyCast(from: v)"}
//        else { line += "try pyCast(from: v)" }
        
        
        return closure.withStatements(.init {
            doCatch
            ReturnStmtSyntax(stringLiteral: "return 1")
        })
    }
    
    var callExpr: FunctionCallExprSyntax {
        let exp = IdentifierExprSyntax(stringLiteral: "PyGetSetDefWrap")
        return .init(
            calledExpression: exp,
            leftParen: .leftParen.withTrailingTrivia(.newline ),
            argumentList: .init {
                TupleExprElementSyntax(
                    label: "pySwift",
                    expression: .init( StringLiteralExprSyntax(content: property.name ) )
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "getter",
                    expression: .init( getter )
                ).withLeadingTrivia(.newline)
                if property.property_type == .GetSet {
                    TupleExprElementSyntax(
                        label: "setter",
                        expression: .init( setter ) 
                    ).withLeadingTrivia(.newline)
                }
            },
            rightParen: .rightParen.withLeadingTrivia(.newline)
        )
        
    }
    
    
}
