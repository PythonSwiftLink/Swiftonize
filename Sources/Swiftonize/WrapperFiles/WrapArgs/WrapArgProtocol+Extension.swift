//
//  File.swift
//  
//
//  Created by MusicMaker on 29/04/2023.
//

import Foundation
import SwiftSyntax


extension WrapArgProtocol {
    
    var identifierSyntax: IdentifiedDeclSyntax {
        self as! IdentifiedDeclSyntax
    }
    
    var label: String? {
        if options.contains(.no_label) {
            return nil
        }
        if let optional = optional_name {
            return optional
        }
        return name
    }
    
    var useLabel: Bool {
        !options.contains(.no_label)
    }
}
