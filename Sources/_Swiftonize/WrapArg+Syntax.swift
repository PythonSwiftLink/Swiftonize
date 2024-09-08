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
    var typeExpr: TypeExprSyntax { get }
    
    var typeSyntax: TypeSyntax { get }
    
    var typeAnnotation: TypeAnnotationSyntax { get }
    
    func callTupleElement(many: Bool) -> TupleExprElementSyntax
    
    func extractDecl(many: Bool) -> VariableDeclSyntax?
}



extension intArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
    
    public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
    
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
        return .pyCast(arg: self, many: many)
    }
    
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
        nil
    }
}

extension boolArg: WrapArgSyntax {
    public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
        
        public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
        
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
            return .pyCast(arg: self, many: many)
        }
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
            nil
        }
}

extension dataArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
            nil
        }
}

extension floatArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
            nil
        }
}

extension strArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
            nil
        }
}

extension objectArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
    
    public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
    
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
        return .init(label: label, expression: ExprSyntax(stringLiteral: many ? "_args_[\(idx)]!" : name))
    }
    
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
        nil
    }
}

extension otherArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { .init(stringLiteral: other_type ?? "wrongType" ) }
    
    public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotationSyntax { .init(type: typeSyntax) }
    
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
        return .pyUnpack(with: self, many: many)
    }
    
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
        nil
    }
}


extension optionalArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { .init( OptionalTypeSyntax(wrappedType: (wrapped as! WrapArgSyntax).typeSyntax) ) }
    
    public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
    
    public var typeAnnotation: TypeAnnotationSyntax { .init(type: typeSyntax) }
    
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
        
        switch wrapped {
        case let other as otherArg:
            //return .pyUnpack(with: other, many: many)
            return .init(
                label: label,
                expression: TryExprSyntax.unPackPyPointer(with: other, many: many) as TryExprSyntax
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
            let opt_call = SequenceExprSyntax {
                MemberAccessExprSyntax(base: ExprSyntax(stringLiteral: _arg), dot: .periodToken(), name: .identifier("isNone"),trailingTrivia: .space)
				UnresolvedTernaryExprSyntax(firstChoice: NilLiteralExprSyntax(leadingTrivia: .space, trailingTrivia: .space))
                callable.exprSyntax
            }
            return .init(label: label, expression: opt_call)
        default: return .optionalPyCast(arg: wrapped, many: many)
        }
    }
    
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
        (wrapped as! WrapArgSyntax).extractDecl(many: many)
    }
}


extension collectionArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { .init(fromProtocol: ArrayTypeSyntax(elementType: (element as! WrapArgSyntax).typeSyntax)) }
    public var typeAnnotation: TypeAnnotationSyntax { .init(type: typeSyntax) }
    
    public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
    
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
        switch element {
        case let other as otherArg:
            return .init(
                label: label,
                expression: TryExprSyntax.unPackPyPointer(with: other, many: many) as TryExprSyntax
            )
            
        default: return .init(
            label: label,
            expression: TryExprSyntax.pyCast(arg: element, many: many) as TryExprSyntax
        )
        }
    }
    
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
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
            r = TypeSyntax(stringLiteral: "Void")//SimpleTypeIdentifierSyntax(stringLiteral: "Void")
        }
		
		let t = FunctionTypeSyntax(parameters: args, returnClause: .init(type: r))
//        let t = FunctionTypeSyntax(
//            leftParen: .leftParenToken(),
//            arguments: args,
//            rightParen: .rightParenToken(),
//            returnType: r
//        )
        
        return .init(t)
    }
    
    public var typeExpr: TypeExprSyntax {
        .init(type: typeSyntax)
        
    }
    
    public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
    
    var exprSyntax: ExprSyntax {
        .init(stringLiteral: PythonCall(
            callable: name,
            args: callArgs,
            rtn: _return!).closureDecl
            .formatted().description)
    }
    
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
        return .init(
            label: label,
            expression: exprSyntax
        )
    }
    
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
        if many {
            //return .init(stringLiteral: "let _\(name) = _args_[\(idx)]!")
			return DeclSyntax(stringLiteral: "let _\(name) = _args_[\(idx)]!").as(VariableDeclSyntax.self)
        }
        //return .init(stringLiteral: "let _\(name) = \(name)")
		return DeclSyntax(stringLiteral: "let _\(name) = \(name)").as(VariableDeclSyntax.self)
    }
}


extension objectStrEnumArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
            nil
        }
}

extension jsonDataArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
            nil
        }
}

extension intEnumArg: WrapArgSyntax {
    public var typeSyntax: TypeSyntax { type.syntaxType }
        
        public var typeExpr: TypeExprSyntax { .init(type: typeSyntax) }
        
        public var typeAnnotation: TypeAnnotationSyntax { type.annotation }
        
    public func callTupleElement(many: Bool) -> TupleExprElementSyntax {
            return .pyCast(arg: self, many: many)
        }
        
    public func extractDecl(many: Bool) -> VariableDeclSyntax? {
            nil
        }
}
