//
//  WrapperHandler.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 25/10/2021.
//

import Foundation

enum WrapperPathMode {
    case pyi
    case py
    case project_dir
}

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))!.isDirectory!
    }
}


class recipePathHandler {
    private var url: URL?
    private var use_project_folder = false
    private var asDir = false
    private let name: String
    //private let project: KslProject
    let project: KSLProjectData
    
    private var src_files: [(name: String, url: URL)] = []
    var result_files: [String] = []
    
    init(name: String, project: KSLProjectData) {

        self.name = name
        self.project = project
        
        checkWrapperPath { url, asDir in
            self.url = url
            self.use_project_folder = true
            self.asDir = asDir
        }
        
        guard let url = url else { fatalError("wrapper \(name) not found")}

    }
    
    
    var recipe_name: String { "\(project.name)_\(name)" }
    
    var recipe_src: URL { return url! }
    
    var recipe_target_dir: URL { KSLPaths.shared.WRAPPER_BUILDS.appendingPathComponent("\(project.name)/\(recipe_name)", isDirectory: true) }
    
    var recipe_target_src_dir: URL { recipe_target_dir.appendingPathComponent("src", isDirectory: true) }
    var swift_headers: URL {
        if folder_mode {
            return project.swift_headers.appendingPathComponent(name, isDirectory: true)
        }
        return project.swift_headers
    }
    
    var c_headers: URL {
        if folder_mode {
            return project.c_headers.appendingPathComponent(name, isDirectory: true)
        }
        return project.c_headers
    }
    
    var folder_mode: Bool { asDir }
    
    
    var pyxfiles: [URL] = []
    var h_files: [URL] = []
    
    var swift_files: [URL] = []
    
    
    private func checkWrapperPath(_ complete: @escaping (_ url: URL?, _ asDir: Bool)->Void) {
        let proj_dir = project.url
        if FM.fileExists(atPath: proj_dir.path) {
            
            let src_path = project.wrapper_src

            if FM.fileExists(atPath: src_path.path) {
                
                let wrap_path = src_path.appendingPathComponent(name)
                if FM.fileExists(atPath: wrap_path.path) {
                    if wrap_path.isDirectory {
                        complete(wrap_path,true)
                        return
                    }
                }
                let wrap_file = wrap_path.appendingPathExtension("py")

                if FM.fileExists(atPath: wrap_file.path) {
                    complete(wrap_file, false)
                    return
                }

            }
        }
        
        complete(nil, false)
    }
    
    
    
    func makeRecipe() throws {
        guard let url = url else { fatalError("no url")}
        
        let recipe_target_src = recipe_target_dir.appendingPathComponent("src", isDirectory: true)
        let c_headers = project.c_headers
        
        
        if FM.fileExists(atPath: recipe_target_src.path) {
            try! FM.removeItem(at: recipe_target_src)
        }
        //if !FM.fileExists(atPath: recipe_target_src.path) {
        try FM.createDirectory(at: recipe_target_src, withIntermediateDirectories: true, attributes: nil)
        //}
        var result_files: [String] = []
        let setup_file = recipe_target_src.appendingPathComponent("setup.py")
        if folder_mode {
            //print("folder mode: \(url.path)")
            let files = try! FM.contentsOfDirectory(atPath: url.path)
            for f in files {
                if f == ".DS_Store" { continue }
                let f_url = url.appendingPathComponent(f)
                let f_name = URL(string: f)!.deletingPathExtension().path
                //print(f,f_url.path)
                src_files.append((f_name,f_url))
                result_files.append("\(name)/\(f_name)")
            }
            
            
            try createSetupPy_Module(title: name, files: src_files.map{$0.name}).write(to: setup_file, atomically: true, encoding: .utf8)
        } else {
            //print("file mode: \(url.path)")
            src_files.append( (name, url) )
            result_files.append(name)
            
            try createSetupPy(title: name).write(to: setup_file, atomically: true, encoding: .utf8)
        }
        
        try createRecipe(title: recipe_name).write(to: recipe_target_dir.appendingPathComponent("__init__.py"), atomically: true, encoding: .utf8)
        if !FM.fileExists(atPath: swift_headers.path) {
            //print("\(swift_headers.path) dont exist")
            try FM.createDirectory(at: swift_headers, withIntermediateDirectories: true, attributes: nil)
        }
        try createWrapFiles()
        
    }
    
    func cleanRecipe() throws {
        guard let url = url else { fatalError("no url")}
        
        let recipe_target_src = recipe_target_dir.appendingPathComponent("src", isDirectory: true)
        
        
    }
    
    private func createWrapFiles() throws {
        for _file_ in src_files {
            let afile = _file_.url.deletingPathExtension()
            
            let pyxfile = recipe_target_src_dir.appendingPathComponent("\(_file_.name).pyx")
            pyxfiles.append(pyxfile)
            let h_file = recipe_target_src_dir.appendingPathComponent("_\(_file_.name).h")
            h_files.append(h_file)
            let swift_file = swift_headers.appendingPathComponent("\(_file_.name).swift")
            swift_files.append(swift_file)
            let wrapper_header = c_headers.appendingPathComponent("\(_file_.name).h")
        
            //let py_ast = PythonASTconverter(filename: _file_.name)
            //let wrap_module = py_ast.generateModule(root: _file_.url.path, pyi_mode: false)
//            print("writing to \(pyxfile)")
//            try wrap_module.pyx_new.write(to: pyxfile, atomically: true, encoding: .utf8)
//            try wrap_module.h_new.write(to: h_file, atomically: true, encoding: .utf8)
//            try wrap_module.swift_new.write(to: swift_file, atomically: true, encoding: .utf8)
//
//
//            let extra = [
//                        "\(if: wrap_module.custom_enums.count != 0, "from enum import IntEnum")",
//                        generateGlobalEnums(mod: wrap_module, options: [.python]).replacingOccurrences(of: "    ", with: "\t")
//                        ].joined(separator: newLine)
//            try py_ast.generatePYI(code: String(contentsOf: _file_.url), extra: extra).write(to: KSLPaths.shared.VENV_SITE_PACKAGES.appendingPathComponent("\(_file_.name).py"), atomically: true, encoding: .utf8)
        }
    }
    
}

