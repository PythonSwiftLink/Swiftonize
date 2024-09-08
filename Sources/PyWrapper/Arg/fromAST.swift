//
//  File.swift
//  
//
//  Created by CodeBuilder on 15/02/2024.
//

import Foundation
import PyAst
import SwiftSyntax


public extension PyWrap {
	
	static func asAnyArg(arg ast: AST.Arg) -> AnyArg? {
		let arg_name = ast.arg
		if arg_name == "self" { return nil }
		if let annotation = ast.annotation {
			
			//return .init(type: fromAST(annotation), ast: ast, index: index)
			//return
		}
		
		fatalError()
	}
	
	//	static func fromAST(arg ast: AST.Arg) -> ( Arg)? {
	//		let arg_name = ast.arg
	//		if arg_name == "self" { return nil }
	//		if let annotation = ast.annotation {
	//			return .init(type: fromAST(annotation), ast: ast)
	//		}
	//
	//		return nil
	//	}
	//
	//	static func fromAST(index: Int, ast: AST.Arg) -> Arg? {
	//		let arg_name = ast.arg
	//		if arg_name == "self" { return nil }
	//		if let annotation = ast.annotation {
	//			return .init(type: fromAST(annotation), ast: ast, index: index)
	//		}
	//
	//		return nil
	//	}
	
	//	static func fromAST(expr ast: AST.Arg) -> Arg? {
	//		let arg_name = ast.arg
	//		if arg_name == "self" { return nil }
	//		if let annotation = ast.annotation {
	//			return .init(type: fromAST(annotation), ast: ast)
	//		}
	//
	//		return nil
	//	}
	
	
	static func fromAST(_ ast: ExprProtocol, ast_arg: AST.Arg) -> AnyArg {
		
		let exp_type = ast.type
		switch exp_type {
		case .Constant:
			fatalError(exp_type.rawValue)
		case .NamedExpr:
			fatalError(exp_type.rawValue)
		case .Slice:
			fatalError(exp_type.rawValue)
		case .Subscript:
			if let sub = ast as? AST.Subscript {
				return AST.Subscript.anyArg(sub, ast_arg: ast_arg)
			}
		case .Starred:
			fatalError(exp_type.rawValue)
		case .Name:
			if let name = ast as? AST.Name { return name.anyArg(ast_arg) }
		case .List:
			fatalError(exp_type.rawValue)
		case .Tuple:
			fatalError(exp_type.rawValue)
		case .NoneType:
			fatalError(exp_type.rawValue)
		case .BinOp:
			if let binOp = ast as? AST.BinOp {
				let right = binOp.right
				switch right.type {
				case .Constant:
					
					guard let r_const = (right as? AST.Constant)!.value else {
						//return PyWrap.OptionalType(expr: binOp.left)
						return OptionalArg(ast: ast_arg, type: OptionalType(expr: binOp.left))
					}
					
				default: fatalError("\(#line)")
				}
				
			}
		default:
			fatalError(exp_type.rawValue)
		}
		fatalError()
	}
	static func fromAST<T: TypeProtocol>(_ ast: ExprProtocol) -> T {
		return fromAST(any_ast: ast) as! T
	}
	static func fromAST(tuple: AST.Tuple) -> [any TypeProtocol] {
		tuple.elts.map(fromAST(any_ast:))
	}
	
	static func fromAST(any_ast: ExprProtocol) -> (any TypeProtocol) {
		
		let exp_type = any_ast.type
		switch exp_type {
		case .Constant:
			
			if let const = any_ast as? AST.Constant {
				return PyWrap.VoidType(from: const, type: .void)
			}
			fatalError(exp_type.rawValue)
		case .NamedExpr:
			fatalError(exp_type.rawValue)
		case .Slice:
			fatalError(exp_type.rawValue)
		case .Subscript:
			if let sub = any_ast as? AST.Subscript {
				return AST.Subscript.anyTypeProtocol(sub)
			}
		case .Starred:
			fatalError(exp_type.rawValue)
		case .Name:
			if let name = any_ast as? AST.Name { return name.anyTypeProtocol() }
		case .List:
			return PyWrap.TupleType(from: (any_ast as! AST.List))
			//fatalError(exp_type.rawValue)
		case .Tuple:
			assert(any_ast is AST.Tuple)
			return PyWrap.TupleType(from: (any_ast as! AST.Tuple))
			//fatalError(exp_type.rawValue)
		case .NoneType:
			fatalError(exp_type.rawValue)
		case .BinOp:
			if let binOp = any_ast as? AST.BinOp {
				let right = binOp.right
				switch right.type {
				case .Constant:
					
					guard let r_const = (right as? AST.Constant)!.value else {
						return PyWrap.OptionalType(expr: binOp.left)
					}
					
				default: fatalError("\(#line)")
				}
				
			}
		default:
			fatalError(exp_type.rawValue)
		}
		fatalError()
	}
	
//	static func fromAST() -> (any TypeProtocol).Type {
//		fatalError()
//	}
//	
	
}

extension AST.Subscript {
	
