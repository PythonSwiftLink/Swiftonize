
import Foundation
import PyWrapper
import SwiftSyntax
import SwiftSyntaxBuilder


extension PyWrap.Class {

	func generic_extensions() throws -> [ExtensionDeclSyntax] {
		let bases = bases()
		var output = [ExtensionDeclSyntax]()
		for t in options.generic_typevar?.types ?? [] {
			let generic_name = "\(name)<\(t)>"
			output.append( .init(extendedType: TypeSyntax(stringLiteral: generic_name)) {
				tp_new()
				tp_init(target: generic_name)
				tp_dealloc(target: generic_name)
				
				if bases.contains(.Str) {
					tp_str(target: generic_name)
					tp_repr(target: generic_name)
				}
				if bases.contains(.Hashable) { tp_hash(target: generic_name) }
				
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
				//pyTypeObject()
				genericPyTypeObject(target: t)
				//createPyTypePointer(target: "\(name)_\(t)_PyTypeObject)")
				createPyTypePointer()
				
				//createPyClassExtension(target: generic_name)
				//createPyClassUnRetainedExtension(target: generic_name)
				//createPyObjectClassExtension
				//createPyObjectClassUnretainedExtension
				
			})
		}
		return output
	}
}




extension PyWrap.Class {
	func genericPyTypeObject(target: String) -> VariableDeclSyntax {
		let _init_ = InitializerClauseSyntax(value:
												//ClosureExprSyntax {
			//ClosureExprSyntax {
				PyTypeObjectGenerator(cls: self, target: "\(name)<\(target)>", typevar: target).functionCallExpr()
			//}
		//}
		)
		//let type_var_name = "\(name)_\(target)_PyTypeObject"
		let type_var_name = "pyTypeObject"
//		let binding: PatternBindingListSyntax = .init {
//			.init(
//				pattern: IdentifierPatternSyntax(identifier: .identifier(type_var_name)),
//				typeAnnotation: .init(type: TypeSyntax(stringLiteral: "PyTypeObject")),
//				accessorBlock: AccessorBlockSyntax(accessors: .getter(.init {
//					PyTypeObjectGenerator(cls: self).functionCallExpr()
//				})
//			)
//			)
//		}
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: type_var_name),
			type: .init(type: TypeSyntax(stringLiteral: "PyTypeObject")),
			initializer: _init_
		).with(\.trailingTrivia, .newlines(2))
//		return .init(
//			modifiers: [ .init(name: .keyword(.fileprivate))],
//			bindingSpecifier: .keyword(.var),
//			bindings: binding
//		)
	}
}


fileprivate extension PyWrap.Class {
	
	
	
	fileprivate func create_tp_init(target: String) -> ClosureExprSyntax {
		
		let closure = ExprSyntax(stringLiteral: "{ __self__, _args_, kw -> Int32 in }").as(ClosureExprSyntax.self)!
		return closure.with(\.statements, .init {
			//if debug_mode { ExprSyntax(stringLiteral: #"print("tp_init - <\#(title)>")"#) }
			//createTP_Init(cls: self, args: init_function?._args_ ?? []).code
			ObjectInitializer(_cls: self, generic_target: target).codeBlock
			"return 1"
		})
		
	}
	
	fileprivate func tp_init(target: String) -> VariableDeclSyntax {
		
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_init"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_initproc")),
			initializer: .init(value: create_tp_init(target: target))
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
	
	fileprivate func tp_dealloc(target: String) -> VariableDeclSyntax {
		
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_dealloc"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_destructor")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
   { s in
   if let ptr = s?.pointee.swift_ptr {
   Unmanaged<\(target)>.fromOpaque(ptr).release()
   }
   }
   """)).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	fileprivate func tp_str(target: String) -> VariableDeclSyntax {
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_str"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_reprfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
 { __self__ in
  return UnPackPySwiftObject(with: __self__, as: \(target).self).__str__().pyPointer
 }
 """))//.with(\.trailingTrivia, .newlines(2))
		)
	}
	
	fileprivate func tp_repr(target: String) -> VariableDeclSyntax {
		return .init(
			modifiers: [.init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_repr"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_reprfunc")),
			initializer: .init(value: ExprSyntax(stringLiteral: """
 { __self__ in
  return UnPackPySwiftObject(with: __self__, as: \(target).self).__repr__().pyPointer
 }
 """)).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	
	fileprivate func tp_hash(target: String) -> VariableDeclSyntax {
		let expr = ExprSyntax(stringLiteral: """
   { __self__ in
   return UnPackPySwiftObject(with: __self__, as: \(target).self).__hash__()
   }
   """).as(ClosureExprSyntax.self)!
		
		return .init(
			modifiers: [ .init(name: .keyword(.static))], .var,
			name: .init(stringLiteral: "tp_hash"),
			type: .init(type: TypeSyntax(stringLiteral: "PySwift_hashfunc")),
			initializer: .init(value: expr).with(\.trailingTrivia, .newlines(2))
		)
	}
	
	
	
	fileprivate func createPyClassExtension(target: String) -> FunctionDeclSyntax {
		try! .init(
  """
  public static func asPyPointer(_ target: \(raw: target)) -> PyPointer {
  let new = PySwiftObject_New(\(raw: target).PyType)
  PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
  return new!
  }
  """
		).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate func createPyObjectClassExtension(target: String) -> FunctionDeclSyntax {
		try! .init("""
  public static func asPythonObject(_ target: \(raw: target)) -> PythonObject {
  let new = PySwiftObject_New(\(raw: target).PyType)!
  PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
  return .init(ptr: new, from_getter: true)
  }
  """).with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate func createPyClassUnRetainedExtension(target: String) -> FunctionDeclSyntax {
		try! .init("""
  public static func asPyPointer(unretained target: \(raw: target)) -> PyPointer {
  let new = PySwiftObject_New(\(raw: target).PyType)
  PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
  return new!
  }
  """).with(\.trailingTrivia, .newlines(2))
	}
	fileprivate func createPyObjectClassUnretainedExtension(target: String) -> FunctionDeclSyntax {
		try! .init("""
  public static func asPythonObject(unretained target: \(raw: target)) -> PythonObject {
  let new = PySwiftObject_New(\(raw: target).PyType)!
  PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
  return .init(ptr: new, from_getter: true)
  }
  """)//.with(\.trailingTrivia, .newlines(2))
	}
	
	fileprivate func createPyTypePointer(target: String? = nil) -> DeclSyntax {
		DeclSyntax(stringLiteral: """
  public static let PyType: UnsafeMutablePointer<PyTypeObject> = {
  let t: UnsafeMutablePointer<PyTypeObject> = .init(&\(target ?? "pyTypeObject"))
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
	
	
}



