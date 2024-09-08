// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport


let local = false

var dependencies: [Package.Dependency] = [
	.package(url: "https://github.com/SwiftyJSON/SwiftyJSON", branch: "master"),
	.package(url: "https://github.com/apple/swift-syntax", from: .init(509, 0, 0))
]

if local {
	dependencies.append(contentsOf: [
		.package(path: "../PyAst"),
	])
} else {
	dependencies.append(contentsOf: [
		.package(url: "https://github.com/PythonSwiftLink/PyAst", branch: "master"),
	])
}

let package = Package(
    name: "Swiftonize",
    platforms: [.macOS(.v11), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
//        .library(
//            name: "Swiftonize",
//            targets: ["Swiftonize"]),
		.library(name: "SwiftonizeNew", targets: ["Swiftonizer"]),
		.library(name: "PyWrapper", targets: ["PyWrapper"])
    ],
    dependencies: dependencies,
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PyWrapper",
            dependencies: [
                
				//.product(name: "PySwiftCore", package: "PythonSwiftLink-development"),
				.product(name: "PyAstParser", package: "PyAst"),
                "SwiftyJSON",
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        
//        .target(
//            name: "Swiftonize",
//            dependencies: [
//                "WrapContainers",
//				.product(name: "SwiftSyntax", package: "swift-syntax"),
//				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
//            ]
//        ),
//		
		.target(
			name: "Swiftonizer",
			dependencies: [
				"PyWrapper",
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
				//"SwiftonizeMacros"
				
			]
		),
//		.macro(
//			name: "SwiftonizeMacros",
//			dependencies: [
//				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
//				.product(name: "SwiftCompilerPlugin", package: "swift-syntax")
//			]
//		),
//        .testTarget(
//            name: "SwiftonizeTests",
//            dependencies: [
//                "Swiftonize",
//                "WrapContainers",
//                "PythonSwiftCore",
//                "PythonTestSuite",
//				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
//            ]
//        ),
    ]
)
