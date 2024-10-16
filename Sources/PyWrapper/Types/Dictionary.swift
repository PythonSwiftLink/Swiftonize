import Foundation
import PyAst


public extension PyWrap {
	
	struct DictionaryType: TypeProtocol {
		
		public var ast: AstType?
		
		public let py_type = PythonType.optional
		public typealias AstType = AST.Subscript
		public var lower: any TypeProtocol
		public var upper: any TypeProtocol
		
		public init(from ast: AstType, type: PythonType) {
			self.ast = ast
			guard 
				let slice = ast.slice as? AST.Slice,
				let lower = slice.lower, let upper = slice.upper
			else { fatalError() }
			self.lower = PyWrap.fromAST(any_ast: lower)
			self.upper = PyWrap.fromAST(any_ast: upper)
		}
		
//		public init(expr ast: ExprProtocol) {
//			wrapped = PyWrap.fromAST(ast)
//		}
//		public init(type: any TypeProtocol) {
//			wrapped = type
//		}
		public var string: String { "[\(lower.string):\(upper.string)]" }
	}
	
}

extension PyWrap {
	
}


extension PyWrap.DictionaryType: CustomStringConvertible {
	public var description: String { "\(Self.self)<[\(lower.self) : \(upper.self)]>"}
}
