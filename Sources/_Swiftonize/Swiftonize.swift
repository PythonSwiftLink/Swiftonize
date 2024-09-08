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
import PySwiftCore
//public typealias CodeBlockItem = CodeBlockItemSyntax
//public typealias CodeBlockItemList = CodeBlockItemListSyntax
//public typealias GenericParameterSyntaxClauseSyntax = GenericParameterSyntaxClauseSyntax
//public typealias ParameterClause = ParameterClauseSyntax
//public typealias FunctionSignature = FunctionSignatureSyntax
//public typealias FunctionCallExprSyntax = FunctionCallExprSyntax
//public typealias ReturnClause = ReturnClauseSyntax
//public typealias SequenceExpr = SequenceExprSyntax
//public typealias VariableDeclSyntax = VariableDeclSyntax
//public typealias IfConfigDecl = IfConfigDeclSyntax
//public typealias SimpleTypeIdentifier = IdentifierTypeSyntax
//public typealias GenericParameterSyntax = GenericParameterSyntax

public func buildWrapModule(name: String, code: String, swiftui: Bool = false) async throws -> WrapModule {
    await try .init(fromAst: name, string: code, swiftui: swiftui)
}
