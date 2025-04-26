//
//  File.swift
//  
//
//  Created by CodeBuilder on 09/09/2024.
//

import Foundation
import PyWrapper
import PyAstParser
import PyAst


public func test(file: URL, dst: URL) throws {
	let module = try PyWrap.parse(file: file)
	var type_vars = [AnyArg]()
	let ast_classes: [any Stmt] = module.classes.map(generateAstClass)
	let class_names: [String] = module.classes.map(\.name)
	for cls in module.classes {
		for function in cls.functions ?? [] {
			for arg in function.args {
				if arg.type.py_type == .other {
					
					if !class_names.contains(arg.name), !type_vars.contains(where: {$0.type.string == arg.type.string }) {
						type_vars.append(arg)
					}
				}
			}
		}
		for function in cls.callbacks?.functions ?? [] {
			for arg in function.args {
				if arg.type.py_type == .other {
					
					if !class_names.contains(arg.name), !type_vars.contains(where: {$0.type.string == arg.type.string }) {
						type_vars.append(arg)
					}
				}
			}
		}
	}
//	let imports: [Stmt] = [
//		//AST.ImportFrom(module: "", names: <#T##[AST.Alias]#>, level: <#T##Int#>, lineno: <#T##Int#>, col_offset: <#T##Int#>)
//	]
	var _type_vars = [String]()
	for type_var in type_vars {
		_type_vars.append(type_var.type.string)
	}
	let ast_module = AstExportModule(body: ast_classes, type_vars: _type_vars)
	
	//var dst = file.deletingLastPathComponent()
	//try dst.append(component: file.lastPathComponent.replacingOccurrences(of: ".py", with: ".json"))
	try JSONEncoder().encode(ast_module).write(to: dst)
	
}

final public class AstExportModule: Codable {
	
	
	
	public var description: String { name }
	
	public var type: AST.AstType = .Module
	
	public var type_vars: [String]
	
	public var body: [Stmt]
	
	public var name: String {
		""
	}
	
	enum CodingKeys: CodingKey {
		case body
		case __class__
		case type_vars
	}
	
	public init(body: [Stmt], type_vars: [String] = []) {
		self.body = body
		self.type_vars = type_vars
	}
	
	public init(from decoder: Decoder) throws {
		let c = try decoder.container(keyedBy: CodingKeys.self)
		body = try c.decode([Stmt].self, forKey: .body)
		type_vars = []
	}
	public func encode(to encoder: Encoder) throws {
		var c = encoder.container(keyedBy: CodingKeys.self)
		//try c.encode(type, forKey: .__class__)
		try c.encode(body, forKey: .body)
		try c.encode(type_vars, forKey: .type_vars)
	}
}


private func generateAstClass(_ cls: PyWrap.Class) -> AST.ClassDef {
	var ast_cls = cls.ast!
	ast_cls.decorator_list.removeAll()
	//ast_cls.bases = ast_cls.bases.compactMap(transformClassBase)
	ast_cls.body.transform(transformClassBody)
	if let callback_index = ast_cls.body.firstIndex(where: {($0 as? AST.ClassDef)?.name == "Callback"}) {
		let swap = ast_cls.body.remove(at: callback_index)
		ast_cls.body.insert(swap, at: 0)
	
		let body = (cls.callbacks?.functions ?? []).map { f in
			return AST.AnnAssign(
				target: AST.Name(id: f.name),
				annotation: AST.Name(id: "Callable"),
				simple: 0,
				lineno: 0,
				col_offset: 0
			)
		}
		let typed_dict = AST.ClassDef(
			name: "CallbackDict",
			bases: [AST.Name(id: "TypedDict")],
			keywords: [],
			body: body,
			decorator_list: [],
			lineno: 0,
			col_offset: 0
		)
		ast_cls.body.insert(typed_dict, at: 1)
	}
	return ast_cls
}

private func transformClassBase(_ base: ExprProtocol) -> (any ExprProtocol)? {
	nil
}

