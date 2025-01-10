//
//  SourceFilesFilter.swift
//  SwiftonizeCLI
//
//  Created by MusicMaker on 14/04/2023.
//

import Foundation
import PathKit

enum WrapSource {
    case pyi(path: Path)
    case py(path: Path)
    case both(py: Path, pyi: Path)
    
    private func swift_fn(_ path: Path) -> String {
        let name = path.lastComponentWithoutExtension
        return "_\(name).swift"
    }
    
    func swiftFile(_ dst: Path) -> Path {
        return switch self {
        case .pyi(let path):
            dst + swift_fn(path)
        case .py(let path):
            dst + swift_fn(path)
        case .both(_, let pyi):
            dst + swift_fn(pyi)
        }
    }
}

class SourceFilter {
    
    var sources: [WrapSource]
    
    init(root: Path) throws {
        
        let pyis = root.filter({$0.extension == "pyi"})
        var pys = root.filter({$0.extension == "py"})
        sources = []
        for src in pyis {
            let fname = src.lastComponentWithoutExtension
            if let py_index = pys.firstIndex(where: {$0.lastComponentWithoutExtension == fname}) {
                let py = pys[py_index]
                sources.append(.both(py: py, pyi: src))
                pys.remove(at: py_index)
                continue
            }
            sources.append(.pyi(path: src))
            
        }
        for src in pys {
            sources.append(.py(path: src))
        }
        
    }
    
    
}
