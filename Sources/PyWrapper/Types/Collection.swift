
import Foundation
import PyAst


import Foundation
import PyAst

public protocol CollectionTypeProtocol: TypeProtocol {
	associatedtype Wrapped: TypeProtocol
	var wrapped: Wrapped { get }
}

public extension PyWrap {
	//static func collectionInCollection(_ ast: AST.Subscript, type: PythonType, ast_arg: AST.Arg)
//	static func collectionFromAST(_ ast: AST.Subscript, type: PythonType, ast_arg: AST.Arg) -> AnyArg {
//		switch type {
//		case .int, .long:
//			//let t = IntegerType<Int>(from: ast, type: type)
//			//let ct = PyWrap.integerFromAST(<#T##ast: AST.Name##AST.Name#>, type: <#T##PythonType#>, ast_arg: <#T##AST.Arg#>)
//			//let ct = CollectionType<IntegerType<Int>>.init(from: <#T##AST.Subscript#>, type: <#T##PythonType#>)
//			return CollectionArg<IntegerType<Int>>.init(ast: ast_arg, sub: ast, type: type)
//		case .ulong, .uint:
//			return IntegerType<UInt>(from: ast, type: type)
//		case .int32:
//			return IntegerType<Int32>(from: ast, type: type)
//		case .uint32:
//			return IntegerType<UInt32>(from: ast, type: type)
//		case .int8, .char:
//			return IntegerType<Int8>(from: ast, type: type)
//		case .uint8, .uchar:
//			return IntegerType<UInt8>(from: ast, type: type)
//		case .uint16, .ushort:
//			return IntegerType<UInt16>(from: ast, type: type)
//		case .int16, .short:
//			return IntegerType<Int>(from: ast, type: type)
//		case .longlong:
//			return IntegerType<CLongLong>(from: ast, type: type)
//		case .ulonglong:
//			return IntegerType<CUnsignedLongLong>(from: ast, type: type)
//		default: fatalError()
//		}
//	}
//		
	
	static func collectionElement(from ast: AST.Tuple, dims: inout Int) -> any TypeProtocol {
		var ast = ast
		var elts = ast.elts
		if elts.count > 1 {
			if let last = elts.last, last.type == .Constant {
				
				if let last = last as? AST.Constant, let dimsValue = last.intValue {
					dims = dimsValue
				}
				ast.elts.removeLast()
			}
		}
		return TupleType(from: ast)
		
	}
	
	struct CollectionType: TypeProtocol {

		
		public var py_type: PythonType
		public typealias AstType = AST.Subscript
		public var ast: AST.Subscript?
		
		public var element: any TypeProtocol
		public var dims = 1
		
		public init(from ast: AST.Subscript, type: PythonType) {
			self.ast = ast
			self.py_type = type
			let slice = ast.slice
			if slice.type == .Tuple {
				element = PyWrap.collectionElement(from: slice as! AST.Tuple, dims: &dims)
			} else {
				self.element = PyWrap.fromAST(any_ast: ast.slice)
			}
		}
//		init(py_type: PythonType, ast: AST.Subscript, wrapped: E) {
//			self.py_type = py_type
//			self.ast = ast
//			self.wrapped = wrapped
//		}
		public var string: String { "[\(element.string)]" }
	}
	
}

extension PyWrap.CollectionType: CustomStringConvertible {
	public var description: String { "\(element)"}
}

