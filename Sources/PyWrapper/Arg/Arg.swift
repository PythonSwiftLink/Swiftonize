import Foundation
import PyAst

public protocol ArgProtocol: AnyObject {
	associatedtype T: TypeProtocol
	
	var type: T { get }
	var ast: AST.Arg { get }
	var index: Int? { get set }
	var options: [ArgOption] { get set }
	
	init(ast: AST.Arg, type: T)
}



	public enum ArgOption {
		case no_label
		case optional_name(String)
	}


public typealias AnyArg = any ArgProtocol

func playtest() {
	let int: AnyArg = PyWrap.IntegerArg<Int32>.init(ast: .init(label: "test"), type: .init(from: .init(id: "test"), type: .int32))
	let string: AnyArg = PyWrap.StringArg(ast: .init(label: "b"), type: .init(ast: .init(id: "b"), py_type: .str))
	let fake = JSONDecoder()
	let sub = try! fake.decode(AST.Subscript.self, from: .init())
	//let collect: AnyArg = PyWrap.CollectionArg<PyWrap.IntegerType<Int32>>.init(ast: .init(label: "c"), type: .init(from: sub, type: .list))
	
}


public extension PyWrap {
	
	final class DataArg: ArgProtocol {
		public var type: T
		
		public var ast: PyAst.AST.Arg
		
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: PyAst.AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
		
		public typealias T = DataType
		
		
	}
	
	final class CollectionArg: ArgProtocol {
		public typealias T = CollectionType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
		
		public init(ast: AST.Arg,sub: AST.Subscript, type: PythonType) {
			self.ast = ast
			self.type = CollectionType(from: sub, type: type)
		}
	}
    
    final class MemoryViewArg: ArgProtocol {
        public typealias T = MemoryViewType
        public var ast: AST.Arg
        public var type: T
        public var index: Int?
        
        public var options: [ArgOption] = []
        
        public init(ast: AST.Arg, type: T) {
            self.ast = ast
            self.type = type
        }
        
        public init(ast: AST.Arg,sub: AST.Subscript, type: PythonType) {
            self.ast = ast
            self.type = MemoryViewType(from: sub, type: type)
        }
    }
    
    
	
	final class CallableArg: ArgProtocol {
		public typealias T = PyWrap.CallableType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
		
		public init(ast: AST.Arg,sub: AST.Subscript, type: PythonType) {
			self.ast = ast
			self.type = CallableType(from: sub, type: type)
		}
		
		public init(ast: AST.Arg) {
			self.ast = ast
			self.type = CallableType()
		}
	}
	
	final class TupleArg: ArgProtocol {
		public typealias T = PyWrap.CollectionType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
		
		public init(ast: AST.Arg,sub: AST.Subscript, type: PythonType) {
			self.ast = ast
			self.type = CollectionType(from: sub, type: type)
		}
		
		
	}
	
	final class StringArg: ArgProtocol {
		public typealias T = PyWrap.StringType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
	}
	
	final class IntegerArg<I: BinaryInteger>: ArgProtocol {
		public typealias T = PyWrap.IntegerType<I>
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
	}
	
	final class FloatingPointArg<F: FloatingPoint>: ArgProtocol {
		public typealias T = PyWrap.FloatingPointType<F>
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
	}
	
	final class DictionaryArg: ArgProtocol {
		public typealias T = PyWrap.DictionaryType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
	}
	
	final class OptionalArg: ArgProtocol {
		public typealias T = PyWrap.OptionalType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
	}
	
	final class PyObjectArg: ArgProtocol, CustomStringConvertible {
		public typealias T = PyWrap.PyObjectType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
		
		public init(ast: AST.Arg) {
			self.ast = ast
			self.type = .init()
		}
		public var description: String { "\(name): \(type)"}
	}
	
	final class BoolArg: ArgProtocol, CustomStringConvertible {
		public typealias T = PyWrap.BoolType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
		
		public init(ast: AST.Arg) {
			self.ast = ast
			self.type = .init(ast: .init(id: "object"), py_type: .object)
		}
		
		public var description: String { "\(name): \(type)"}
	}
	
	
	final class OtherArg: ArgProtocol {
		public typealias T = PyWrap.OtherType
		public var ast: AST.Arg
		public var type: T
		public var index: Int?
		
		public var options: [ArgOption] = []
		
		public init(ast: AST.Arg, type: T) {
			self.ast = ast
			self.type = type
		}
		
//		public init(ast: AST.Arg) {
//			self.ast = ast
//			self.type = .init(from: <#PyWrap.OtherType.AstType#>, type: <#PythonType#>)
//		}
	}
//	class Arg {
//		public init(type: any TypeProtocol, ast: AST.Arg? = nil, index: Int? = nil) {
//			self.type = type
//			self.ast = ast
//		}
//		//typealias T = T
//		public var type: any TypeProtocol
//		
//		public var ast: AST.Arg?
//		
//		public var index: Int?
//		
//		
//		init(type: any TypeProtocol) {
//			self.type = type
//			fatalError()
//		}
//		init(ast: AST.Arg) {
//			self.ast = ast
//			
//			
//			
//			fatalError()
//		}
//		
//		public var name: String { ast?.arg ?? "NULL"}
//		
//		public var optional_name: String? { nil }
//		
//		public var no_label: Bool { false }
//	}
    
    final class WeakRefArg: ArgProtocol {
        public typealias T = PyWrap.WeakRefType
        public var ast: AST.Arg
        public var type: T
        public var index: Int?
        
        public var options: [ArgOption] = []
        
        public init(ast: AST.Arg, type: T) {
            self.ast = ast
            self.type = type
        }
    }
}


//extension PyWrap.Arg {
//	static func fromName(_ ast: AST.Name) -> Self? {
//		if let type = PythonType(rawValue: ast.id) {
//			//print("\t\t\t\(type)")
//			let t: (any ArgType).Type = PyWrap.fromAST()
//			return Self.init(type: <#T##ArgType#>)
//			
//		} else {
//			//print("\t\t\t\(PythonType.other)<\(name.id)>")
//		}
//		return nil
//	}
//}

