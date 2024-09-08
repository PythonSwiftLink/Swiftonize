//
//  File.swift
//  
//
//  Created by CodeBuilder on 12/02/2024.
//

import Foundation
import SwiftSyntax



extension DeclModifierListSyntax.Element {
	static var `static`: Self { .init(name: .keyword(.static)) }
	static var `fileprivate`: Self { .init(name: .keyword(.fileprivate)) }
	static var `public`: Self { .init(name: .keyword(.public)) }
}

