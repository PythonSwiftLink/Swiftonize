

import Foundation
import PyAst

extension ArgProtocol {
	
	public var name: String { ast.arg }
	
	public var optional_name: String? { nil }
	
	public var no_label: Bool { options.contains(where: {
		switch $0 {
		case .no_label: return true
		default: return false
		}
	}) }
}
