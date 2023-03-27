//
//  TestSuite.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 24/10/2021.
//

import Foundation
//import SwiftyJSON

//private class WrapTestSuite: Codable {
//    var files: [WrapModule]
//}


//private func generateTestWrapperModules(url: URL) -> WrapTestSuite {
//
//    let test_file_path = url.appendingPathComponent("generated_mod.json")
//    print("loading json file")
//    let data = try! Data(contentsOf: test_file_path)
//    print("building wrap_module")
//    let decoder = JSONDecoder()
//    let wrap_module = try! decoder.decode(WrapTestSuite.self, from: data)
//
//    return wrap_module
//}


//func buildTestWrapper() {
//    let file_man = FileManager()
//    let cur_dir = file_man.currentDirectoryPath
//    let cur_dir_url = URL(fileURLWithPath: cur_dir)
//    
//    let wrap_files = generateTestWrapperModules(url: cur_dir_url)
//    for wrap_module in wrap_files.files {
//        print("building \(wrap_module.filename)")
//        let py_name = wrap_module.filename
//        let wrapper_builds_path = cur_dir_url.appendingPathComponent("wrapper_builds", isDirectory: true)
//        //let wrapper_headers_path = cur_dir_url.appendingPathComponent("wrapper_headers", isDirectory: true)
//        let recipe_dir = wrapper_builds_path.appendingPathComponent(py_name, isDirectory: true)
//        let src_path = recipe_dir.appendingPathComponent("src", isDirectory: true)
//        if !file_man.fileExists(atPath: src_path.path){
//            try! file_man.createDirectory(atPath: src_path.path, withIntermediateDirectories: true, attributes: [:])
//        }
//        let pyxfile = src_path.appendingPathComponent("\(py_name).pyx")
//        let h_file = src_path.appendingPathComponent("_\(py_name).h")
//        let m_file = src_path.appendingPathComponent("_\(py_name).m")
//        let setup_file = src_path.appendingPathComponent("setup.py")
//        let recipe_file = recipe_dir.appendingPathComponent("__init__.py")
//        do {
////            try wrap_module.pyx.write(to: pyxfile, atomically: true, encoding: .utf8)
////            try wrap_module.h.write(to: h_file, atomically: true, encoding: .utf8)
////            try wrap_module.m.write(to: m_file, atomically: true, encoding: .utf8)
//            try createSetupPy(title: py_name).write(to: setup_file, atomically: true, encoding: .utf8)
//            try createRecipe(title: py_name).write(to: recipe_file, atomically: true, encoding: .utf8)
//        } catch {
//            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
//            print(error.localizedDescription)
//        }
//        let wrapper_typedefs = cur_dir_url.appendingPathComponent("project_support_files/wrapper_typedefs.h")
//        let typedefs_dst = src_path.appendingPathComponent("wrapper_typedefs.h")
//        //let wrapper_header = wrapper_headers_path.appendingPathComponent("\(wrap_module.filename).h")
//        
//        if !file_man.fileExists(atPath: typedefs_dst.path){
//            //copyItem(from: wrapper_typedefs.path, to: typedefs_dst.path)
//        }
//
//        //_toolchain(path: cur_dir, command: .clean, args: [py_name, "--add-custom-recipe" ,recipe_dir.path])
//        //_toolchain(path: cur_dir, command: .build, args: [py_name, "--add-custom-recipe" ,recipe_dir.path])
//    }//update_project()
//}
