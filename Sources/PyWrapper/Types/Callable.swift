
import Foundation
import PyAst


import Foundation
import PyAst

//public protocol CollectionTypeProtocol {
//	associatedtype Wrapped: TypeProtocol
//	var wrapped: Wrapped { get }
//}

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
	
//	static func collectionElement(from ast: AST.Tuple, dims: inout Int) -> any TypeProtocol {
//		var ast = ast
//		var elts = ast.elts
//		if elts.count > 1 {
//			if let last = elts.last, last.type == .Constant {
//				
//				if let last = last as? AST.Constant, let dimsValue = last.intValue {
//					dims = dimsValue
//				}
//				ast.elts.removeLast()
//			}
//		}
//		return TupleType(from: ast)
//		
//	}
	
	fileprivate static func argsFromAST(ast: ExprProtocol) -> any TupleTypeProtocol {
		switch ast.type {
		case .Tuple: return TupleType(from: ast as! AST.Tuple)
		case .List: return TupleType(from: ast as! AST.List)
		case .Name: return TupleType(from: ast as! AST.Name)
		default: fatalError(ast.type.rawValue)
		}
		
		
		return TupleType<AST.Tuple>()
	}
	
	struct CallableType: TypeProtocol {
		
		
		public var py_type: PythonType = .callable
		public typealias AstType = AST.Subscript
		public var ast: AST.Subscript?
		
		public var input: any TupleTypeProtocol
		public var output: (any TypeProtocol)?
		//public var element: any TypeProtocol
		//public var dims = 1
		
		public init(from ast: AST.Subscript, type: PythonType) {
			self.ast = ast
			self.py_type = type
			let slice = ast.slice
			switch slice {
			case let tuple as AST.Tuple:
				let elts = tuple.elts
				input = PyWrap.argsFromAST(ast: elts[0])
				output = PyWrap.fromAST(any_ast: elts[1])
				
			case let list as AST.List:
				let elts = list.elts
				input = PyWrap.argsFromAST(ast: elts[0])
				output = PyWrap.fromAST(any_ast: elts[1])
			case let name as AST.Name:
				input = TupleType(from: name)
			default: fatalError()
			}
			
//			dump(input)
//			fatalError()
		}
		init() {
			input = TupleType<AST.Tuple>()
		}
		//		init(py_type: PythonType, ast: AST.Subscript, wrapped: E) {
		//			self.py_type = py_type
		//			self.ast = ast
		//			self.wrapped = wrapped
		//		}
		
	}
	
}

extension PyWrap.CallableType: CustomStringConvertible {
	public var description: String { "\(Self.self)"}
	public var string: String { "\(Self.self)" }
}

