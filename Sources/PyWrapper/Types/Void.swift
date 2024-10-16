
import Foundation
import PyAst


public extension PyWrap {
	
	struct VoidType<E: ExprProtocol>: TypeProtocol {
		public static func fromAST(ast: PyAst.AST.Name, type: PythonType) -> PyWrap.PyObjectType {
			fatalError()
		}
		
		
		public var ast: AstType?
		
		public typealias AstType = E
		
		public var py_type: PythonType = .void
		
		public init(from ast: AstType, type: PythonType) {
			self.ast = ast
			self.py_type = type
			
		}
		
		
		public init() {
			
		}
		
		
	}
	
}

extension PyWrap.VoidType: CustomStringConvertible {
	public var description: String { "Void" }
	public var string: String { "Void" }
}


