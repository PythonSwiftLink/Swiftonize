
import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum PySwiftUnPackError: Error {
	case arg(name: String, kind: String)
	case args(_ message: String)
}

struct PySwiftUnPacker: DeclarationMacro {
	static func expansion(of node: some SwiftSyntax.FreestandingMacroExpansionSyntax, in context: some SwiftSyntaxMacros.MacroExpansionContext) throws -> [SwiftSyntax.DeclSyntax] {
	
		var args: [String: String] = [
			"cls": "__self__",
			"type": "AnyClass"
		]

		for arg in node.argumentList {
			switch arg.label?.text {
			case "cls":
				args["cls"] = arg.expression.description
				//throw PySwiftUnPackError.arg(name: "cls", kind: "\(arg.expression.kind)")
			case "type":
				if let arg = arg.expression.as(MemberAccessExprSyntax.self) {
					args["type"] = arg.base!.description
				}
				//args["type"] = arg.expression.description
				//throw PySwiftUnPackError.arg(name: "type", kind: "\(arg.expression.kind)")
			default: continue
			}
		}
		
		//throw PySwiftUnPackError.args(node.argumentList.map({"\($0.kind)"}).joined(separator: ", "))
//		for arg in node.argumentList {
//			arg
//		}
		
		
		
		return ["let cls: \(raw: args["type"]!) = Unmanaged.fromOpaque(\(raw: args["cls"]!).swift_ptr).takeUnretainedValue()"]
	}
}






@main
struct ScriptEnginePlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		PySwiftUnPacker.self
	]
}
