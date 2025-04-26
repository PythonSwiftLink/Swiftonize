//
//  PythonHandler.swift
//  Swiftonize
//
//  Created by CodeBuilder on 17/12/2024.
//




import Foundation
import PySwiftCore
import PythonCore
//import PythonFiles

func DEBUG_PRINT(_ items: Any..., separator: String = " ", terminator: String = "\n") {
#if DEBUG
    print(items, separator: separator, terminator: terminator)
#endif
}



fileprivate func pyCheckStatus(status: inout PyStatus, config: inout PyConfig, msg: String) {
    if PyStatus_Exception(status) != 0 {
        DEBUG_PRINT("\(msg)}: \(String(describing: status.err_msg))")
        PyConfig_Clear(&config)
        Py_ExitStatusException(status)
    }
}

//var pystdlib: URL {
//    Bundle.module.url(forResource: "python_stdlib", withExtension: nil)!
//}
//var pyextras: URL {
//    Bundle.module.url(forResource: "python-extra", withExtension: nil)!
//}
class PythonHandler {
    
    static let shared = PythonHandler()
    
    var threadState: UnsafeMutablePointer<PyThreadState>?
    var status: PyStatus
    var preconfig: PyPreConfig
    var config: PyConfig
    
    private var _isRunning: Bool = false
    var defaultRunning: Bool = false

    
    init() {
        
        status = .init()
        preconfig = .init()
        config = .init()

    }
    
    
    
    func start(stdlib: String, app_packages: [String], debug: Bool) {
        //var ret = 0
        
      
        if debug { DEBUG_PRINT("Configuring isolated Python...") }
        PyPreConfig_InitIsolatedConfig(&preconfig)
        PyConfig_InitIsolatedConfig(&config)
        
        // Configure the Python interpreter:
        // Enforce UTF-8 encoding for stderr, stdout, file-system encoding and locale.
        // See https://docs.python.org/3/library/os.html#python-utf-8-mode.
        
        //  Converted to Swift 5.7.1 by Swiftify v5.7.32383 - https://swiftify.com/
        preconfig.utf8_mode = 1
        // Don't buffer stdio. We want output to appears in the log immediately
        config.buffered_stdio = 0
        // Don't write bytecode; we can't modify the app bundle
        // after it has been signed.
        config.write_bytecode = 0
        // Isolated apps need to set the full PYTHONPATH manually.
        config.module_search_paths_set = 1
		
        
        if debug { DEBUG_PRINT("Pre-initializing Python runtime...") }
        status = Py_PreInitialize(&preconfig)
        if PyStatus_Exception(status) != 0 {
            DEBUG_PRINT("Unable to pre-initialize Python interpreter: \(String(describing: status.err_msg))")
            PyConfig_Clear(&config)
            Py_ExitStatusException(status)
        }
        
        // Read the site config
        status = PyConfig_Read(&config)
        pyCheckStatus(status: &status, config: &config, msg: "Unable to read site config")
        
        // The unpacked form of the stdlib
        //path = stdlib_path
        if debug { DEBUG_PRINT("- \(stdlib)") }
        var wtmp_str = stdlib.withCString { Py_DecodeLocale($0, nil) }
        status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
        
        pyCheckStatus(status: &status, config: &config, msg: "Unable to set unpacked form of stdlib path")
        PyMem_RawFree(wtmp_str)
        
        // Add the stdlib binary modules path
        let dynload_path = "\(stdlib)/lib-dynload"
        if debug { DEBUG_PRINT("- \(dynload_path)") }
        wtmp_str = dynload_path.withCString { Py_DecodeLocale($0, nil) }
        status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
        pyCheckStatus(status: &status, config: &config, msg: "Unable to set stdlib binary module path")
        PyMem_RawFree(wtmp_str)
		
        
        // Add the app_packages path
        //path = "\(resourcePath)/app_packages"
        for package in app_packages {
            print("- \(package)") 
            wtmp_str = package.withCString { Py_DecodeLocale($0, nil) }
            status = PyWideStringList_Append(&config.module_search_paths, wtmp_str)
            pyCheckStatus(status: &status, config: &config, msg: "Unable to set app packages path")
            PyMem_RawFree(wtmp_str)
        }
        
        //    DEBUG_PRINT("Configure argc/argv...")
        //    status = PyConfig_SetBytesArgv(&config, argc, argv)
        //    pyCheckStatus(status: &status, config: &config, msg: "Unable to configured argc/argv")
        
        
        if debug { DEBUG_PRINT("Initializing Python runtime...") }
        status = Py_InitializeFromConfig(&config)
        pyCheckStatus(status: &status, config: &config, msg: "Unable to initialize Python interpreter")
        
        
        
        //exit(Int32(ret))
        //return ret
    }
    
    
    deinit {
        Py_Finalize();
    }
}