extension AST.Arg {
	mutating func transform() {
		switch self.annotation?.type {
		case .BoolOp:
			fatalError()
		case .BinOp:
			fatalError()
		case .UnaryOp:
			fatalError()
		case .Lambda:
			fatalError()
		case .IfExp:
			fatalError()
		case .Dict:
			fatalError()
		case .Set:
			fatalError()
		case .ListComp:
			fatalError()
		case .SetComp:
			fatalError()
		case .DictComp:
			fatalError()
		case .GeneratorExp:
			fatalError()
		case .Await:
			fatalError()
		case .Yield:
			fatalError()
		case .YieldFrom:
			fatalError()
		case .Compare:
			fatalError()
		case .Call:
			fatalError()
		case .FormattedValue:
			fatalError()
		case .JoinedStr:
			fatalError()
		case .Constant:
			fatalError()
		case .NamedExpr:
			fatalError()
		case .Attribute:
			fatalError()
		case .Slice:
			fatalError()
		case .Subscript:
			fatalError()
		case .Starred:
			fatalError()
		case .Name:
			guard var name = annotation as? AST.Name else { fatalError() }
			print("assign:")
			print(name)
			switch name.id {
			case "data":
				name.id = "bytes"
			default: break
			}
			annotation = name
			
		case .List:
			fatalError()
		case .Tuple:
			fatalError()
		case .NoneType:
			fatalError()
		case nil:
			annotation = AST.Constant.Object
		}
	}
}

extension Array where Element == AST.Arg {
	mutating func transform() {
		self = map {
			var arg = $0
			arg.transform()
			return arg
		}
	}
}
extension AST.Arguments {
	mutating func transform() {
		args.transform()
	}
}

extension AST.FunctionDef {
	mutating func transform() {
		decorator_list.removeAll()
		args.transform()
	}
}
extension AST.Name {
	static var Object: Self {
		.init(id: "object")
	}
}
extension AST.Constant {
	static var Object: Self {
		"object"
	}
	static var Bytes: Self {
		"bytes"
	}

	static var property_deco: AST.Constant {
		.init(stringLiteral: "property")
	}
}

extension Stmt {
	static func ==(l: Self, r: String) -> Bool {
		switch l {
		case let f as AST.FunctionDef:
			return f.name == r
		default: fatalError()
		}
	}
}


private func transformClassBody(_ base: Stmt) -> (any Stmt)? {
	switch base.type {
	case .FunctionDef:
		guard var function = base as? AST.FunctionDef else { return nil }
		function.transform()
		return function
		
	case .AsyncFunctionDef:
		fatalError()
	case .ClassDef:
		guard var cls = base as? AST.ClassDef else { fatalError() }
		guard cls.name == "Callbacks" else { return cls }
		cls.name = "Callback"
		
		cls.body.transform(transformClassBody)
		cls.bases = [
			AST.Name(id: "Protocol")
		]
		
		return cls
	case .Return:
		fatalError()
	case .Delete:
		fatalError()
	case .Assign:
		debugPrint(base)
		guard let assign = base as? AST.Assign else { return nil }
		guard let name = (assign.targets.first as? AST.Name)?.id else {
			print(assign.targets.map(\.type))
			fatalError()
		}
		switch assign.value {
		case let call as AST.Call:
			if call == "WrappedProperty" {
				if call.keywords.contains(where: { kw in
					kw.arg == "readonly" && (kw.value as? AST.Constant)?.boolValue ?? false
				}) {
					
					//var arg = AST.Arg(label: "value")
					//arg.annotation = AST.Name.Object
					let args = AST.Arguments(
						args: [
							.init(label: "self")
						],
						kwonlyargs: [],
						kw_defaults: [],
						defaults: []
					)
					return AST.FunctionDef(
						name: name,
						args: args,
						body: [AST.Pass()],
						decorator_list: [AST.Constant.property_deco],
						returns: call.args.first,
						lineno: 0,
						col_offset: 0
					)
				} else {
					return AST.AnnAssign(
						target: AST.Constant(stringLiteral: name),
						annotation: AST.Constant.Object,
						simple: 0,
						lineno: 0,
						col_offset: 0
					)
				}
				//return nil
			}
		default:
			print(base.type)
			print(base)
			fatalError()
		}
		
		
	case .AugAssign:
		fatalError()
	case .AnnAssign:
		fatalError()
	case .For:
		fatalError()
	case .AsyncFor:
		fatalError()
	case .While:
		fatalError()
	case .If:
		fatalError()
	case .With:
		fatalError()
	case .AsyncWith:
		fatalError()
	case .Raise:
		fatalError()
	case .Try:
		fatalError()
	case .TryStar:
		fatalError()
	case .Assert:
		fatalError()
	case .Import:
		fatalError()
	case .ImportFrom:
		fatalError()
	case .Global:
		fatalError()
	case .Nonlocal:
		fatalError()
	case .Expr:
		fatalError()
	case .Pass:
		fatalError()
	case .Break:
		fatalError()
	case .Continue:
		fatalError()
	}
	
	return nil
}

extension Array where Element == any Stmt {
	mutating func transform(_ handler: (Stmt)-> Stmt?) {
		self = compactMap(handler)
	}
}
