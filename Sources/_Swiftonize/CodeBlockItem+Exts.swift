//
//  File.swift
//  
//
//  Created by MusicMaker on 03/05/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax


extension CodeBlockItemSyntax {
    
    static func varGIL() -> Self { .init(item: .expr(.init(stringLiteral: "var gil: PyGILState_STATE?")))}
    static func checkGIL() -> Self { .init(item: .expr(.init(stringLiteral: "if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }")))}
    static func releaseGIL() -> Self { .init(item: .expr(.init(stringLiteral: "if let gil = gil { PyGILState_Release(gil) }")))}
}

@resultBuilder
struct CodeBlockItemListFromStrings {
    static func buildBlock(_ components: String...) -> CodeBlockItemListSyntax {
        return .init {
            for comp in components {
                comp.codeBlockItem
            }
        }
    }
    
}

extension CodeBlockItemListSyntax {
    func withGIL(src: CodeBlockItemListSyntax) -> Self {
        .init {
			CodeBlockItemSyntax.varGIL()
            CodeBlockItemSyntax.checkGIL()
            src
            CodeBlockItemSyntax.releaseGIL()
        }
    }
    
    func withGIL(@CodeBlockItemListBuilder src: () -> CodeBlockItemListSyntax) -> Self {
        .init {
            CodeBlockItemSyntax.varGIL()
            CodeBlockItemSyntax.checkGIL()
            src()
            CodeBlockItemSyntax.releaseGIL()
        }
    }
    
    func withGIL(@CodeBlockItemListFromStrings builder: () -> CodeBlockItemListSyntax) -> Self {
        .init {
            CodeBlockItemSyntax.varGIL()
            CodeBlockItemSyntax.checkGIL()
            builder()
            CodeBlockItemSyntax.releaseGIL()
        }
    }
    
    
    
    func withGIL(src: [String]) -> Self {
        .init {
            CodeBlockItemSyntax.varGIL()
            CodeBlockItemSyntax.checkGIL()
            for s in src {
                s.codeBlockItem
            }
            CodeBlockItemSyntax.releaseGIL()
        }
    }
}
