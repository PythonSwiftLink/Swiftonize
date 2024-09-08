

import Foundation
import PyAst

public protocol BaseTypeProtocol {
	var name: String { get }
	var base_options: PyWrap.BaseTypeOptions { get }
	var functions: [PyWrap.Function]? { get }
	var properties: [any ClassProperty]? { get }
	var options: PyWrap.ClassOptions { get }
	
	var ast: AST.ClassDef? { get }
}

extension PyWrap {
	final public class BaseType: PyWrap.Class, BaseTypeProtocol {
		
		
		public var base_options: BaseTypeOptions
		
		
		
		public init(ast: AST.ClassDef) throws {
			base_options = .init()
			try super.init(ast: ast)
			
		}
		
	}
	final public class GenericBaseType: PyWrap.Class, BaseTypeProtocol {
		
		
		public var base_options: BaseTypeOptions
		//public var generic_types: [String]
		
		
		public init(ast: AST.ClassDef) throws {
			base_options = .init()
			
			try super.init(ast: ast)
			//fatalError(ast.description)
		}
		
	}
	public final class TypeVar {
		public var name: String
		public var types: [String]
		public var ast: AST.Call?
		
		public init(_ ast: AST.Call) throws {
			var args = ast.args
			let first = args.removeFirst()
			guard let n = (first as? AST.Constant)?.value else { throw SwiftonizeModuleError.Assign("TypeVar extraction failed <\(first.type)>") }
			self.name = n
			types = args.lazy.compactMap({$0 as? AST.Name}).map(\.id)
			self.ast = ast
		}
	}
	
}


extension PyWrap {
	public class BaseTypeOptions {
		
	}
}
extension Array where Element == any ExprProtocol {
	func contains(name: String) -> Bool {
		self.contains { expr in
			switch expr.type {
			case .Name:
				//
				if let _name = expr as? AST.Name {
					return _name.id == name
				}
			case .Subscript:
				if let sub = expr as? AST.Subscript, let _name = sub.value as? AST.Name {
					return _name.id == name
				}
			case .Call:
				if let call = expr as? AST.Call {
					//fatalError()
					if let _name = call._func as? AST.Name {
						return _name.id == name
					}
				}
			default: fatalError("\(expr.type)")
			}
			
			return false
		}
	}
}

func handleBaseTypes(_ classes: [AST.ClassDef]) throws -> [BaseTypeProtocol] {
	
	return try classes.lazy
		.filter({$0.decorator_list.contains(name: "wrapper_base")})
		.map(PyWrap.BaseType.init)
}

func handleTypeVars(_ assigns: [AST.Assign]) throws -> [PyWrap.TypeVar] {
	
	try assigns.lazy.compactMap({$0.value as? AST.Call}).map(PyWrap.TypeVar.init)
}
