
import Foundation
import PyAst

let ignoreFatals = true

public protocol TypeProtocol {
	
	associatedtype AstType: ExprProtocol
	
	var ast: AstType? { get }
	
	var py_type: PythonType { get }
	
	var string: String { get }
	
	init(from ast: AstType, type: PythonType)
}


extension ArgProtocol {
	var lineno: Int { ast.lineno }
	var col_offset: Int { ast.col_offset }
	var end_lineno: Int { ast.end_lineno ?? -1 }
	var end_col_offset: Int { ast.end_col_offset ?? -1 }
}
