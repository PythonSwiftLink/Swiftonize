//
//  AutoDocGenerator.swift
//

import Foundation


func generateDocs(file: String, path: String) {
    
//    let wrap_py_path = KSLPaths.shared.WRAPPER_SOURCES.appendingPathComponent("\(file).py")
//    let PATH = URL(fileURLWithPath: path)
//    
//    let py_ast = PythonASTconverter(filename: file)
//    let wrap_module = py_ast.generateModule(root: wrap_py_path.path, pyi_mode: false)
//    
//    let extra = [
//        "\(if: wrap_module.custom_enums.count != 0, "from enum import IntEnum")",
//        generateGlobalEnums(mod: wrap_module, options: [.python]).replacingOccurrences(of: "    ", with: "\t")
//    ].joined(separator: newLine)
//    
//    if !FM.fileExists(atPath: PATH.path) { try! FM.createDirectory(atPath: PATH.path, withIntermediateDirectories: true, attributes: [:]) }
//    try! py_ast.generatePYI(code: String(contentsOf: wrap_py_path), extra: extra).write(to: PATH.appendingPathComponent("\(file).py"), atomically: true, encoding: .utf8)
}
