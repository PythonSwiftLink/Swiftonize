import Foundation
import PyAst

fileprivate func convertAST2Function(_ asts: [any Stmt], cls: PyWrap.Class) -> [PyWrap.Function]? {
	if asts.isEmpty { return nil }
	var out = [PyWrap.Function]()
	for ast in asts {
		switch ast.type {
		case .FunctionDef:
			if let function = ast as? AST.FunctionDef {
				//if functionsExclude.contains(function.name) { continue }
				out.append(.init(ast: function, cls: cls))
			}
		default: continue
		}
	}
	return out.isEmpty ? nil : out
}

extension PyWrap.Class {
	public class Callbacks {
		
		public var ast: AST.ClassDef
		public weak var cls: PyWrap.Class?
		public var functions: [PyWrap.Function]
		public var properties: [any ClassProperty]?
		public var bases: [ExprProtocol] { cls?.ast?.bases ?? [] }
		public var count: Int { functions.count }
		
		public var __init__: PyWrap.Function?
		
		public init(ast: AST.ClassDef, cls: PyWrap.Class) {
			self.ast = ast
			self.cls = cls
			var _functions: [PyWrap.Function]? = convertAST2Function(ast.body, cls: cls)
			if let init_index = _functions?.firstIndex(where: { $0.name == "__init__" }) {
				__init__ = _functions?.remove(at: init_index)
				//options.py_init = true
			}
			functions = _functions ?? []
			properties = convertAST2Property(ast.body)
			
			
		}
		
		public var name: String { cls?.name ?? "NoName"}
		
		public var new_class: Bool { cls?.new_class ?? false}
	}
}
