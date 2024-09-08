
import Foundation
import PyWrapper
import SwiftSyntax
import SwiftSyntaxBuilder


extension PyWrap.Class {
	func codeBlock() throws -> CodeBlockItemListSyntax { try .init {
		if options.generic_mode {
//			for typevar in options.generic_typevar?.types ?? [] {
//				genericPyTypeObject(target: typevar)
//			}
			baseTypeCode()
			for ext in try generic_extensions() {
				ext.with(\.leadingTrivia, .newlines(2))
			}
		} else {
			try extensions().with(\.leadingTrivia, .newlines(2))
		}
		if new_class {
			NewClassGenerator(cls: self).code.with(\.leadingTrivia, .newline)
		}
		if !new_class ,let pyProtocol = pyProtocol {
			pyProtocol
		}
	}}
	
	func extensions() throws -> ExtensionDeclSyntax {
		let bases = bases()
		return .init(extendedType: TypeSyntax(stringLiteral: name)) {
			if !new_class, let callbacks = callbacks, callbacks.count > 0 {
				PyCallbacksGenerator(cls: callbacks).code.with(\.leadingTrivia, .newline)
			}
			tp_new()
			tp_init()
			tp_dealloc()
			
			if bases.contains(.Str) {
				tp_str()
				tp_repr()
			}
			if bases.contains(.Hashable) { tp_hash() }
			
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
			
			if functions != nil {
				PyMethods(cls: self).output.with(\.trailingTrivia, .newlines(2))
			}
//			if !properties.isEmpty {
				pyGetSets()
//			}
			pyTypeObject()
			createPyTypePointer
			
			
			createPyClassExtension
			createPyClassUnRetainedExtension
			//createPyObjectClassExtension
			//createPyObjectClassUnretainedExtension
			
		}
		
	}
	
	
}







