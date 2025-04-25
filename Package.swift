// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport


let local = false

var dependencies: [Package.Dependency] = [
	.package(url: "https://github.com/SwiftyJSON/SwiftyJSON", from: .init(5, 0, 2)),
	.package(url: "https://github.com/swiftlang/swift-syntax", from: .init(509, 0, 0))
]

if local {
	dependencies.append(contentsOf: [
		.package(path: "../PyAst"),
	])
} else {
	dependencies.append(contentsOf: [
		//.package(url: "https://github.com/PythonSwiftLink/PyAst", branch: "master"),
		.package(url: "https://github.com/PythonSwiftLink/PyAst", from: .init(0, 0, 0)),
        .package(url: "https://github.com/apple/swift-argument-parser", from: .init(1, 2, 0)),
        .package(url: "https://github.com/PythonSwiftLink/PySwiftKit", from: .init(311, 0, 0)),
        .package(url: "https://github.com/kylef/PathKit", from: .init(1, 0, 0) ),
	])
}

let package = Package(
    name: "Swiftonize",
    platforms: [.macOS(.v13), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
//        .library(
//            name: "Swiftonize",
//            targets: ["Swiftonize"]),
		.library(name: "SwiftonizeLibrary", targets: ["Swiftonizer"]),
        .executable(name: "Swiftonize", targets: ["Swiftonize"]),
		.library(name: "PyWrapper", targets: ["PyWrapper"]),
		.library(name: "ShadowPip", targets: ["ShadowPip"])
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
		.target(
			name: "ShadowPip",
			dependencies: [
				.product(name: "PyAstParser", package: "PyAst"),
				"PyWrapper",
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
        .executableTarget(
            name: "Swiftonize",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "PySwiftCore", package: "PySwiftKit"),
                .product(name: "PySwiftObject", package: "PySwiftKit"),
                .product(name: "PyDictionary", package: "PySwiftKit"),
                "Swiftonizer",
                //.product(name: "PySwiftObject", package: "PythonSwiftLink"),
                "PathKit"
            ]
        )
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
