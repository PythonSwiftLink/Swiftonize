//
//  File.swift
//
//
//  Created by MusicMaker on 01/05/2023.
//

import Foundation
import SwiftSyntax
//import SwiftSyntaxParser
import PyWrapper


fileprivate extension String {
	func asLabeledExpr(_ expression: ExprSyntaxProtocol) -> LabeledExprSyntax {
		.init(label: self, expression: expression)//.newLineTab
	}
	func asExpr() -> ExprSyntax { .init(stringLiteral: self)}
}

struct PyGetSetProperty {
	
	var property: any ClassProperty
	var cls: PyWrap.Class
	
	init(_property: (any ClassProperty), _cls: PyWrap.Class) {
		self.property = _property
		self.cls = _cls
	}
	
	var getter: ClosureExprSyntax {
		let closure = ExprSyntax(stringLiteral: "{s,clossure in }").as(ClosureExprSyntax.self)!
		var line = "UnPackPySwiftObject(with: s, as: \(cls.name).self).\(property.target_name ?? property.name)"
		if property.name == "delegate" && property.prop_type is PyWrap.OtherType {
			line += " as? \(property.prop_type as! PyWrap.OtherType)"
		}
		if property.name == "py_callback" {
			line += "?._pycall"
		}
//		if property.prop_type is PyWrap.OptionalType || property.name == "py_callback" { line = "optionalPyPointer( \(line) )"}
        if property.prop_type is PyWrap.OptionalType || property.name == "py_callback" { line = "\(line).pyPointer"}
		else {
			if !(property.prop_type is PyWrap.PyObjectType) {
				line += ".pyPointer"
			}
		}
		return closure.with(\.statements, .init(itemsBuilder: {
			ExprSyntax(stringLiteral: line)
		}))
		//        return closure.withStatements(.init {
		//            ExprSyntax(stringLiteral: line)
		//        })
	}
	
	
	var setter_assign: String {
		let arg_type = property.prop_type
		let name = property.name
		switch arg_type {
		case _ where name == "delegate":
			return  "try UnPackOptionalPyPointer(with: \(arg_type)PyType.pytype, from: v, as: \(arg_type).self)"
		case _ where name == "py_callback":
			return "\(cls.name)PyCallback(callback: v)"
		case let opt as PyWrap.OptionalType:
			if opt.wrapped.py_type == .other {
				return  "try UnPackOptionalPyPointer(with: \(opt.wrapped.string).PyType, from: v, as: \(opt.wrapped.string).self)"
			}
			return "optionalPyCast(from: v)"
		case let other as PyWrap.OtherType:
			return  "try UnPackPyPointer(with: \(other.wrapped).PyType, from: v, as: \(other.wrapped).self)"
		default:
			return "try pyCast(from: v)"
		}
	}
	
