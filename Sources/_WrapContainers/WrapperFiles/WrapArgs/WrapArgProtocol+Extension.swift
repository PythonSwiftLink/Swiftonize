//
//  File.swift
//  
//
//  Created by MusicMaker on 29/04/2023.
//

import Foundation
import SwiftSyntax


public extension WrapArgProtocol {
    
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
    
    var no_label: Bool {
        options.contains(.no_label)
    }
}

public extension _WrapArg {
    
    func setIndex(_ idx: Int) {
        _idx = idx
    }
    
}
