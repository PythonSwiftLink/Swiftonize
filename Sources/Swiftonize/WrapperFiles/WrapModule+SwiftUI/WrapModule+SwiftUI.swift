//
//  File.swift
//  
//
//  Created by MusicMaker on 19/01/2023.
//

import Foundation



extension WrapModule {
    public var pyswiftui_code: String {
        
        """
        //
        // \(filename).swift
        //
        
        import Foundation
        \(swift_import_list.joined(separator: newLine))
        
        \(classes.map(\.swift_string).joined(separator: newLine))
        
        \(generateSwiftPythonObjectCallbackWrap)
        
        \(generatePyModule)
        """
    }
}


fileprivate extension WrapModule {
    
    
    var generatePyModule_SwiftUI: String {
        
        
        return """
        """
    }
}
