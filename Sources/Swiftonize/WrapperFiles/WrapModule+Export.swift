//
//  WrapModule+Export.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 13/03/2022.
//

import Foundation


extension WrapModule {
    
    
    
    public var pySwiftCode: String {
        
        """
        //
        // \(filename).swift
        //
        
        import Foundation
        \(if: swiftui_mode, """
        import PythonSwiftCore
        import PythonLib
        """)
        
        \(swift_import_list.joined(separator: newLine))
        
        \(classes.map(\.swift_string).joined(separator: newLine))

        \(if: false, generateSwiftPythonObjectCallbackWrap)
        
        \(generatePyModule)
        """
    }
    
    
     
    
    
}





