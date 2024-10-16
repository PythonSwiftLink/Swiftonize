//
//  File.swift
//  
//
//  Created by CodeBuilder on 14/12/2023.
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
			
			//            if let methods = pyMethodDefHandler {
			//                methods
			//            }
			ExtensionDeclSyntax(extensionKeyword: .keyword(.extension), extendedType: TypeSyntax(stringLiteral: title)) {
				if callbacks.count > 0 {
					PyCallbacksGenerator(cls: self).code.with(\.leadingTrivia, .newline)
				}
				pySwiftTypeInType.with(\.leadingTrivia, .newline)
				pySwiftTypeForCheckInType.with(\.leadingTrivia, .newline)
				
				createPyClassExtension
				createPyClassUnRetainedExtension
				createPyObjectClassExtension
				createPyObjectClassUnretainedExtension
			}
			
		
			if let pyProtocol = pyProtocol {
				pyProtocol.with(\.leadingTrivia, .newline)
			}
			
		}.with(\.leadingTrivia, .newline)
		
		
	}
	
	public var pySwiftTypeInType: VariableDeclSyntax {
		let name = PatternSyntax(stringLiteral: "\(title)PyType")
		//let name = PatternSyntax(identifier: .identifier("\(title)PyType"))
		let var_decl = VariableDeclSyntax(modifiers: [.init(name: .keyword(.public)), .init(name: .keyword(.static))],.let, name: name, initializer: createPySwiftType.initClause )
		return var_decl
	}
	public var pySwiftTypeForCheckInType: VariableDeclSyntax {
		//let name = IdentifierPatternSyntax(identifier: .identifier("pyType"))
		let name = PatternSyntax(stringLiteral: "pyType")
		let var_decl = VariableDeclSyntax(modifiers: [.init(name: .keyword(.public)),.init(name: .keyword(.static))],.let, name: name, initializer: .init(value:  ExprSyntax(stringLiteral: "\(title)PyType.pytype")) )
		return var_decl
	}
	fileprivate var createPyClassExtension: FunctionDeclSyntax {
		try! .init(
		"""
		public static func asPyPointer(_ target: \(raw: title)) -> PyPointer {
			let new = PySwiftObject_New(pyType)
			PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
			return new!
		}
		"""
		).with(\.leadingTrivia, .newline)
	}

	fileprivate var createPyObjectClassExtension: FunctionDeclSyntax {
		try! .init("""
		public static func asPythonObject(_ target: \(raw: title)) -> PythonObject {
			let new = PySwiftObject_New(pyType)!
			PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
			return .init(ptr: new, from_getter: true)
		}
		""").with(\.leadingTrivia, .newline)
	}
	
	fileprivate var createPyClassUnRetainedExtension: FunctionDeclSyntax {
		try! .init("""
		public static func asPyPointer(unretained target: \(raw: title)) -> PyPointer {
			let new = PySwiftObject_New(pyType)
			PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
			return new!
		}
		""").with(\.leadingTrivia, .newline)
	}
	fileprivate var createPyObjectClassUnretainedExtension: FunctionDeclSyntax {
		try! .init("""
		public static func asPythonObject(unretained target: \(raw: title)) -> PythonObject {
			let new = PySwiftObject_New(pyType)!
			PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
			return .init(ptr: new, from_getter: true)
		}
		""").with(\.leadingTrivia, .newline)
	}
}
