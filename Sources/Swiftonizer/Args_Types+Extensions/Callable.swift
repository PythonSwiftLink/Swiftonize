import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyWrapper

extension PyWrap.CallableArg: ArgSyntax {
    public func callTupleElement(many: Bool) -> SwiftSyntax.LabeledExprSyntax {
		if no_label { return .init(expression: "_\(name)".expr) }
		return .init(label: name, expression: "_\(name)".expr)
	}
	private func extractOptional(opt: PyWrap.OptionalType, index: Int) -> String? {
		return switch opt.wrapped.py_type {
		case .error: "let arg\(index) = arg\(index)?.localizedDescription"
		default: nil
		}
	}
	public func extractDecl(many: Bool) -> SwiftSyntax.VariableDeclSyntax? {
		let types = type.input.types
		let args = types.enumerated().map{"arg\($0.offset)"}.joined(separator: ", ")
		let extracts = types.enumerated().compactMap({ item in
			return switch item.element.py_type {
			case .optional: extractOptional(opt: item.element as! PyWrap.OptionalType, index: item.offset)
			default: nil
			}
		})
		return .init(
			.let,
			name: "_\(raw: name)",
			type: .init(type: self._typeSyntax),
			initializer: .init(
				value: ExprSyntax(stringLiteral:  """
					{ \(args) in
						\(extracts.joined(separator: "\n"))
						DispatchQueue.main.async {
							do {
								try PythonCallWithGil(call: \(name)\(types.count > 0 ? ", " : "")\(args))
							} catch let err as PythonError {
								// python errors
							} catch {
								// other errors
							}
						}
					}
					""")
			)
		)
	}
	
	
}



extension PyWrap.CallableType: ArgTypeSyntax {
	public var typeExpr: SwiftSyntax.TypeExprSyntax {
		.init(type: typeSyntax)
	}
	
	public var typeSyntax: SwiftSyntax.TypeSyntax {
		let _input = input as! ArgTypeSyntax
		
		return .init(
			FunctionTypeSyntax(
				parameters: input.types.tupleTypeList,
				returnClause: .init(type: TypeSyntax(stringLiteral: "Void"))
			)
		)
	}
	
	public var typeAnnotation: SwiftSyntax.TypeAnnotationSyntax {
		.init(type: typeSyntax)
	}
	
	
}
