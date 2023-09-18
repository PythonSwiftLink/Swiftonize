//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/09/2023.
//

import Foundation
import WrapContainers
import SwiftSyntaxBuilder
import SwiftSyntax

//public typealias CodeBlockItem = CodeBlockItemSyntax
//public typealias CodeBlockItemList = CodeBlockItemListSyntax
//public typealias GenericParameterClause = GenericParameterClauseSyntax
//public typealias ParameterClause = ParameterClauseSyntax
//public typealias FunctionSignature = FunctionSignatureSyntax
//public typealias FunctionCallExpr = FunctionCallExprSyntax
//public typealias ReturnClause = ReturnClauseSyntax
//public typealias SequenceExpr = SequenceExprSyntax
//public typealias VariableDecl = VariableDeclSyntax
//public typealias IfConfigDecl = IfConfigDeclSyntax
//public typealias SimpleTypeIdentifier = IdentifierTypeSyntax
//public typealias GenericParameter = GenericParameterSyntax

public func buildWrapModule(name: String, code: String, swiftui: Bool = false) async -> WrapModule {
    await .init(fromAst: name, string: code, swiftui: swiftui)
}
