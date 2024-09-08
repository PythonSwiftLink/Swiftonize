
import Foundation
import PyAst
import WrapContainers

import PySwiftCore

public extension WrapClassProperty {
	var ast: [PyAstObject] {
		var body: [PyAstObject] = []
		
		
			body.append(
				PyAst_Function(
					name: name,
					args: [.init(arg: "self")],
					decorator_list: ["property"],
					returns: arg_type.ast
				)
			)
			if property_type == .GetSet {
				body.append(
					PyAst_Function(name: name, args: [.init(arg: "self"), arg_type.ast], decorator_list: ["\(name).setter"])
				)
			}
		
		
		return body
	}
}

public extension WrapArgProtocol {
	
	var ast: PyAst_Arg {
		.init(arg: name, annotation: type.rawValue)
	}
	
}

public extension WrapFunction {
	
	var ast: PyAst_Function {
		.init(name: name, body: [" ..."], args: _args_.map(\.ast), decorator_list: [], returns: _return_.ast)
	}
}

public extension WrapClass {
	
	var ast: PyAst_Class {
		var body: [PyAstObject] = []
		
		for p in properties {
			body.append(contentsOf: p.ast)
		}
		
		for f in functions {
			body.append(f.ast)
		}
		
		return PyAst_Class(name: title, body: body, decorator_list: [])
		
	}
	
}

public extension WrapModule {
	var ast: PyAst_Module {
		var body: [PyAstObject] = []
		for f in functions {
			body.append(f.ast)
		}
		for c in classes {
			body.append(c.ast)
		}
		
		return .init(body: body)
	}
}
