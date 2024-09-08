//
//  File.swift
//  
//
//  Created by CodeBuilder on 25/09/2023.
//

import Foundation
import SwiftSyntax
//import SwiftSyntaxParser
import SwiftSyntaxBuilder
import WrapContainers

private enum SwiftBaseTypes: String {
	case Int
	case Int32
	case Int16
	case Int8
	case UInt
	case UInt32
	case UInt16
	case UInt8
	case Float
	case Double
	case String
	case Array
}

//extension WrapArgProtocol {
	
//	func fromSimpleType(name: String, t: SimpleTypeIdentifier, idx: Int) -> WrapArgProtocol {
	func fromSimpleType(name: String, t: IdentifierTypeSyntax, idx: Int) -> WrapArgProtocol {
		let _t = t.name.text
		switch SwiftBaseTypes(rawValue: _t) {
		case .Int, .Int8, .Int16, .Int32, .UInt, .UInt8, .UInt16, .UInt32:
			return intArg(_name: name, _type: .init(rawValue: _t.lowercased())!, _other_type: nil, _idx: idx, _options: [])
		case .Float, .Double:
			return floatArg(_name: name, _type: .init(rawValue: _t.lowercased())!, _other_type: nil, _idx: idx, _options: [])
		case .String:
			return strArg(_name: name, _type: .str, _other_type: nil, _idx: idx, _options: [])
		default: fatalError()
		}
	}
//}


extension FunctionParameterSyntax {
	
	var wrapArg: WrapArgProtocol {
		var _name: String {
			let firstName = firstName.text
			let secondName = secondName?.text
			
			//if let firstName = firstName {
				if firstName.hasPrefix("_") { return secondName  ?? "#ErrorInName" }
				return firstName
			//}
			return "#ErrorInName"
		}
		//if let type = type {
//			
//			switch type.kind {
//			case .identifierType:
//				let simple = type.as(IdentifierTypeSyntax.self)!
//				return fromSimpleType(name: _name, t: simple, idx: self.index)
//			default: break
//			}
//		switch type.kind {
//		case .identifierType:
//			let simple = type.as(IdentifierTypeSyntax.self)!
//			return fromSimpleType(name: _name, t: simple, idx: indexInParent)
//		default: break
//		}
//			
		//}
		
		
		fatalError()
	}
	
	
}

extension WrapFunction {
	
	convenience init(syntax: FunctionDeclSyntax, cls: WrapClass?) {
		let signature = syntax.signature
		self.init(
			name: syntax.identifier.text,
			_args_: signature.input.parameterList.map(\.wrapArg),
			_return_: objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [.return_]),
			options: [],
			wrap_class: cls
		)
	}
}

extension WrapClass {
	
	func extend(from syntax: ClassDeclSyntax ) {
		
		for member in syntax.members.members {
			let decl = member.decl
			switch decl.kind {
			case .functionDecl:
				let fDecl = decl.as(FunctionDeclSyntax.self)!
				if functions.contains(where: {$0.name == fDecl.identifier.text}) {
					functions.append(.init(syntax: fDecl, cls: self))
				}
			default: fatalError("\(decl.kind)")
			}
		}
		
		
		
	}
	
	
}
