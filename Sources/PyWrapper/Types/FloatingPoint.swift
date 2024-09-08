import Foundation
import PyAst


public extension PyWrap {
	
	struct FloatingPointType<T: FloatingPoint>: TypeProtocol, CustomStringConvertible {
		
		public var ast: AstType?
		
		public typealias AstType = AST.Name
		
		public var py_type: PythonType
		
		public var wrapped = T.self
		
		init(ast: PyAst.AST.Name, py_type: PythonType) {
			self.ast = ast
			self.py_type = py_type
			
		}
		public init(from ast: AST.Name, type: PythonType) {
			self.ast = ast
			self.py_type = type
		}
		
		public static func fromAST(_ ast: PyAst.AST.Name, type: PythonType) -> any TypeProtocol {
			Self.init(ast: ast, py_type: type)
		}
		public var description: String { "\(T.self)" }
		public var string: String { "\(T.self)" }
	}
	
}



extension PyWrap {
	static func floatFromAST(_ ast: FloatingPointType.AstType, type: PythonFloatingPoints) -> any TypeProtocol {
		switch type {
		case .float:
			return FloatingPointType<Double>(ast: ast, py_type: .double)
		case .double:
			return FloatingPointType<Double>(ast: ast, py_type: .double)
		case .float32:
			return FloatingPointType<Float32>(ast: ast, py_type: .float32)
		}
		
	}
	static func floatFromAST(_ ast: FloatingPointType.AstType, type: PythonFloatingPoints, ast_arg: AST.Arg) -> AnyArg {
		switch type {
		case .float:
			let t = FloatingPointType<Double>(ast: ast, py_type: .float)
			return FloatingPointArg(ast: ast_arg, type: t)
		case .double:
			let t = FloatingPointType<Double>(ast: ast, py_type: .double)
			return FloatingPointArg(ast: ast_arg, type: t)
		case .float32:
			let t = FloatingPointType<Float32>(ast: ast, py_type: .float32)
			return FloatingPointArg(ast: ast_arg, type: t)
		}
		
	}
}
