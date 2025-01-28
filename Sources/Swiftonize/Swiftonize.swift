
import ArgumentParser
import PathKit
import Foundation

@main
struct Swiftonize: AsyncParsableCommand {
    
    static var configuration: CommandConfiguration = .init(
        version: "0.0.4",
        subcommands: [
            Build.self,
            //VenvDump.self
        ]
    )
    
    static func launchPython() throws {
        let python = PythonHandler.shared
        //try PythonFiles.checkModule()
        if !python.defaultRunning {
            python.start(
                stdlib: "/Library/Frameworks/Python.framework/Versions/3.11/lib/python3.11",
                app_packages: [
                    //PythonFiles.py_modules
                ],
                debug: true
            )
        }
    }
    
}

//extension PathKit.Path: @retroactive ExpressibleByArgument {
extension PathKit.Path: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
    
    static let app_path: Self? = {
        guard let _app_path = Foundation.ProcessInfo.processInfo.arguments.first else { return nil }
        var app_path = Path(_app_path)
        
        if app_path.isSymlink {
            app_path = try! app_path.symlinkDestination()
        }
        print(app_path)
        return app_path.parent()
    }()
    
}
