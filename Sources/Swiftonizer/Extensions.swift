//
//  Extensions.swift
//  Swiftonize
//
//  Created by CodeBuilder on 07/03/2025.
//

import SwiftSyntax

extension AttributeSyntax {
    static var dynamicMemberLookup: Self {
        .init(stringLiteral: "@dynamicMemberLookup")
    }
}

extension AttributeListSyntax.Element {
    static var dynamicMemberLookup: Self {
        .attribute(.dynamicMemberLookup)
    }
}

extension TypeSyntax {
    static var T: Self { .init(stringLiteral: "T")}
    static var R: Self { .init(stringLiteral: "R")}
    static var String: Self { .init(stringLiteral: "String")}
}

extension TypeSyntaxProtocol where Self == TypeSyntax{
    static var T: Self { .T }
    static var R: Self { .R }
    static var String: Self { .String }
}


extension ReturnClauseSyntax {
    static var T: Self { .init(type: .T) }
    static var R: Self { .init(type: .R) }
}

extension MemberAccessExprSyntax {
    static func typeSelf(type: String) -> Self {
        .init(base: ExprSyntax(stringLiteral: type), name: .identifier("self"))
    }
}

extension ExprSyntaxProtocol where Self == MemberAccessExprSyntax {
    static func typeSelf(type: String) -> Self {
        MemberAccessExprSyntax.typeSelf(type: type)
    }
}
