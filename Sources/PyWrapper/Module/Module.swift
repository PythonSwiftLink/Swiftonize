import Foundation
import PyAst
import PyAstParser

public enum SwiftonizeModuleError: Error {
	case Assign(_ message: String)
	case AnnAssign(_ message: String)
	case Class(_ message: String)
	case Dict(_ message: String)
}

public struct PyWrap {
	
	public static func parse(file: URL) throws -> Module {
		try .init(filename: file.deletingPathExtension().lastPathComponent,ast: try AST.parseFile(url: file))
	}
	public static func parse(filename: String, string: String) throws -> Module {
		try .init(filename: filename, ast: try AST.parseString(string))
	}
	public static func parse(json filename: String, data: Data) throws -> Module {
		try .init(
			filename: filename,
			ast: JSONDecoder().decode(AST.Module.self, from: data)
		)
		//try .init(filename: filename, ast: try AST.parseString(string))
	}
	private init() {}
}

public extension PyWrap {
	
	
	
	class Module {
		
		public var filename: String
		public var classes: [Class]
		public var functions: [Function]
		public var imports: [String]
		public var type_vars: [TypeVar]
		init(filename: String,ast: AST.Module) throws {
			
			self.filename = filename
			
			let wrapped_classes: [String:String] = try ast.body.reduce(into: [:], { partialResult, stmt in
				let stmt_type = stmt.type
				switch stmt_type {
				case .Assign:
					if let assign = stmt as? AST.Assign {
						switch assign.value.type {
						case .Call:
							if let call = assign.value as? AST.Call {
								if let name = call._func as? AST.Name {
									switch name.id {
									case "NewType", "TypeVar":
										break
										//throw SwiftonizeModuleError.Assign("NewType - \(assign.value)")
									default:
										break
									}
								}
							}
						case .Dict:
							if let target = assign.targets.first as? AST.Name {
								if target.id == "wrapped_classes" {
									if let dict = assign.value as? AST.Dict {
										
										let keys = dict.keys.compactMap({$0 as? AST.Constant}).compactMap(\.value)
										let values = dict.values.compactMap({$0 as? AST.Name}).map(\.id)
										for (i, key) in keys.enumerated() {
											partialResult[key] = values[i]
										}
									}
								}
							}
						default: break
						}
						//throw SwiftonizeModuleError.Assign("\(assign.targets) - \(assign.value)")
					}
				default: break
				}
			})
			
			let _type_vars = try handleTypeVars(ast.body.compactMap({$0 as? AST.Assign}))
			type_vars = _type_vars
			let _classes = ast.body.compactMap({$0 as? AST.ClassDef})
			
			let classes2wrap = Array(wrapped_classes.values)
			let filtered_classes = _classes.filter({classes2wrap.contains($0.name)})
			
			let bases = try handleBaseTypes(_classes)
			
			classes = try filtered_classes.map({try PyWrap.fromAST($0, classes: wrapped_classes, base_types: bases, type_vars: _type_vars)})
//			classes = ast.body.compactMap { stmt in
//				let stmt_type = stmt.type
//				switch stmt_type {
//				case .ClassDef:
//					if let cls = stmt as? AST.ClassDef {
//						let decos = cls.decorator_list
//						for deco in decos {
//							switch deco.type {
//							case .Call:
//								if let call = deco as? AST.Call, let ast_name = call._func as? AST.Name {
//									let deco_name = ast_name.id
//									switch deco_name {
//									case "wrapper":
////										print(call.keywords.map{($0.arg!, $0.value.type.rawValue)})
////										print(call.args.compactMap({$0 as? AST.Constant}).compactMap(\.value))
//										return PyWrap.fromAST(cls)
//									default: break
//									}
//								}
//							
//							default:
//								continue
//								//options = .init()
//								//fatalError(deco.type.rawValue)
//							}
//						}
//
//						return nil
//					}
//				default: break
//				}
//				
//				return nil
//			}
			functions = ast.body.compactMap({ stmt in
				let stmt_type = stmt.type
				switch stmt_type {
				case .FunctionDef:
					if let function = stmt as? AST.FunctionDef {
						return Function(ast: function)
					}
				default: break
				}
				
				return nil
			})
			imports = ast.body.compactMap({ stmt  in
				let stmt_type = stmt.type
				switch stmt_type {
				case .Expr:
					let expr = stmt as! AST.Expr
					
					switch expr.value.type {
						
						case .Constant:
						if let const = expr.value as? AST.Constant, let value = const.value {
								if value.contains("import") {
									return String(value.split(separator: " ").last ?? "")
								}
							}
						default: break
						}
					
					
				default: break
				}
				return nil
			})
		}
		
	}
	
	
	static func fromAST(
		_ ast: AST.ClassDef,
		classes: [String: String] = [:],
		base_types: [BaseTypeProtocol] = [],
		type_vars: [TypeVar] = []
	) throws -> Class {
		
		try .init(ast: ast, classes: classes, base_types: base_types, type_vars: type_vars)
		
		
	}
}
