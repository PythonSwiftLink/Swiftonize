
import Foundation
import PyAst


import Foundation
import PyAst

public protocol TupleTypeProtocol: TypeProtocol {
	var types: [any TypeProtocol] {get}
}

public extension PyWrap {
	struct TupleType<A: ExprProtocol>: TupleTypeProtocol {
		
		
		public var py_type: PythonType
		public typealias AstType = A
		public var ast: A?
		
		public var types: [any TypeProtocol]
		
		
		public init(from ast: A, type: PythonType = .tuple) {
			self.ast = ast
			self.py_type = type
			//self.elements = PyWrap.fromAST(any_ast: ast.slice)
			fatalError()
		}
		public init(from ast: A, type: PythonType = .tuple) where A == AST.Tuple {
			self.ast = ast
			self.py_type = type
			types = ast.elts.map(PyWrap.fromAST(any_ast:))
			//self.elements = PyWrap.fromAST(any_ast: ast.slice)
		}
		
		public init(from ast: A, type: PythonType = .tuple) where A == AST.List {
			self.ast = ast
			self.py_type = type
			types = ast.elts.map(PyWrap.fromAST(any_ast:))
			//self.elements = PyWrap.fromAST(any_ast: ast.slice)
		}
		
		public init(from ast: A, type: PythonType = .tuple) where A == AST.Name {
			self.ast = ast
			self.py_type = type
			types = [PyWrap.fromAST(any_ast: ast)]
			//self.elements = PyWrap.fromAST(any_ast: ast.slice)
		}
		
		public init() {
			py_type = .tuple
			types = []
		}
		//		init(py_type: PythonType, ast: AST.Subscript, wrapped: E) {
		//			self.py_type = py_type
		//			self.ast = ast
		//			self.wrapped = wrapped
		//		}
		
	}
	
}
extension Array where Element == any TypeProtocol {
	var tuple_description: String {
		map(String.init(describing:)).joined(separator: ", ")
	}
}
extension PyWrap.TupleType: CustomStringConvertible {
	public var description: String { "(\(self.types.tuple_description))"}
	public var string: String { "(\(self.types.tuple_description))" }
}

