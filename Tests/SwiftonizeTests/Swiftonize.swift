import XCTest
@testable import Swiftonize
@testable import WrapContainers
@testable import PythonTestSuite
import SwiftParser
import SwiftSyntax

final class SwiftnizeTests: XCTestCase {
    
    private func testFunction_TestA(_ f: WrapFunction) throws {
        XCTAssertEqual(f._args_.count, 3)
        let args = f._args_
        let (arg0, arg1, arg2) = (args[0], args[1], args[2])
        XCTAssertEqual(arg0.name, "a")
        XCTAssertEqual(arg0.type, .int)
        XCTAssertNotNil(arg0 as? intArg)
        
        XCTAssertEqual(arg1.name, "b")
        XCTAssertEqual(arg1.type, .float)
        XCTAssertNotNil(arg1 as? floatArg)
        
        XCTAssertEqual(arg2.name, "c")
        XCTAssertEqual(arg2.type, .uint8)
        XCTAssertNotNil(arg2 as? intArg)
    }
    
    private func testFunction_TestB(_ f: WrapFunction) throws {
        XCTAssertEqual(f._args_.count, 3)
        let args = f._args_
        let (arg0, arg1, arg2) = (args[0], args[1], args[2])
        XCTAssertEqual(arg0.name, "a")
        XCTAssertEqual(arg0.type, .list)
        XCTAssertNotNil(arg0 as? collectionArg)
        if let testArg = arg0 as? collectionArg {
            let element = testArg.element
            XCTAssertEqual(element.type, .int)
            XCTAssertNotNil(element as? intArg)
        }
        
        XCTAssertEqual(arg1.name, "b")
        XCTAssertEqual(arg1.type, .list)
        XCTAssertNotNil(arg1 as? collectionArg)
        
        if let testArg = arg1 as? collectionArg {
            let element = testArg.element
            XCTAssertEqual(element.type, .float)
            XCTAssertNotNil(element as? floatArg)
        }
        
        XCTAssertEqual(arg2.name, "c")
        XCTAssertEqual(arg2.type, .tuple)
        XCTAssertNotNil(arg2 as? collectionArg)
        
        if let testArg = arg2 as? collectionArg {
            let element = testArg.element
            XCTAssertEqual(element.type, .uint8)
            XCTAssertNotNil(element as? intArg)
        }
    }
    
    private func testFunction_TestC(_ f: WrapFunction) throws {
        XCTAssertEqual(f._args_.count, 3)
        let args = f._args_
        let (arg0, arg1, arg2) = (args[0], args[1], args[2])
        XCTAssertEqual(arg0.name, "a")
        XCTAssertEqual(arg0.type, .other)
        XCTAssertNotNil(arg0 as? otherArg)
        if let testArg = arg0 as? otherArg {
            XCTAssertEqual(testArg.other_type, "SomeSwiftType")
        }
        
        XCTAssertEqual(arg1.name, "b")
        XCTAssertEqual(arg1.type, .list)
        XCTAssertNotNil(arg1 as? collectionArg)
        
        if let testArg = arg1 as? collectionArg {
            let element = testArg.element
            XCTAssertEqual(element.type, .other)
            XCTAssertNotNil(element as? otherArg)
        }
        
        XCTAssertEqual(arg2.name, "c")
        XCTAssertEqual(arg2.type, .tuple)
        XCTAssertNotNil(arg2 as? collectionArg)
        
        if let testArg = arg2 as? collectionArg {
            let element = testArg.element
            XCTAssertEqual(element.type, .other)
            XCTAssertNotNil(element as? otherArg)
        }
    }
    
    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        initPython()
        return 
        let module = await WrapModule(fromAst: "my_module", string: """
        @wrapper
        class MyWrapper:
            
            def testA(a: int, b: float, c: uint8): ...
            def testB(a: list[int], b: list[float], c: tuple[uint8]): ...
            def testC(a: SomeSwiftType, b: list[SomeSwiftType], c: tuple[SomeSwiftType]): ...
        
        """, swiftui: true)
        
        XCTAssertEqual(module.filename, "my_module")
        XCTAssertEqual(module.classes.count, 1)
        guard let MyWrapper = module.classes.first else { fatalError() }
        print(MyWrapper)
        let functions = MyWrapper.functions
        XCTAssertEqual(functions.count, 3)
        guard let testA = functions.first(where: { $0.name == "testA" }) else { fatalError() }
        
        try testFunction_TestA(testA)
        
        guard let testB = functions.first(where: { $0.name == "testB" }) else { fatalError() }
        
        try testFunction_TestB(testB)
        
        guard let testC = functions.first(where: { $0.name == "testC" }) else { fatalError() }
        
        try testFunction_TestC(testC)
        
        
    }
	
	func test_autoWrapper() throws {
		initPython()
		
		let classes = nsItemProviderTree.statements.compactMap { blockitem in
			blockitem.item.as(ClassDeclSyntax.self)
		}
		let export = URL(filePath: "/Users/codebuilder/Downloads/export.swift")
		let url = URL(filePath: "/Volumes/CodeSSD/GitHub/kivy-ios/kivy_ios/recipes/swift_webviews/src/sources/WebViews.swift")
		let mod = WrapModule(filename: url.deletingPathExtension().lastPathComponent, file: try! .init(contentsOf: url))
//		let mod = WrapModule(filename: "mySwift")
//		mod.classes = classes.map(WrapClass.init)
//		let url = URL(fileURLWithPath: "/Users/codebuilder/Downloads/export.swift")
		try mod.code.formatted().description.write(to: export, atomically: true, encoding: .utf8)
		
	}
}
public let nsItemProviderTree = Parser.parse(source: nsItemProviderCode)
public let testBuilderTree = Parser.parse(source: """

class MySwiftClass {

	var a: String {
		""
	}

	private var b: String {
		get { }
		set { }
	}
	public var c: String {
		get { }
		set { }
	}


	func MyFunction(a: Int) -> String {
		return ""
	}

	func MyFunction2(b: Int, c: String?) -> String {
		return ""
	}

	func MyFunction3( _ b: Int, _ c: [[Int]]) -> String {
		return ""
	}
}

enum MySwiftEnum: String {
 case MyCase
}

""")
