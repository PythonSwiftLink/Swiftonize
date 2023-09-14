//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/09/2023.
//

import Foundation
import WrapContainers


public func buildWrapModule(name: String, code: String, swiftui: Bool = false) async -> WrapModule {
    await .init(fromAst: name, string: code, swiftui: swiftui)
}
