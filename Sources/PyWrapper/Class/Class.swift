import Foundation
import PyAst

fileprivate var functionsExclude: [String] = [
	//"__init__",
	"__getattr__",
	"__setattr__"

]
fileprivate func getFunctionOverloads(functions: [any Stmt]) -> [PyWrap.Class.ClassOverLoads] {
	functions.compactMap { stmt in
		switch stmt.type {
		case .FunctionDef:
			if let function = stmt as? AST.FunctionDef {
				return .init(rawValue: function.name)
			}
		default: return nil
		}
		return nil
	}
}
fileprivate func convertAST2Function(_ asts: [any Stmt], cls: PyWrap.Class) -> [PyWrap.Function]? {
	if asts.isEmpty { return nil }
	var out = [PyWrap.Function]()
	for ast in asts {
		switch ast.type {
		case .FunctionDef:
			if let function = ast as? AST.FunctionDef {
				if functionsExclude.contains(function.name) { continue }
				out.append(.init(ast: function, cls: cls))
			}
		default: continue
		}
	}
	return out.isEmpty ? nil : out
}


fileprivate func convertAST2Property(_ asts: [any Stmt], cls: PyWrap.Class) -> [any ClassProperty]? {
	if asts.isEmpty { return nil }
	var out = [any ClassProperty]()
	for ast in asts {
		switch ast.type {
		case .AnnAssign:
			
			out.append(PyWrap.Class.propertyFromAST(ast: ast as! AST.AnnAssign))
		case .Assign:
			out.append(PyWrap.Class.Property(stmt: ast as! AST.Assign))
		case .FunctionDef: continue
		case .ClassDef: continue
		case .Expr: continue
		default: fatalError(ast.type.rawValue)
		}
	}
	return out.isEmpty ? nil : out
}

extension AST.Constant {
	var boolValue: Bool {
		if let value = value {
			return Bool(value.lowercased()) ?? false
		}
		
		return false
	}
}

public extension PyWrap {
	
	class Class {
		
		public var functions: [Function]?
		
		public var callbacks: Callbacks?
		public var ast: AST.ClassDef?
		
		public var properties: [any ClassProperty]?
		
		public var options: PyWrap.ClassOptions
		
		public var overloads: [ClassOverLoads] = []
		
		public var new_class: Bool = false
		
		public var __init__: Function?
		
		public var base_types: [any BaseTypeProtocol]
		
		init(
			ast: AST.ClassDef,
			classes: [String: String] = [:],
			base_types: [BaseTypeProtocol] = [],
			type_vars: [TypeVar] = []
		) throws {
			self.ast = ast
			functions = []
			self.base_types = base_types
			options = .init()
			
			if ast.bases.contains(name: "Generic") {
				
				if let first = ast.bases.first as? AST.Subscript, let generic_name = (first.slice as? AST.Name)?.id {
					//fatalError("\(generic_name) == \(type_vars.map(\.name)) -> \(type_vars.first(where: {$0.name == generic_name}))")
					if let type_var = type_vars.first(where: {$0.name == generic_name}) {
						//fatalError("Generic typevar matched")
						options.generic_mode = true
						options.generic_typevar = type_var
					}
				}
			}
			//print(ast.name)
			let decos = ast.decorator_list
			//print(ast.decorator_list)
			
			if decos.isEmpty {
//
			} else {
				for deco in decos {
					switch deco.type {
					case .Call:
						if let call = deco as? AST.Call, let ast_name = call._func as? AST.Name {
							let deco_name = ast_name.id
							if deco_name == "wrapper" {
								let kws = call.keywords.compactMap { kw in
									if let arg = kw.arg, let value = (kw.value as? AST.Constant)?.value {
										return (arg,value)
									}
									return nil
								}
								for kw in kws {
									switch InitArguments(rawValue: kw.0) {
									case .py_init:
										options.py_init = kw.1 == "True" ? true : false
									case .target:
										options.target = kw.1
									case .unretained:
										options.unretained = kw.1 == "True" ? true : false
									case .new:
										new_class = true
									case .none: break
									}
									
								}
								for (i, arg) in call.args.enumerated() {
									switch i {
									case 0:
										options.py_init = (arg as! AST.Constant).boolValue ?? true
									default: break
									}
								}
							}
						}
					default: 
						continue
					}
				}
			}
			var _functions: [PyWrap.Function]? = convertAST2Function(ast.body, cls: self)
			if let init_index = _functions?.firstIndex(where: { $0.name == "__init__" }) {
				__init__ = _functions?.remove(at: init_index)
				options.py_init = true
			}
			
//			if let funcs = _functions {
//				if funcs.contains(where: {$0.name == "__init__"}) {
//					options.py_init = false
//					_functions?.removeAll(where: {$0.name == "__init__"})
//				}
//			}
			
			functions = _functions
			properties = convertAST2Property(ast.body, cls: self)
			overloads.append(contentsOf: getFunctionOverloads(functions: ast.body))
			
			
			var bases: [ExprProtocol] { ast.bases }
			
			let cls_name = ast.name
			//throw SwiftonizeModuleError.Class( "\(classes)")
			if let result = classes.first(where: { (k,v) in
				v == cls_name && k != cls_name
			}) {
				options.target = result.key
				//throw SwiftonizeModuleError.Class( "\(options.target)")
			}
			if let first = ast.body.compactMap({$0 as? AST.ClassDef}).first(where: {$0.name == "Callbacks"}) {
				callbacks = .init(ast: first, cls: self)
			}
			
//			functions = ast.body.compactMap({ stmt in
//				switch stmt.type {
//				case .FunctionDef:
//					if let function = stmt as? AST.FunctionDef {
//						if function.name == "__init__" { return nil }
//						return .init(ast: function)
//					}
//				default: break
//				}
//				return nil
//			})
		}
		
	}
}


public extension PyWrap.Class {
	
	enum InitArguments: String {
		case target
		case py_init
		case unretained
		case new
		
	}
	
	var name: String { options.target ?? ast?.name ?? "NULL"}
	
	var init_func: PyWrap.Function? {
		for stmt in ast?.body ?? [] {
			switch stmt.type {
			case .FunctionDef:
				let f = stmt as! AST.FunctionDef
				if f.name == "__init__" {
					return convertAST2Function([f], cls: self)?.first
				}
			default: break
			}
		}
		return nil
	}
}

public extension PyWrap {
	
	struct ClassOptions {
		public var py_init = false
		public var debug_mode = false
		public var target: String? = nil
		public var unretained = false
		public var generic_mode = false
		public var generic_typevar: PyWrap.TypeVar?
		
		init(py_init: Bool = false, debug_mode: Bool = false, target: String? = nil) {
			self.py_init = py_init
			self.debug_mode = debug_mode
			self.target = target
		}
		
		
	}
}


public extension PyWrap.Class {
	enum ClassOverLoads: String {
		case __getattr__
		case __setattr__
	}
}