	static func anyArg(_ ast: Self, ast_arg: AST.Arg) -> AnyArg {
		guard let value = ast.value as? AST.Name else {
			fatalError()
		}
		
		let t = value.asPyType()
		switch value.asPySubscriptType() {
			
		case .list, .sequence, .array, .Array:
			//return PyWrap.CollectionType(from: ast, type: .list)
			return PyWrap.CollectionArg(ast: ast_arg, type: PyWrap.CollectionType(from: ast, type: .list))
		case .memoryview:
			fatalError(value.id)
		case .tuple:
			fatalError(value.id)
		case .callable:
			return PyWrap.CallableArg(ast: ast_arg, type: PyWrap.CallableType(from: ast, type: .callable))
		case .dict:
			//return PyWrap.DictionaryType(from: ast, type: .dict)
			return PyWrap.DictionaryArg(ast: ast_arg, type: PyWrap.DictionaryType(from: ast, type: .dict))
		case .optional:
			//return PyWrap.OptionalType(from: ast, type: .optional)
			return PyWrap.OptionalArg(ast: ast_arg, type: PyWrap.OptionalType(from: ast, type: .optional))
		case .other:
			return PyWrap.OtherArg(ast: ast_arg, type: .init(from: value, type: .other))
		}
	}
	
	static func anyTypeProtocol(_ ast: Self) -> any TypeProtocol {
		guard let value = ast.value as? AST.Name else {
			fatalError()
		}
		
		let t = value.asPyType()
		switch value.asPySubscriptType() {
			
		case .list, .sequence, .array, .Array:
			return PyWrap.CollectionType(from: ast, type: .list)
		case .memoryview:
			fatalError(value.id)
		case .tuple:
			fatalError(value.id)
		case .callable:
			fatalError(value.id)
		case .dict:
			return PyWrap.DictionaryType(from: ast, type: .dict)
		case .optional:
			return PyWrap.OptionalType(from: ast, type: .optional)
		case .other:
			return PyWrap.OtherType(from: ast.slice as! AST.Name, type: .other)
		}
		
		fatalError()
	}
}

extension AST.Tuple {
	func anyTypes() -> [any TypeProtocol] {
		elts.map(PyWrap.fromAST(any_ast:))
	}
}

extension AST.Name {
	
	func asPyType() -> PythonType { .init(rawValue: id) ?? .other }
	func asPySubscriptType() -> PythonSubscriptType { .init(rawValue: id) ?? .other }
	func anyTypeProtocol() -> any TypeProtocol {
		let t = asPyType()
		switch t {
		case .other:
			if !ignoreFatals { fatalError() }
		case .int, .long, .ulong, .uint, .int32, .uint32, .int8, .char,
				.uint8, .uchar, .ushort, .short, .int16, .uint16, .longlong, .ulonglong:
			return PyWrap.integerFromAST(self, type: t)
		case .float, .double, .float32:
			return PyWrap.floatFromAST(self, type: .init(from: t))
		case .list, .sequence, .array, .Array, .memoryview, .tuple, .byte_tuple:
			fatalError()
			
		case .str, .url, .error:
			return PyWrap.StringType.fromAST(self, type: t)
		case .bytes:
			fatalError()
		case .data:
			return PyWrap.DataType(from: self, type: t)
		case .json:
			fatalError()
		case .jsondata:
			fatalError()
		case .object:
			return PyWrap.PyObjectType(from: self, type: t)
		case .bool:
			return PyWrap.BoolType(from: self, type: t)
		case .dict:
			fatalError()
		case .void:
			fatalError()
		case .None:
			fatalError()
		case .callable:
			fatalError()
		case .optional:
			fatalError()
			
		}
		return PyWrap.OtherType(from: self, type: .other)
	}
	
}
extension AST.Name {
	func anyArg(_ ast_arg: AST.Arg) -> AnyArg {
		let t = asPyType()
		switch t {
		case .other:
			if !ignoreFatals { fatalError() }
		case .int, .long, .ulong, .uint, .int32, .uint32, .int8, .char,
				.uint8, .uchar, .ushort, .short, .int16, .uint16, .longlong, .ulonglong:
			//return PyWrap.integerFromAST(self, type: t)
			//return PyWrap.IntegerArg(ast: ast_arg, type: PyWrap.integerFromAST(self, type: t))
			return PyWrap.integerFromAST(self, type: t, ast_arg: ast_arg)
		case .float, .double, .float32:
			return PyWrap.floatFromAST(self, type: .init(from: t), ast_arg: ast_arg)
		case .list, .sequence, .array, .Array, .memoryview, .tuple, .byte_tuple:
			fatalError()
			
		case .str:
			//let o = PyWrap.StringType.fromAST(self, type: t)
			return PyWrap.StringArg.fromAST(self, type: t, ast_arg: ast_arg)
		case .bytes:
			fatalError()
		case .data:
			if !ignoreFatals { fatalError() }
		case .json:
			fatalError()
		case .jsondata:
			fatalError()
		case .object:
			let o = PyWrap.PyObjectType(from: self, type: t)
			return PyWrap.PyObjectArg(ast: ast_arg, type: o)
		case .bool:
			let o = PyWrap.BoolType(from: self, type: t)
			return PyWrap.BoolArg(ast: ast_arg, type: o)
		case .dict:
			fatalError()
		case .void:
			fatalError()
		case .None:
			fatalError()
		case .callable:
			return PyWrap.CallableArg(ast: ast_arg)
		case .optional:
			fatalError()
		case .error:
			fatalError()
		case .url:
			fatalError()
			
		}
		let o = PyWrap.OtherType(from: self, type: t)
		return PyWrap.OtherArg(ast: ast_arg, type: o)
	}
}
