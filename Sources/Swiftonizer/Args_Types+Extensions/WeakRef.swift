import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper


extension PyWrap.WeakRefArg: ArgSyntax {
    public func callTupleElement(many: Bool) -> SwiftSyntax.LabeledExprSyntax {
        
        switch type.wrapped {
        case let other as PyWrap.OtherType:
            return .PyWeakref_GetObject(weak: self, many: many)
            
        default:
            return .PyWeakref_GetObject(weak: self, many: many)
        }
    }
    
    public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
        nil
    }
    
    
}

extension PyWrap.WeakRefType: ArgTypeSyntax {
    public var typeExpr: SwiftSyntax.TypeExprSyntax {
        .init(type: typeSyntax)
    }
    
    public var typeSyntax: SwiftSyntax.TypeSyntax {
        .init(OptionalTypeSyntax(wrappedType: (wrapped as! ArgTypeSyntax).typeSyntax))
    }
    
    public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
        .init(type: OptionalTypeSyntax(wrappedType: (wrapped as! ArgTypeSyntax).typeSyntax))
        
    }
    
    
}