fileprivate extension PyWrap.Class {
	
	fileprivate func baseTypeCode() -> CodeBlockItemListSyntax { .init {
//		"""
//		fileprivate var \(raw: name)_Mapping = {
//			var mapping = PyMappingMethods()
//			let mp_subscript: PySwift__mgetitem__ = {_, type in
//				pyPrint(type!)
//				return .None
//			}
//			mapping.mp_subscript = unsafeBitCast(mp_subscript, to: binaryfunc.self)
//			return mapping
//		}()
//		"""
		"fileprivate var \(raw: name)_BaseType = PyTypeObject.BaseType(name: \(literal: name))"
		"fileprivate let \(raw: name)_PyType: UnsafeMutablePointer<PyTypeObject> = .init(&\(raw: name)_BaseType)"
		"""
		extension \(raw: name) {
			static var BaseType: UnsafeMutablePointer<PyTypeObject> { \(raw: name)_PyType }
		}
		"""
	}}
	
	fileprivate func pyTypeObject() -> VariableDeclSyntax {
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "pyTypeObject"),
			type: .init(type: TypeSyntax(stringLiteral: "PyTypeObject")),
			initializer: .init(value: PyTypeObjectGenerator(cls: self).functionCallExpr() )
		).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate var create_tp_init: ClosureExprSyntax {
		
		let closure = ExprSyntax(stringLiteral: "{ __self__, _args_, kw -> Int32 in }").as(ClosureExprSyntax.self)!
		return closure.with(\.statements, .init {
			//if debug_mode { ExprSyntax(stringLiteral: #"print("tp_init - <\#(title)>")"#) }
			//createTP_Init(cls: self, args: init_function?._args_ ?? []).code
			ObjectInitializer(_cls: self).codeBlock
			"return 1"
		})
		
	}
	
	fileprivate func tp_init() -> VariableDeclSyntax {
		
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_init"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_initproc")),
			initializer: .init(value: create_tp_init)
		).with(\.trailingTrivia, .newlines(2))
	}
	
	
	
	fileprivate func tp_new() -> VariableDeclSyntax {
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
//			modifiers: [.init(name: .keyword(.fileprivate)), .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_new"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_newfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
				{ type, _, _ -> PyPointer? in
				PySwiftObject_New(type)
				}
				"""))
		).with(\.leadingTrivia, .newlines(2)).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate func tp_dealloc(target: String? = nil) -> VariableDeclSyntax {
		
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_dealloc"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_destructor")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
			{ s in
			if let ptr = s?.pointee.swift_ptr {
			Unmanaged<\(target ?? name)>.fromOpaque(ptr).release()
			}
			}
			""")).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	fileprivate func tp_str(target: String? = nil) -> VariableDeclSyntax {
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_str"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_reprfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
	{ __self__ in
	 return UnPackPySwiftObject(with: __self__, as: \(target ?? name).self).__str__().pyPointer
	}
	"""))//.with(\.trailingTrivia, .newlines(2))
		)
	}
	
	fileprivate func tp_repr() -> VariableDeclSyntax {
		return .init(
			modifiers: [.init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_repr"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_reprfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
	{ __self__ in
	 return UnPackPySwiftObject(with: __self__, as: \(name).self).__repr__().pyPointer
	}
	""")).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	
	fileprivate func tp_hash() -> VariableDeclSyntax {
		let expr = ExprSyntax(stringLiteral: """
			{ __self__ in
			return UnPackPySwiftObject(with: __self__, as: \(name).self).__hash__()
			}
			""").as(ClosureExprSyntax.self)!
		
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_hash"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_hashfunc")),
			initializer: .init(value: expr).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	
	
	fileprivate var createPyClassExtension: FunctionDeclSyntax {
		try! .init(
  """
  public static func asPyPointer(_ target: \(raw: name)) -> PyPointer {
  let new = PySwiftObject_New(\(raw: name).PyType)
  PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
  return new!
  }
  """
		).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate var createPyObjectClassExtension: FunctionDeclSyntax {
		try! .init("""
  public static func asPythonObject(_ target: \(raw: name)) -> PythonObject {
  let new = PySwiftObject_New(\(raw: name).PyType)!
  PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
  return .init(ptr: new, from_getter: true)
  }
  """).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate var createPyClassUnRetainedExtension: FunctionDeclSyntax {
		try! .init("""
  public static func asPyPointer(unretained target: \(raw: name)) -> PyPointer {
  let new = PySwiftObject_New(\(raw: name).PyType)
  PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
  return new!
  }
  """).with(\.trailingTrivia, .newlines(2))
	}
	fileprivate var createPyObjectClassUnretainedExtension: FunctionDeclSyntax {
		try! .init("""
  public static func asPythonObject(unretained target: \(raw: name)) -> PythonObject {
  let new = PySwiftObject_New(\(raw: name).PyType)!
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
	
	
	
	fileprivate func pyGetSets() -> VariableDeclSyntax {
		let methods: ArrayElementListSyntax = .init {
			if let properties = self.properties {
				for property in properties {
					PyGetSetProperty(_property: property, _cls: self).pyGetSetDef()
				}
				ArrayElementSyntax(expression: ExprSyntax(stringLiteral: "PyGetSetDef()"))
			}
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

fileprivate extension String {
	
}

public extension PyWrap.Class {
	
	fileprivate func getBaseMethods() -> [FunctionDeclSyntax] {
		let bases = bases()
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
	
	var protocolConformances: InheritanceClauseSyntax? {
		let bases = bases()
		if bases.isEmpty { return nil }
		return .init {
			for base in bases {
				switch base {
					//				case .NSObject:
					//
					//				case .SwiftBase:
					//
					//				case .SwiftObject:
					//
					//				case .Iterable:
					//
					//				case .Iterator:
					//
					//				case .Collection:
					//
				case .MutableMapping:
					"PyMutableMappingProtocol".inheritanceType
				case .Mapping:
					"PyMappingProtocol".inheritanceType
				case .Sequence, .MutableSequence:
					"PySequenceProtocol".inheritanceType
					
				case .Buffer:
					"PyBufferProtocol_AnyClass".inheritanceType
				case .Bytes:
					"PyBytesProtocol".inheritanceType
				case .AsyncIterable:
					"PyAsyncIterableProtocol".inheritanceType
				case .AsyncIterator:
					"PyAsyncIteratorProtocol".inheritanceType
				case .AsyncGenerator:
					"PyAsyncProtocol".inheritanceType
				case .Number:
					"PyNumberProtocol".inheritanceType
				case .Str:
					"PyStrProtocol".inheritanceType
				case .Float:
					"PyFloatProtocol".inheritanceType
				case .Int:
					"PyIntProtocol".inheritanceType
				case .Hashable:
					"PyHashable".inheritanceType
				default: "".inheritanceType
				}
			}
		}
		
	
		
	}
	
	var pyProtocol: ProtocolDeclSyntax? {
		let bases = bases()
		
//		let _user_functions = functions.filter({!$0.has_option(option: .callback) && !$0.has_option(option: .no_protocol)})
//		let clsMethods = pyClassMehthods.filter({$0 != .__init__})
//		//		if  !(callbacks_count == 0 && !new_class) && _user_functions.isEmpty &&
//		//				clsMethods.isEmpty && pySequenceMethods.isEmpty && init_function == nil {
//		//			if bases.isEmpty { return nil }
//		//		}
//		if  !(callbacks_count == 0 && !new_class) && _user_functions.isEmpty && init_function == nil {
//			if bases.isEmpty { return nil }
//		}
		
		let protocolList = MemberDeclListSyntax {
			if let callbacks = callbacks {
				"var py_callback: \(raw: name).PyCallback { get set }"
			}
			for f in functions ?? [] {
				f.function_header
			}
//			for base_method in getBaseMethods() {
//				base_method
//			}
		}
		let base_methods = getBaseMethods()
		
		let _protocol = ProtocolDeclSyntax(
			modifiers: [.init(name: .keyword(.public))],
			protocolKeyword: .keyword(.protocol),
			name: .identifier("\(name)_PyProtocol"),
			inheritanceClause: protocolConformances) {
				protocolList
			}
		
		return _protocol.with(\.leadingTrivia, .newlines(2)).with(\.trailingTrivia, .newlines(2))
	}
}



