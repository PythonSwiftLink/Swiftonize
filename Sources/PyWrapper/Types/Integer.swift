
import Foundation
import PyAst


public extension PyWrap {
	
	struct IntegerType<T: BinaryInteger>: TypeProtocol {
		public static func fromAST(ast: AST.Name, type: PythonType) -> PyWrap.IntegerType<T> {
			fatalError()
		}
		public var wrapped = T.self
		public var ast: AstType?
		
		public typealias AstType = AST.Name
		
		public var py_type: PythonType
		
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
		public var string: String { "\(T.self)" }
	}
	
}


extension PyWrap {
	
	static func integerFromAST(_ ast: IntegerType.AstType, type: PythonType, ast_arg: AST.Arg) -> AnyArg {
		switch type {
		case .int, .long:
			//return IntegerType<Int>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<Int>(from: ast, type: type))
		case .ulong, .uint:
//			return IntegerType<UInt>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<UInt>(from: ast, type: type))
		case .int32:
//			return IntegerType<Int32>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<Int32>(from: ast, type: type))
		case .uint32:
//			return IntegerType<UInt32>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<UInt32>(from: ast, type: type))
		case .int8, .char:
//			return IntegerType<Int8>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<Int8>(from: ast, type: type))
		case .uint8, .uchar:
//			return IntegerType<UInt8>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<UInt8>(from: ast, type: type))
		case .uint16, .ushort:
//			return IntegerType<UInt16>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<UInt16>(from: ast, type: type))
		case .int16, .short:
//			return IntegerType<Int>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<Int16>(from: ast, type: type))
		case .longlong:
//			return IntegerType<CLongLong>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<CLongLong>(from: ast, type: type))
		case .ulonglong:
//			return IntegerType<CUnsignedLongLong>(from: ast, type: type)
			return IntegerArg(ast: ast_arg, type: IntegerType<CUnsignedLongLong>(from: ast, type: type))
		default: fatalError()
		}
	}
	
	static func integerFromAST(_ ast: IntegerType.AstType, type: PythonType) -> any TypeProtocol {
		switch type {
		case .int, .long:
			return IntegerType<Int>(from: ast, type: type)
		case .ulong, .uint:
			return IntegerType<UInt>(from: ast, type: type)
		case .int32:
			return IntegerType<Int32>(from: ast, type: type)
		case .uint32:
			return IntegerType<UInt32>(from: ast, type: type)
		case .int8, .char:
			return IntegerType<Int8>(from: ast, type: type)
		case .uint8, .uchar:
			return IntegerType<UInt8>(from: ast, type: type)
		case .uint16, .ushort:
			return IntegerType<UInt16>(from: ast, type: type)
		case .int16, .short:
			return IntegerType<Int>(from: ast, type: type)
		case .longlong:
			return IntegerType<CLongLong>(from: ast, type: type)
		case .ulonglong:
			return IntegerType<CUnsignedLongLong>(from: ast, type: type)
		default: fatalError()
		}
	}
}


extension PyWrap.IntegerType: CustomStringConvertible {
	public var description: String { "\(T.self)" }
}
