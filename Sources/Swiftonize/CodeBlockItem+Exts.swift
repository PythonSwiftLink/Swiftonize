//
//  File.swift
//  
//
//  Created by MusicMaker on 03/05/2023.
//

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax


extension CodeBlockItem {
    
    static func varGIL() -> Self { .init(item: .expr(.init(stringLiteral: "var gil: PyGILState_STATE?")))}
    static func checkGIL() -> Self { .init(item: .expr(.init(stringLiteral: "if PyGILState_Check() == 0 { gil = PyGILState_Ensure() }")))}
    static func releaseGIL() -> Self { .init(item: .expr(.init(stringLiteral: "if let gil = gil { PyGILState_Release(gil) }")))}
}

@resultBuilder
struct CodeBlockItemListFromStrings {
    static func buildBlock(_ components: String...) -> CodeBlockItemList {
        return .init {
            for comp in components {
                comp.codeBlockItem
            }
        }
    }
    
}

extension CodeBlockItemList {
    func withGIL(src: CodeBlockItemList) -> Self {
        .init {
            CodeBlockItem.varGIL()
            CodeBlockItem.checkGIL()
            src
            CodeBlockItem.releaseGIL()
        }
    }
    
    func withGIL(@CodeBlockItemListBuilder src: () -> CodeBlockItemList) -> Self {
        .init {
            CodeBlockItem.varGIL()
            CodeBlockItem.checkGIL()
            src()
            CodeBlockItem.releaseGIL()
        }
    }
    
    func withGIL(@CodeBlockItemListFromStrings builder: () -> CodeBlockItemList) -> Self {
        .init {
            CodeBlockItem.varGIL()
            CodeBlockItem.checkGIL()
            builder()
            CodeBlockItem.releaseGIL()
        }
    }
    
    
    
    func withGIL(src: [String]) -> Self {
        .init {
            CodeBlockItem.varGIL()
            CodeBlockItem.checkGIL()
            for s in src {
                s.codeBlockItem
            }
            CodeBlockItem.releaseGIL()
        }
    }
}
