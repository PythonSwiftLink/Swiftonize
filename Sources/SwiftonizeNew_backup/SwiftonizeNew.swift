//
//  File.swift
//  

import Foundation
import SwiftSyntaxBuilder
import SwiftSyntax

import WrapContainers
import PyAst
import PySwiftCore


extension WrapClass {
	
	var `extension`: CodeBlockItemListSyntax {
		return .init {
			//ExtensionDeclSyntax(extensionKeyword: .keyword(.extension), extendedType: TypeSyntax(stringLiteral: title)) {
				
			//}
			ExtensionDeclSyntax(extensionKeyword: .keyword(.extension), extendedType: TypeSyntax(stringLiteral: title)) {
				tp_new()
				tp_init()
				tp_dealloc()
				if bases.contains(.Str) {
					tp_str()
					tp_repr()
				}
				if bases.contains(.Hashable) { tp_hash() }
				if !send_functions.isEmpty {
					PyMethods(cls: self).output.with(\.trailingTrivia, .newlines(2))
				}
				
				if !bases.isEmpty {
					if bases.contains(.AsyncGenerator) {
						PyAsyncMethodsGenerator(cls: self).variDecl
					}
					if bases.contains(.Sequence) {
						PySequenceMethodsGenerator(cls: self).variDecl
					}
					if bases.contains(.Mapping) {
						PyMappingMethodsGenerator(cls: self).variDecl
					}
					if bases.contains(.Number) {
						PyNumberMethodsGenerator(cls: self).variDecl
					}
				}
				if !properties.isEmpty {
					pyGetSets()
				}
				
				
				
				pyTypeObject()
				
				createPyTypePointer
				
				
				createPyClassExtension
				createPyClassUnRetainedExtension
				createPyObjectClassExtension
				createPyObjectClassUnretainedExtension
				
				if callbacks.count > 0 {
					PyCallbacksGenerator(cls: self).code.with(\.leadingTrivia, .newline)
				}
				
			}
			//.with(\.leadingTrivia, .newlines(2)).with(\.trailingTrivia, .newlines(2))
			
			if let pyProtocol = pyProtocol {
				pyProtocol//.with(\.leadingTrivia, .newlines(2))
			}
		}
	}
	
	public var extensionFile: SwiftSyntax.SourceFileSyntax {
		.init(statements: self.extension, endOfFileToken: .endOfFileToken())
	}
	
	fileprivate var create_tp_init: ClosureExprSyntax {
		
		let closure = ExprSyntax(stringLiteral: "{ __self__, _args_, kw -> Int32 in }").as(ClosureExprSyntax.self)!
		return closure.with(\.statements, .init {
			if debug_mode { ExprSyntax(stringLiteral: #"print("tp_init - <\#(title)>")"#) }
			createTP_Init(cls: self, args: init_function?._args_ ?? []).code
			"return 1"
		})
		
	}
	
	fileprivate func tp_init() -> VariableDeclSyntax {
		
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_init"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_initproc")),
			initializer: .init(value: create_tp_init)
		).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate func tp_new() -> VariableDeclSyntax {
		
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_new"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_newfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
				{ type, _, _ -> PyPointer? in
					PySwiftObject_New(type)
				}
				"""))
		).with(\.leadingTrivia, .newlines(2)).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate func tp_dealloc() -> VariableDeclSyntax {
		
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_dealloc"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_destructor")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
				{ s in
					if let ptr = s?.pointee.swift_ptr {
						Unmanaged<\(title)>.fromOpaque(ptr).release()
					}
				}
			""")).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	fileprivate func tp_str() -> VariableDeclSyntax {
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_str"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_reprfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
				{ __self__ in
					return UnPackPySwiftObject(with: __self__, as: \(title).self).__str__().pyPointer
				}
				""")).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	fileprivate func tp_repr() -> VariableDeclSyntax {
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_repr"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_reprfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
				{ __self__ in
					return UnPackPySwiftObject(with: __self__, as: \(title).self).__repr__().pyPointer
				}
				""")).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	fileprivate func tp_hash() -> VariableDeclSyntax {
		let expr = ExprSyntax(stringLiteral: """
		{ __self__ in
			return UnPackPySwiftObject(with: __self__, as: \(title).self).__hash__()
		}
		""").as(ClosureExprSyntax.self)!
		
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_hash"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_hashfunc")),
			initializer: .init(value: expr).with(\.trailingTrivia, .newlines(2))
		)
	}
//	fileprivate func pyMethods() -> VariableDeclSyntax {
//		let methods: ArrayElementListSyntax = .init {
//			for property in self.properties {
//				PyGetSetProperty(_property: property, _cls: self).pyGetSetDef()
//			}
//			ArrayElementSyntax(expression: ExprSyntax(stringLiteral: "PyMethodDef()"))
//		}
//		
//		return .init(
//			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
//			name: .init(stringLiteral: "PyMethods"),
//			type: .init(type: TypeSyntax(stringLiteral: "[PyMethodDef]")),
//			initializer: .init(value: ArrayExprSyntax(
//				leftSquare: .leftSquareToken(),
//				elements: methods.with(\.leadingTrivia, .newline),
//				rightSquare: .rightSquareToken(leadingTrivia: .newline)
//			))
//		).with(\.trailingTrivia, .newlines(2))
//	}
	
	fileprivate func pyGetSets() -> VariableDeclSyntax {
		let methods: ArrayElementListSyntax = .init {
			for property in self.properties {
				PyGetSetProperty(_property: property, _cls: self).pyGetSetDef()
			}
			ArrayElementSyntax(expression: ExprSyntax(stringLiteral: "PyGetSetDef()"))
		}
		
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "asPyGetSet"),
			type: .init(type: TypeSyntax(stringLiteral: "[PyGetSetDef]")),
			initializer: .init(value: ArrayExprSyntax(
				leftSquare: .leftSquareToken(),
				elements: methods.with(\.leadingTrivia, .newline),
				rightSquare: .rightSquareToken(leadingTrivia: .newline)
			))
		).with(\.trailingTrivia, .newlines(2))
	}
	