	private var doCatch: DoStmtSyntax {
		func catchItem(_ label: String) -> CatchItemListSyntax {
			.init(
				arrayLiteral: .init(pattern: IdentifierPatternSyntax(identifier: .identifier(label)))
			)
		}
		var catchClauseList: CatchClauseListSyntax {
			
			.init {
				CatchClauseSyntax(catchItem("let err as PythonError")) {
					
	 #"""
	 switch err {
	 case .call: err.triggerError("type Error")
	 default: err.triggerError("hmmmmmm")
	 }
	 """#.codeBlockItem
					
				}
				CatchClauseSyntax(catchItem("let other_error")) {
					"//other_error.pyExceptionError()".codeBlockItem
				}
				
			}
		}
		//		if let tname = property.target_name {
		//			fatalError()
		//		}
		let line = "UnPackPySwiftObject(with: s, as: \(cls.name).self).\(property.target_name ?? property.name) = \(setter_assign)"
		let extra =  CodeBlockItemListSyntax {
			if property.name == "py_callback" {
				ExprSyntax(stringLiteral: "guard let v = v else { throw PythonError.attribute }")
				//GuardStmtSyntax(stringLiteral: "guard let v = v else { throw PythonError.attribute }")
			}
			
		}
		var do_stmt = DoStmtSyntax {
			CodeBlockItemListSyntax {
				extra
				ExprSyntax(stringLiteral: line)
				//                ReturnStmtSyntax(stringLiteral: "return 0")
				"return 0"
			}//.with(\.leadingTrivia, .newline)
		}
		do_stmt.catchClauses = catchClauseList
		return do_stmt
	}
	
	var setter: ClosureExprSyntax {
		//let closure = ClosureExprSyntax(stringLiteral: "{ s, v, clossure in }")
		let closure: ClosureExprSyntax = ExprSyntax(stringLiteral: "{ s, v, clossure in }").as(ClosureExprSyntax.self)!
//		if let tname = property.target_name {
//			
//		}
//		let line = "UnPackPySwiftObject(with: s, as: \(cls.name).self).\(property.target_name ?? property.name) = \(setter_assign)"
//		
		//        if property.arg_type is optionalArg { line += "optionalPyCast(from: v)"}
		//        else { line += "try pyCast(from: v)" }
		
		return closure.with(\.statements, .init {
			doCatch
			//ReturnStmtSyntax(stringLiteral: "return 1")
			"return 1"
		})
		//        return closure.withStatements(.init {
		//            doCatch
		//            //ReturnStmtSyntax(stringLiteral: "return 1")
		//			"return 1"
		//        })
	}
	func pyGetSetDef() -> FunctionCallExprSyntax {
		.init(
			calledExpression: ExprSyntax(stringLiteral: "PyGetSetDef"),
			leftParen: .leftParenToken(trailingTrivia: .newline.appending(.tab)),
			arguments: .init {
				"name".asLabeledExpr(FunctionCallExprSyntax.cString(property.name))
					.with(\.trailingComma, .commaToken(trailingTrivia: .newline))
				"get".asLabeledExpr(unsafeBitCast(pymethod: getter, from: "PySwift_getter", to: "getter.self"))
					.with(\.trailingComma, .commaToken(trailingTrivia: .newline))
				"set".asLabeledExpr(
					property.property_type == .GetSet
					? unsafeBitCast(pymethod: setter, from: "PySwift_setter", to: "setter.self")
					: NilLiteralExprSyntax()
				).with(\.trailingComma, .commaToken(trailingTrivia: .newline))
				"doc".asLabeledExpr(NilLiteralExprSyntax())
				"closure".asLabeledExpr(NilLiteralExprSyntax())
				
			},
			rightParen: .rightParenToken(leadingTrivia: .newline)
		)
	}
	
	func pyGetSetDef() -> ArrayElementSyntax {
		.init(expression: pyGetSetDef())
		.with(\.trailingComma, .commaToken(trailingTrivia: .newline))
	}
	
	
	var _callExpr: FunctionCallExprSyntax {
		//        let exp = IdentifierExprSyntax(stringLiteral: "PyGetSetDefWrap")
		let exp = ExprSyntax(stringLiteral: "PyGetSetDefWrap")
		return .init(
			calledExpression: exp,
			leftParen: .leftParenToken(trailingTrivia: .newline),//.withTrailingTrivia(.newline ),
			arguments: .init {
				LabeledExprSyntax(
					label: "pySwift",
					expression: StringLiteralExprSyntax(content: property.name )
				).with(\.leadingTrivia, .newline)
				LabeledExprSyntax(
					label: "getter",
					expression: getter//.init( getter )
				).with(\.leadingTrivia, .newline)
				if property.property_type == .GetSet {
					LabeledExprSyntax(
						label: "setter",
						expression: setter//.init( setter )
					).with(\.leadingTrivia, .newline)
				}
			},
			rightParen: .rightParenToken(leadingTrivia: .newline)//.with(\.leadingTrivia, .newline)
		)
		
	}
	
	
}
