//
//  File.swift
//  
//
//  Created by CodeBuilder on 18/02/2024.
//

import Foundation
import PyAst

public protocol ClassProperty {
	var prop_type: any TypeProtocol { get }
	associatedtype S: Stmt
	var stmt: S { get }
	
	var name: String { get }
	
	var target_name: String? { get }
	
	var property_type: PyWrap.Class.PropertyType { get }
}

extension ClassProperty {
	public var lineno: Int { stmt.lineno ?? -1}
	
	public var col_offset: Int { stmt.lineno ?? -1}
	
	public var end_lineno: Int? { stmt.end_lineno }
	
	public var end_col_offset: Int? { stmt.end_col_offset }
	
	public var type_comment: String? { stmt.type_comment }
}

public extension PyWrap.Class {
	static func propertyFromAST(ast: AST.AnnAssign) -> any ClassProperty {
		Property(stmt: ast)
	}
	static func propertyFromAST(ast: Stmt) -> any ClassProperty {
		switch ast.type {
		case .AnnAssign:
			return Property(stmt: ast as! AST.AnnAssign)
		default: fatalError()
		}
	}
	
	
	enum PropertyType: String, Codable, CaseIterable {
		case Getter
		case GetSet
		case Property
		case NumericProperty
		case StringProperty
	}
	struct Property<S: Stmt>: ClassProperty {

		
		
		
		
		public var prop_type: any TypeProtocol
		public typealias S = S
		public var stmt: S
		
		public var index: Int?
		
		
		
		public let name: String
		public let property_type: PropertyType
		//let arg_type: WrapArg
		//public let arg_type: WrapArgProtocol
		
		public let target_name: String?
		
		public init(stmt: S) {
			fatalError()
		}
		public init(stmt: S) where S == AST.Assign {
			self.stmt = stmt
			self.name = (stmt.targets.first! as! AST.Name).id
			let info = PropertyInfo(ast: stmt.value)
			self.prop_type = info.type
			self.property_type = info.setter ? .GetSet : .Getter
			self.target_name = info.target
		}
		public init(stmt: S) where S == AST.AnnAssign {
			self.stmt = stmt
			if let value = stmt.value {
				let info = PropertyInfo(ast: value)
				self.prop_type = info.type
				self.property_type = info.setter ? .GetSet : .Getter
			} else {
				self.prop_type = PyWrap.fromAST(any_ast: stmt.annotation)
				self.property_type = .GetSet
			}
			
			self.name = (stmt.target as! AST.Name).id
			
			self.target_name = nil
		}
		
		
//		public init(name: String, property_type: PropertyType, type: T, target_name: String? = nil) {
//			self.name = name
//			self.property_type = property_type
//			self.prop_type = type
//			self.target_name = target_name
//			//self.arg_type_new = handleWrapArgTypes(args: [arg_type]).first!
//		}
		
		
	}
}


extension PyWrap.Class.Property {
	struct PropertyInfo {
		var readonly: Bool
		var setter: Bool { !readonly }
		var type: any TypeProtocol
		var alias: String?
		var target: String? { alias }
		
		
		init(ast: ExprProtocol) {
			if let ast = ast as? AST.Call, let name = ast._func as? AST.Name, name.id == "WrappedProperty" {
				readonly = ast.keywords.reduce(into: false) { partialResult, next in
					if let key = next.arg, key.lowercased() == "readonly" {
						
						if let value = next.value as? AST.Constant {
							
							let bool = value.boolValue
							//print(bool)
							partialResult = bool
							//return bool
						}
					}
				}
		
//				readonly = ast.keywords.map( { kw in
//					if let key = kw.arg, key.lowercased() == "readonly" {
//						
//						if let value = kw.value as? AST.Constant {
//							
//							let bool = value.boolValue
//							//print(bool)
//							
//							return bool
//						}
//					}
//					return true
//				}).first ?? false
				if let arg = ast.args.first {
					type = PyWrap.fromAST(any_ast: ast.args.first!)
				} else {
					type = PyWrap.PyObjectType()
				}
				alias = (ast.keywords.first(where: { kw in
					if let key = kw.arg, key.lowercased() == "alias" {
						return true
					}
					return false
				})?.value as? AST.Constant)?.value
				
			} else {
				readonly = false
				type = PyWrap.PyObjectType()
			}
		}
	}
}