//	func pySequenceMethods() -> FunctionCallExprSyntax {
//		//let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
//		let exp: ExprSyntax = ".init"
//		return .init(
//			
//			calledExpression: exp,
//			leftParen: .leftParenToken(),
//			argumentList: .init {
//				TupleExprElementSyntax(
//					label: "methods",
//					expression: PySequenceMethods(cls: self).output
//				)
//			},
//			rightParen: .rightParenToken(leadingTrivia: .newline)//.with(\.leadingTrivia, .newline)
//		)
//	}
	
	fileprivate func pyTypeObject() -> VariableDeclSyntax {
		return .init(
			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "pyTypeObject"),
			type: .init(type: TypeSyntax(stringLiteral: "PyTypeObject")),
			initializer: .init(value: PyTypeObjectGenerator(cls: self).functionCallExpr() )
		).with(\.trailingTrivia, .newlines(2))
	}
	
	
	fileprivate var createPyClassExtension: FunctionDeclSyntax {
		try! .init(
		"""
		public static func asPyPointer(_ target: \(raw: title)) -> PyPointer {
		let new = PySwiftObject_New(\(raw: title).PyType)
		PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
		return new!
		}
		"""
		).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate var createPyObjectClassExtension: FunctionDeclSyntax {
		try! .init("""
		public static func asPythonObject(_ target: \(raw: title)) -> PythonObject {
		let new = PySwiftObject_New(\(raw: title).PyType)!
		PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
		return .init(ptr: new, from_getter: true)
		}
		""").with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate var createPyClassUnRetainedExtension: FunctionDeclSyntax {
		try! .init("""
		public static func asPyPointer(unretained target: \(raw: title)) -> PyPointer {
		let new = PySwiftObject_New(\(raw: title).PyType)
		PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
		return new!
		}
		""").with(\.trailingTrivia, .newlines(2))
	}
	fileprivate var createPyObjectClassUnretainedExtension: FunctionDeclSyntax {
		try! .init("""
		public static func asPythonObject(unretained target: \(raw: title)) -> PythonObject {
		let new = PySwiftObject_New(\(raw: title).PyType)!
		PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
		return .init(ptr: new, from_getter: true)
		}
		""")//.with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate var createPyTypePointer: DeclSyntax {
		DeclSyntax(stringLiteral: """
		public static let PyType: UnsafeMutablePointer<PyTypeObject> = {
		let t: UnsafeMutablePointer<PyTypeObject> = .init(&pyTypeObject)
		if PyType_Ready(t) < 0 {
		PyErr_Print()
		fatalError("PyReady failed")
		}
		return t
		}()
		""").with(\.trailingTrivia, .newlines(2))
	}
}
extension Array where Element == FunctionDeclSyntax {
	func uniqued() -> Array {
		var buffer = Array()
		var added = Set<String>()
		for elem in self {
			if !added.contains(elem.description) {
				buffer.append(elem)
				added.insert(elem.description)
			}
		}
		return buffer
	}
}
extension WrapClass {
	
	fileprivate func getBaseMethods() -> [FunctionDeclSyntax] {
		var base_methods = [FunctionDeclSyntax]()
		for base in bases {
			switch base {
			case .Mapping, .MutableMapping:
				for f in PyMappingMethodsGenerator(cls: self).methods {
					base_methods.append(f._protocol())
				}
			case .Sequence, .MutableSequence:
				for f in PySequenceMethodsGenerator(cls: self).methods {
					base_methods.append(f._protocol())
				}
			case .Buffer:
				continue
			case .AsyncGenerator:
				for f in PyAsyncMethodsGenerator(cls: self).methods {
					base_methods.append(f._protocol())
				}
			case .Number:
				for f in PyNumberMethodsGenerator(cls: self).methods {
					if let _protocol = f._protocol() {
						base_methods.append(_protocol)
					}
				}
			case .Str:
				base_methods.append(try! .init("func __str__() -> String"))
				base_methods.append(try! .init("func __repr__() -> String"))
			case .Hashable:
				base_methods.append(try! .init("func __hash__() -> Int"))
			default: continue
			}
		}
		return base_methods.uniqued()
		
	}
	
	var pyProtocol: ProtocolDeclSyntax? {
		
		let _user_functions = functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .no_protocol)})
		let clsMethods = pyClassMehthods.filter({$0 != .__init__})
//		if  !(callbacks_count == 0 && !new_class) && _user_functions.isEmpty &&
//				clsMethods.isEmpty && pySequenceMethods.isEmpty && init_function == nil {
//			if bases.isEmpty { return nil }
//		}
		
		if  !(callbacks_count == 0 && !new_class) && _user_functions.isEmpty && init_function == nil {
			if bases.isEmpty { return nil }
		}
		
		let protocolList = MemberDeclListSyntax {
			for base_method in getBaseMethods() {
				base_method
			}
		}
		let _protocol = ProtocolDeclSyntax(
			modifiers: [.init(name: .keyword(.public))],
			protocolKeyword: .keyword(.protocol),
			name: .identifier("\(title)_PyProtocol")) {
				protocolList
			}
		
		return _protocol.with(\.leadingTrivia, .newlines(2)).with(\.trailingTrivia, .newlines(2))
	}
}





