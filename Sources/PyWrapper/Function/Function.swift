import Foundation
import PyAst



extension AST.Name: CustomDebugStringConvertible, CustomStringConvertible {
	public var debugDescription: String {
		id
	}
	
	public var description: String { id }
}

extension AST.Arg: CustomStringConvertible {
	public var description: String { (annotation as? CustomStringConvertible)?.description ?? "\(annotation)" }
}
public extension PyWrap {
	
	class Function {
		
		
		public weak var `class`: Class?
		
		public var args: [AnyArg]
		
		public var vararg: AnyArg?
		
		public var kwargs: AnyArg?
		
		public var ast: AST.FunctionDef
		
		public var returns: (any TypeProtocol)?
		
		public var `static`: Bool
		
		public var call_target: String?
		
		init(ast: AST.FunctionDef, cls: Class? = nil) {
			  print("###########################################################")
			self.ast = ast
			self.class = cls
			  print(ast.name)
			
			//self.args = ast.args.args.enumerated().compactMap(PyWrap.fromAST)
//			let no_labels = ast.decorator_list.compactMap({ deco in
//				switch deco.type {
//				case .Call:
//					let call = deco as! AST.Call
//					if let _func = call._func as? AST.Name {
//						
//						switch _func.id {
//						case "no_labels": return Self.handleNoLabels(call)
//						default: fatalError()
//						}
//					}
//				case .Name: return ["*"]
//				default: fatalError(deco.type.rawValue)
//				}
//				return nil
//			})
			//let no_labels_all = no_labels.contains(["*"])
			let filtered = ast.args.args.filter({$0.arg != "self"})
			self.args = filtered.enumerated().compactMap({ i, arg in
				if let annotation = arg.annotation {
					var out: AnyArg = PyWrap.fromAST(annotation, ast_arg: arg)
					out.index = i
					//if no_labels_all { out.options.append(.no_label)}
					return out
				}
				return PyObjectArg(ast: arg)
			})
			dump(args)
			
			
			// so easy to check if *args is used, if not present vararg is nil
//			if let vararg = ast.args.vararg {
//				if let annotation = vararg.annotation {
//					self.vararg = PyWrap.fromAST(annotation, ast_arg: vararg)
//				} else {
//					self.vararg = PyObjectArg(ast: vararg)
//				}
//				
//				print("vararg: *\(self.vararg!.type)")
//			}
			// same with **kwargs, if not present kwarg is nil
//			if let kw = ast.args.kwarg {
//				if let annotation = kw.annotation {
//					kwargs = PyWrap.fromAST(annotation, ast_arg: kw)
//				} else {
//					self.kwargs = PyObjectArg(ast: kw)
//				}
//				
//				print("**kw: \(kwargs!.type)")
//			}
//			
			if let returns = ast.returns {
				self.returns = PyWrap.fromAST(any_ast: returns)
				print("return type: \(self.returns!)")
			}
//			print(self.args.map(\.type))
			self.static = ast.decorator_list.contains(name: "staticmethod")
			  print("###########################################################\n")
			
			for deco in ast.decorator_list {
				switch deco.type {
				case .Call:
					guard let call = deco as? AST.Call,
						  let fname = call._func as? AST.Name
					else { continue }
					switch FuncDecorator(rawValue: fname.id) {
					case .no_labels:
						if call.keywords.isEmpty, call.args.isEmpty {
							args.forEach { arg in
								arg.options.append(.no_label)
							}
						} else {
							for kw in call.keywords {
								guard
									let key = kw.arg,
									let const = kw.value as? AST.Constant
								else { fatalError() }
								if let arg = args.first(where: {$0.name == key}) {
									if const.boolValue {
										arg.options.append(.no_label)
									}
								}
							}
						}
					case .arg_alias:
						for kw in call.keywords {
							guard
								let key = kw.arg,
								let const = kw.value as? AST.Constant
							else { fatalError() }
							if let arg = args.first(where: {$0.name == key}) { 
								//if let value =  const.value {
								//arg.ast.arg = const.value
								arg.name
								//}
							}
							
						}
					case .no_protocol: break
					case .func_options:
						handleFuncOptions(options: call)
					case .none:
						break
					}
				default: continue
				}
				
			}
		}
		
	}
}

extension PyWrap.Function {
	
	public enum FuncDecorator: String {
		case no_labels
		case arg_alias
		case no_protocol
		case func_options
		
	}
	
	public enum FuncOptions: String {
		case no_labels
		case arg_alias
		case no_protocol
		case call_target
		
	}
	
	func handleFuncOptions(options: AST.Call) {
		for kw in options.keywords {
			
			guard
				let key = kw.arg
				//let const = kw.value as? AST.Constant
			else {
				//fatalError( "\(kw), \(kw.lineno), \(kw.col_offset)" )
				fatalError("wrong arg")
			}
			switch FuncOptions(rawValue: key) {
			case .call_target:
				if let const = kw.value as? AST.Constant {
					call_target = const.value
				}
			case .no_labels:
				guard let dict = kw.value as? AST.Dict else { fatalError() }
				for (i,label_key) in dict.keys.enumerated() {
					if let label_key = label_key as? AST.Constant, let label = label_key.value {
						if let arg = args.first(where: {$0.name == label}), let value  = dict.values[i] as? AST.Constant {
							if value.boolValue {
								//fatalError()
								arg.options.append(.no_label)
							}
						} else {
							fatalError()
						}
					}
				}
			case .arg_alias:
				guard let value = kw.value as? AST.Dict else { fatalError() }
				for (i,label_key) in value.keys.enumerated() {
					if let label_key = label_key as? AST.Constant, let label = label_key.value {
						if let arg = args.first(where: {$0.name == label}) {
							//arg.name =
						}
					}
				}
			case .no_protocol: break
			case .none: continue
			}
		}
	
	}
}

extension PyWrap.Function {
	public var arguments: AST.Arguments { ast.args }
	public var name: String { ast.name }
	public var defaults_name: [String] { arguments.defaults.compactMap({ d in
		if let _name = d as? AST.Name {
			return _name.id
		}
		return nil
	}) }
	
	public var `throws`: Bool { ast.decorator_list.contains { expr in
		if let _name = expr as? AST.Name {
			return _name.id == "throws"
		}
		return false
	}}
	
	static func handleNoLabels(_ call: AST.Call) -> [String] {
		if call.keywords.isEmpty { return ["*"] }
		if call.args.isEmpty { return ["*"] }
		fatalError()
		return ["*"]
		
	}
}
