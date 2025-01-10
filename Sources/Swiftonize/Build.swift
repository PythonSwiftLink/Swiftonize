

import Foundation
import ArgumentParser
import Swiftonizer
import PyWrapper
import PathKit

//import PythonFiles
import PySwiftCore
import PyDictionary

extension Swiftonize {
    
    
    struct Build: AsyncParsableCommand {
        
        @Argument var source: Path
        @Argument var destination: Path
        @Option var site: Path?
        
        
        func run() async throws {
            
            try launchPython()
  
            let wrappers = try SourceFilter(root: source)
            
            for file in wrappers.sources {
                
                let src = switch file {
                case .pyi(let path):
                    path
                case .py(let path):
                    path
                case .both(_, let pyi):
                    pyi
                }
                
                try await build_wrapper(
                    src: src,
                    dst: file.swiftFile(destination)
                )
            }
            //}
        }
    }
    
    
    
}

func build_wrapper(src: Path, dst: Path, site: Path? = nil, beeware: Bool = true) async throws {
    
    let filename = src.lastComponentWithoutExtension
    let code = try src.read(.utf8)
    let module = try PyWrap.parse(filename: filename,string: code)
    let module_code = try module.file().formatted().description
    
    try dst.write(module_code)
    
}

