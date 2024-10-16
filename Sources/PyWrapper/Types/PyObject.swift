
import Foundation
import PyAst


public extension PyWrap {
	
	struct PyObjectType: TypeProtocol {
		public static func fromAST(ast: PyAst.AST.Name, type: PythonType) -> PyWrap.PyObjectType {
			fatalError()
		}
		
		
		public var ast: AstType?
		
		public typealias AstType = AST.Name
		
		public var py_type: PythonType = .object
		
		init(ast: PyAst.AST.Name, py_type: PythonType) {
			self.ast = ast
			self.py_type = py_type
			
		}
		public init(from ast: AST.Name, type: PythonType) {
			self.ast = ast
			self.py_type = type
		}
		
		public init() {
			
		}
		
		public static func fromAST(_ ast: PyAst.AST.Name, type: PythonType) -> any TypeProtocol {
			Self.init(ast: ast, py_type: type)
		}
		public var string: String { "PyPointer" }
	}
	
}

extension PyWrap.PyObjectType: CustomStringConvertible {
	public var description: String { "PyObject" }
}