func BuildWrapperFile(py_name: String, project: KSLProjectData,_ completion: @escaping (Bool, [String])->Void ) {
    
//
//    let fm = FM
//    let cur_dir = ROOT_URL
//
//    var py_file: URL?
//    var c_header_url: URL?
//    var swift_header_url: URL?
//    var project_folder_mode = false
//    var multi_files = false
//    var recipe_name = "\(project.name)_\(py_name)"
//
//    var result_files: [String] = []
    
    
    let recipe = recipePathHandler(name: py_name, project: project)
    try! recipe.makeRecipe()
    let recipe_dir = recipe.recipe_target_dir
    let recipe_name = recipe.recipe_name
    //return

//    let recipe_dir = recipe.recipe_src
//    multi_files = recipe.folder_mode
//    py_file = recipe.recipe_src
////    if project_folder_mode {
////        let build_folder = WRAPPER_BUILDS.appendingPathComponent(project.name, isDirectory: true)
//////        recipe_dir = build_folder.appendingPathComponent(py_name, isDirectory: true)
//////        recipe_name = "\(project.name)_\(py_name)"
////        recipe_dir = WRAPPER_BUILDS.appendingPathComponent(recipe_name, isDirectory: true)
////    } else {
////        recipe_dir = WRAPPER_BUILDS.appendingPathComponent(py_name, isDirectory: true)
////    }
//
//    let src_path = recipe_dir.appendingPathComponent("src", isDirectory: true)
//
//
//    if fm.fileExists(atPath: src_path.path) {
//        try! fm.removeItem(at: src_path)
//    }
//    //if !fm.fileExists(atPath: src_path.path){
//        try! fm.createDirectory(atPath: src_path.path, withIntermediateDirectories: true, attributes: [:])
//    //}
//    let setup_file = src_path.appendingPathComponent("setup.py")
//    let recipe_file = recipe_dir.appendingPathComponent("__init__.py")
//
//
//    if !fm.fileExists(atPath: swift_header_url!.path) { try! fm.createDirectory(at: swift_header_url!, withIntermediateDirectories: true, attributes: [:]) }
//
//    do {
//        if multi_files {
//            try createSetupPy_Module(title: py_name, files: src_files.map{$0.name}).write(to: setup_file, atomically: true, encoding: .utf8)
//        } else {
//            try createSetupPy(title: py_name).write(to: setup_file, atomically: true, encoding: .utf8)
//        }
//
//        try createRecipe(title: recipe_name).write(to: recipe_file, atomically: true, encoding: .utf8)
////        if project_folder_mode {
////            try createRecipe(title: "\(project.name)_\(py_name)").write(to: recipe_file, atomically: true, encoding: .utf8)
////        } else {
////            try createRecipe(title: py_name).write(to: recipe_file, atomically: true, encoding: .utf8)
////        }
//
//    } catch {
//        print(error.localizedDescription)
//    }
//
//
    
//
//    let wrapper_typedefs = cur_dir.appendingPathComponent("system_files/project_support_files/wrapper_typedefs.h")
//    let typedefs_dst = src_path.appendingPathComponent("wrapper_typedefs.h")
//    //let wrapper_header = WRAPPER_HEADERS_C.appendingPathComponent("\(wrap_module.filename).h")
//
//    //if !file_man.fileExists(atPath: typedefs_dst.path){
//        copyItem(from: wrapper_typedefs.path, to: typedefs_dst.path, force: true)
//    //}
//
    print("building", recipe_name, recipe_dir.path)
    //if !DEBUG_MODE {
        venvpython_toolchain(command: .build, args: [recipe_name, "--add-custom-recipe" ,recipe_dir.path])
        venvpython_toolchain(command: .clean, args: [recipe_name, "--add-custom-recipe" ,recipe_dir.path])
    //}
    
    if FM.fileExists(atPath: recipe.c_headers.path) {
        try! FM.removeItem(at: recipe.c_headers)
    }
    try! FM.createDirectory(at: recipe.c_headers, withIntermediateDirectories: true, attributes: nil)
    copyCheaders(from: recipe.h_files, to: recipe.c_headers.path, force: true)
    //copyItem(from: h_file.path, to: wrapper_header.path, force: true)
//    let root_site = ROOT_URL.appendingPathComponent("dist/root/python3/lib/python3.9/site-packages", isDirectory: true)
//        if multi_files {
//            let __init__ = root_site.appendingPathComponent("\(py_name)/__init__.py")
//            if !FM.fileExists(atPath: __init__.path) {
//                FM.createFile(atPath: __init__.path, contents: nil, attributes: [:])
//            }
//        }
    completion(true, recipe.result_files)

}
