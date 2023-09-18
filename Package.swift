// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Swiftonize",
    platforms: [.macOS(.v11), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Swiftonize",
            targets: ["Swiftonize"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        //.package(path: "../PyAstParser"),
        //.package(path: "../PythonSwiftCore"),
        .package(url: "https://github.com/PythonSwiftLink/PyAstParser", branch: "main"),
        //.package(path: "../PyAstParser"),
        //.package(url: "https://github.com/PythonSwiftLink/PythonSwiftCore", branch: "main"),
        .package(url: "https://github.com/PythonSwiftLink/PythonSwiftCore", branch: "testing"),
        //.package(url: "https://github.com/PythonSwiftLink/PythonSwiftCore", from: .init(0, 3, 0)),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", branch: "master"),
        .package(url: "https://github.com/apple/swift-syntax", from: .init(508, 0, 0)),
        
        //.package(path: "../PythonTestSuite")
        .package(url: "https://github.com/PythonSwiftLink/PythonTestSuite", branch: "master"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WrapContainers",
            dependencies: [
                "PythonSwiftCore",
                "PyAstParser",
                "SwiftyJSON",
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        
        .target(
            name: "Swiftonize",
            dependencies: [
                "WrapContainers",
				.product(name: "SwiftSyntax", package: "swift-syntax"),
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "SwiftonizeTests",
            dependencies: [
                "Swiftonize",
                "WrapContainers",
                "PythonSwiftCore",
                "PythonTestSuite",
				.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")
            ]
        ),
    ]
)
