//
//  File.swift
//
//
//  Created by CodeBuilder on 13/09/2023.
//

import Foundation
import SwiftSyntax
import WrapContainers
import SwiftSyntaxBuilder

public protocol WrapArgSyntax {
    var typeExpr: TypeExpr { get }
    
    var typeSyntax: TypeSyntax { get }
    
    var typeAnnotation: TypeAnnotation { get }
    
    func callTupleElement(many: Bool) -> TupleExprElement
    
    func extractDecl(many: Bool) -> VariableDecl?
}



extension intArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
    
    public var typeExpr: TypeExpr { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotation { type.annotation }
    
    public func callTupleElement(many: Bool) -> TupleExprElement {
        return .pyCast(arg: self, many: many)
    }
    
    public func extractDecl(many: Bool) -> VariableDecl? {
        nil
    }
}

extension boolArg: WrapArgSyntax {
    public var typeAnnotation: TypeAnnotation { type.annotation }
        
        public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExpr { .init(type: typeSyntax) }
        
    public func callTupleElement(many: Bool) -> TupleExprElement {
            return .pyCast(arg: self, many: many)
        }
    public func extractDecl(many: Bool) -> VariableDecl? {
            nil
        }
}

extension dataArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExpr { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotation { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElement {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDecl? {
            nil
        }
}

extension floatArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExpr { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotation { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElement {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDecl? {
            nil
        }
}

extension strArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExpr { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotation { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElement {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDecl? {
            nil
        }
}

extension objectArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
    
    public var typeExpr: TypeExpr { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotation { type.annotation }
    
    public func callTupleElement(many: Bool) -> TupleExprElement {
        return .init(label: label, expression: .init(stringLiteral: many ? "_args_[\(idx)]!" : name))
    }
    
    public func extractDecl(many: Bool) -> VariableDecl? {
        nil
    }
}

extension otherArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { .init(stringLiteral: other_type ?? "wrongType" ) }
    
    public var typeExpr: TypeExpr { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotation { .init(type: typeSyntax) }
    
    public func callTupleElement(many: Bool) -> TupleExprElement {
        return .pyUnpack(with: self, many: many)
    }
    
    public func extractDecl(many: Bool) -> VariableDecl? {
        nil
    }
}


extension optionalArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { .init( OptionalTypeSyntax(wrappedType: (wrapped as! WrapArgSyntax).typeSyntax) ) }
    
    public var typeExpr: TypeExpr { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotation { .init(type: typeSyntax) }
    
    public func callTupleElement(many: Bool) -> TupleExprElement {
        
        switch wrapped {
        case let other as otherArg:
            //return .pyUnpack(with: other, many: many)
            return .init(
                label: label,
                expression: .init(TryExpr.unPackPyPointer(with: other, many: many) as TryExpr)
            )
        case let collection as collectionArg:
            var collect = collection.callTupleElement(many: many)
            if no_label {
                collect.label = nil
                collect.colon = nil
            }
            return collect
        case let callable as callableArg:
            var _arg: String {
                if many { return "_\(name)"}
                return name
            }
            let opt_call = SequenceExpr {
                MemberAccessExpr(base: IdentifierExpr(stringLiteral: _arg), dot: .period, name: .identifier("isNone"),trailingTrivia: .space)
                UnresolvedTernaryExpr(firstChoice: NilLiteralExpr(leadingTrivia: .space, nilKeyword: .nil, trailingTrivia: .space))
                callable.exprSyntax
            }
            return .init(label: label, expression: .init(opt_call))
        default: return .optionalPyCast(arg: wrapped, many: many)
        }
    }
    
    public func extractDecl(many: Bool) -> VariableDecl? {
        (wrapped as! WrapArgSyntax).extractDecl(many: many)
    }
}


extension collectionArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { .init(fromProtocol: ArrayTypeSyntax(elementType: (element as! WrapArgSyntax).typeSyntax)) }
    public var typeAnnotation: TypeAnnotation { .init(type: typeSyntax) }
    
    public var typeExpr: TypeExpr { .init(type: typeSyntax) }
    
    public func callTupleElement(many: Bool) -> TupleExprElement {
        switch element {
        case let other as otherArg:
            return .init(
                label: label,
                expression: .init(TryExprSyntax.unPackPyPointer(with: other, many: many) as TryExpr)
            )
            
        default: return .init(
            label: label,
            expression: .init(TryExprSyntax.pyCast(arg: element, many: many))
        )
        }
    }
    
    public func extractDecl(many: Bool) -> VariableDecl? {
        nil
    }
}


extension callableArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax {
        
        let args: TupleTypeElementListSyntax = .init {
            for arg in callArgs {
                TupleTypeElementSyntax(type: (arg as! WrapArgSyntax).typeSyntax)
            }
        }
        
        var r: TypeSyntaxProtocol
        if let _return = _return {
            r = (_return as! WrapArgSyntax).typeSyntax
        } else {
            r = SimpleTypeIdentifierSyntax(stringLiteral: "Void")
        }
        let t = FunctionTypeSyntax(
            leftParen: .leftParen,
            arguments: args,
            rightParen: .rightParen,
            returnType: r
        )
        
        return .init(t)
    }
    
    public var typeExpr: TypeExpr {
        .init(type: typeSyntax)
        
    }
    
    public var typeAnnotation: TypeAnnotation { type.annotation }
    
    var exprSyntax: ExprSyntax {
        .init(stringLiteral: PythonCall(
            callable: name,
            args: callArgs,
            rtn: _return!).closureDecl
            .formatted().description)
    }
    
    public func callTupleElement(many: Bool) -> TupleExprElement {
        return .init(
            label: label,
            expression: exprSyntax
        )
    }
    
    public func extractDecl(many: Bool) -> VariableDecl? {
        if many {
            return .init(stringLiteral: "let _\(name) = _args_[\(idx)]!")
        }
        return .init(stringLiteral: "let _\(name) = \(name)")
    }
}


extension objectStrEnumArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExpr { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotation { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElement {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDecl? {
            nil
        }
}

extension jsonDataArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExpr { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotation { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElement {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDecl? {
            nil
        }
}

extension intEnumArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExpr { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotation { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElement {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDecl? {
            nil
        }
}
