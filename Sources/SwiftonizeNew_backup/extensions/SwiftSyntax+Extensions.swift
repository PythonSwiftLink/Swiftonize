//
//  File.swift
//  
//
//  Created by MusicMaker on 25/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser
import WrapContainers

extension Array where Element == WrapArgProtocol {
    var parameterList: FunctionParameterListSyntax {
        return .init {
            for par in self {
                par.functionParameter
            }
        }
    }
	
	var cParameterList: ClosureParameterListSyntax {
		
		return .init {
			
		}
		return .init {
			for par in self {
				par.clossureParameter
			}
		}
	}
	
	var closureParameterClause: ClosureParameterClauseSyntax {
		.init(parameters: cParameterList)
	}
    
    var parameterClause: ParameterClauseSyntax {
        .init(parameterList: parameterList)
    }
    var argConditions: [ConditionElementSyntax] {
		switch count {
		case 0: return []
		case 1: return [first!.__arg__optionalGuardUnwrap]
		default: return map(\.optionalGuardUnwrap)
		}
		
    }
}


extension FunctionCallExprSyntax {
	init(_ string: String) throws {
		
		if let new = ExprSyntax(stringLiteral: string).as(FunctionCallExprSyntax.self) {
			self = new
		}
		throw CocoaError.error(.coderInvalidValue)
	}
}

extension ExprSyntax {
	init(nilOrExpression exp: ExprSyntaxProtocol?) {
		if let exp = exp {
			self.init(fromProtocol: exp)
		} else {
			self.init(fromProtocol: NilLiteralExprSyntax())
		}
		
	}
	
}
extension LabeledExprSyntax {
	init(label: String, nilOrExpression exp: ExprSyntax?) {
		if let exp = exp {
			self.init(label: label, expression: exp)
		} else {
			self.init(label: label, expression: NilLiteralExprSyntax() )
		}
		
	}
	init(nilOrExpression exp: ExprSyntax?) {
		if let exp = exp {
			self.init(expression: exp)
		} else {
			self.init(expression: NilLiteralExprSyntax() )
		}
		
	}
}


extension WrapFunction {
    
//    var __init__: FunctionCallExprSyntax {
//        //let cls_pointer: FunctionCallExprSyntax = .getClassPointer(wrap_class?.title ?? "Unknown")
////        let src_member = MemberAccessExprSyntax(
////            base: TryExprSyntax.unPackPySwiftObject(with: "s", as: wrap_class?.title ?? "Unknown"),
////            dot: .period,
////            name: .identifier(call_target ?? name)
////        )
//        let call = FunctionCallExprSyntax.
////        let call = FunctionCallExprSyntax.pyCall(
////            src_member,
////            args: _args_,
////            cls: wrap_class
////        )
//        return call.withRightParen(.rightParen.with(\.leadingTrivia, .newline))//.withRightParen(.rightParen.with(\.leadingTrivia, .newline)).with(\.leadingTrivia, .newline)
//    }
    
    
    var pyCall: FunctionCallExprSyntax {
        //let cls_pointer: FunctionCallExprSyntax = .getClassPointer(wrap_class?.title ?? "Unknown")
        if let wrap_class = wrap_class {
            let src_member = MemberAccessExprSyntax(
                base: TryExprSyntax.unPackPySwiftObject(with: "__self__", as: wrap_class.title),
				dot: .periodToken(),
                name: .identifier(call_target ?? name)
            )
            let call = FunctionCallExprSyntax.pyCall(
                src_member,
                args: _args_,
                cls: wrap_class
            )
            //return call.withRightParen(_args_.count > 0 ? .rightParen.with(\.leadingTrivia, .newline) : .rightParen)
			return call.with(\.rightParen, _args_.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
        }
//        let call = FunctionCallExprSyntax.pyCall(
//            IdentifierExpr(stringLiteral: call_target ?? name),
//            args: _args_
//        )
		let call = FunctionCallExprSyntax.pyCall(
			//IdentifierExpr(stringLiteral: call_target ?? name),
			"\(call_target ?? name)",
			args: _args_
		)
        //return call.withRightParen(_args_.count > 0 ? .rightParen.with(\.leadingTrivia, .newline) : .rightParen)
		return call.with(\.rightParen, _args_.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
    }
	
	func pyCallDefault(maxArgs: Int) -> FunctionCallExprSyntax {
		//let cls_pointer: FunctionCallExprSyntax = .getClassPointer(wrap_class?.title ?? "Unknown")
		let args = Array(_args_[0..<maxArgs])
		if let wrap_class = wrap_class {
			let src_member = MemberAccessExprSyntax(
				base: TryExprSyntax.unPackPySwiftObject(with: "__self__", as: wrap_class.title),
				dot: .periodToken(),
				name: .identifier(call_target ?? name)
			)
			let call = FunctionCallExprSyntax.pyCall(
				src_member,
				args: args,
				cls: wrap_class
			)
			//return call.withRightParen(_args_.count > 0 ? .rightParen.with(\.leadingTrivia, .newline) : .rightParen)
			return call.with(\.rightParen, _args_.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
		}
		let call = FunctionCallExprSyntax.pyCall(
			//IdentifierExpr(stringLiteral: call_target ?? name),
			"\(call_target ?? name)",
			args: args
		)
		//return call.withRightParen(_args_.count > 0 ? .rightParen.with(\.leadingTrivia, .newline) : .rightParen)
		return call.with(\.rightParen, _args_.count > 0 ? .rightParenToken(leadingTrivia: .newline) : .rightParenToken() )
	}
    
    
    var returnPattern: PatternBindingSyntax {
        let pattern = PatternSyntax(stringLiteral: "\(name)_result")
        return .init(pattern: pattern, initializer: nil)
    }
    
    var pyCallReturn: VariableDeclSyntax {
		let call: ExprSyntaxProtocol = self.throws ? TryExprSyntax(expression: pyCall) : pyCall
        let _var = VariableDeclSyntax(
            .let,
            name: .init(stringLiteral: "\(name)_result"),
//            initializer: .init(equal: .equal, value: call)
			initializer: .init(equal: .equalToken(), value: call)
        )
        
        //return _var.with(\.leadingTrivia, .newline)
		return _var.with(\.trailingTrivia, .newline)
    }
	
	func pyCallDefaultReturn(maxArgs: Int) -> VariableDeclSyntax {
		let _var: VariableDeclSyntax
		if self.throws {
			
			_var = .init(
				.let,
				name: .init(stringLiteral: "\(name)_result"),
				initializer: .init(equal: .equalToken(), value: pyCallDefault(maxArgs: maxArgs))
			)
		} else {
			_var = .init(
				.let,
				name: .init(stringLiteral: "\(name)_result"),
				//initializer: .init(equal: .equal, value: TryExprSyntax(expression: pyCallDefault(maxArgs: maxArgs)))
				initializer: .init(value: pyCallDefault(maxArgs: maxArgs))
			)
		}
		//return _var.with(\.leadingTrivia, .newline)
		return _var.with(\.trailingTrivia, .newline)
	}
    
    var assignFromClass: SequenceExprSyntax {
        .init {
            .init {
                //IdentifierExpr(stringLiteral: "_\(name)")
				ExprSyntax(stringLiteral: "_\(name)")
                AssignmentExprSyntax()
                pyGetAttr
                //MemberAccessExprSyntax(base: pyGetAttr, dot: .period, name: .identifier("xDECREF"))
            }
        }
    }
	
	func decref() -> MemberAccessExprSyntax {
		.init(base: ExprSyntax(stringLiteral: "_\(name)"), name: .identifier("decref()"))
	}
    
    var assignFromDict: SequenceExprSyntax {
        .init {
            .init {
				ExprSyntax(stringLiteral: "_\(name)")
				AssignmentExprSyntax()
                pyDictGet
            }
        }
    }
	
	    
    var pyGetAttr: FunctionCallExprSyntax {
//        .init(callee: IdentifierExpr(stringLiteral: "PyObject_GetAttr")) {
//            "callback".tupleExprElement
//            name._tupleExprElement
//        }
		.init(callee: ExprSyntax(stringLiteral: "PyObject_GetAttr")) {
			"callback".tupleExprElement
			name._tupleExprElement
		}
    }
    
    var pyDictGet: FunctionCallExprSyntax {
        .init(callee: ExprSyntax(stringLiteral: "PyDict_GetItem")) {
            "callback".tupleExprElement
            name._tupleExprElement
        }
    }
}

extension WrapArgProtocol {
	var __arg__optionalGuardUnwrap: ConditionElementSyntax {
		name.__arg__optionalGuardUnwrap
	}
    var optionalGuardUnwrap: ConditionElementSyntax {
//        .init(condition: .optionalBinding(.init(
//            letOrVarKeyword: .let,
//            pattern: IdentifierPatternSyntax(identifier: .identifier(name)),
//            initializer: name.initializerClause
//            //trailingTrivia: .space
//        )))
        name.optionalGuardUnwrap
    }
    
}

extension Array where Element == String {
    var parameterList: FunctionParameterListSyntax {
        return .init {
            for par in self {
                par.functionParameter
            }
        }
    }
    
    var closureInputList: ClosureParamListSyntax {
        var list = ClosureParamListSyntax {
            for par in self {
                par.closureParameter
            }
        }
        list.leadingTrivia = .space
        list.trailingTrivia = .space
        return list
    }
    
    var parameterClause: ParameterClauseSyntax {
        .init(parameterList: parameterList)
    }
    
    
    
    var closureSignature: ClosureSignatureSyntax {
        .init(input: .simpleInput(closureInputList) )
    }
    
}

func _generatePythonCall() -> CodeBlockItemListSyntax.Element? {
    
    
    
    
    return nil
}

func generatePythonCall() -> String {
    
    return ""
}


public extension String {
    
    var functionParameter: FunctionParameterSyntax {
        //.init(self, for: .functionParameters)
		.init(stringLiteral: self)
//		/fatalError()
			
    }
    
    var closureParameter: ClosureParamSyntax {
        .init(name: .identifier(self))
    }
    
    func tuplePExprElement(_ label: String) -> TupleExprElementSyntax {
        .init(label: self, expression: ExprSyntax(stringLiteral: "\"\(label)\""))
    }
    
    func _tuplePExprElement(_ label: String) -> TupleExprElementSyntax {
        .init(label: self, expression: label.expr)
    }
    
    var tupleExprElement: LabeledExprSyntax { .init(expression: ExprSyntax(stringLiteral: self)) }
    var _tupleExprElement: LabeledExprSyntax { .init(expression: ExprSyntax(stringLiteral: "\"\(self)\"")) }

    var _codeBlockItem: CodeBlockItemSyntax? {
        if self.isEmpty || hasPrefix("//") { return nil }
        return codeBlockItem
    }
    
    var codeBlockItem: CodeBlockItemSyntax {
        if let parsed = Parser.parse(source: self).children(viewMode: .all).first {
            if let block = parsed.as(CodeBlockItemListSyntax.self)?.first {
                return block
            }
        }
        return CodeBlockItemSyntax(item: .decl(.init(stringLiteral: self)))
    }
    
    var codeBlock: CodeBlockSyntax {
        if let parsed = Parser.parse(source: self).children(viewMode: .all).first {
            if let block = parsed.as(CodeBlockSyntax.self) {
                return block
            }
        }
        fatalError()
    }
    
    var expr: ExprSyntax { .init(stringLiteral: self) }
    
    var initializerClause: InitializerClauseSyntax {
        .init(equal: .equalToken(), value: expr)
    }
    
    
    
    var nargsCheck: ConditionElementSyntax {
        .init(condition: .expression(.init(SequenceExprSyntax(
            elements: .init {
                //IdentifierExprSyntax(stringLiteral: "__nargs__")
				ExprSyntax(stringLiteral: "__nargs__")
                BinaryOperatorExprSyntax(operatorToken: .leftAngleToken())
                //IntegerLiteralExprSyntax(stringLiteral: self)
				ExprSyntax(stringLiteral: self)
            }
        ))))
    }
	var __arg__optionalGuardUnwrap: ConditionElementSyntax {
		.init(condition: .optionalBinding(.init(
			bindingSpecifier: .identifier("let"),
			pattern: IdentifierPatternSyntax(identifier: .identifier(self)),
			initializer: "__arg__".initializerClause
		)))
	}
    var optionalGuardUnwrap: ConditionElementSyntax {
		.init(condition: .optionalBinding(.init(
			bindingSpecifier: .identifier("let"),
			pattern: IdentifierPatternSyntax(identifier: .identifier(self)),
			initializer: self.initializerClause
		)))
//        .init(condition: .optionalBinding(.init(
//            letOrVarKeyword: .let,
//            pattern: IdentifierPatternSyntax(identifier: .identifier(self)),
//            initializer: self.initializerClause
//            //trailingTrivia: .space
//        )))
    }
    
    var _import: ImportDeclSyntax {
        .init(path: .init(itemsBuilder: {
            //.init(name: self)
			.init(name: .identifier(self))
        }))
    }
	
	var `import`: ImportDeclSyntax {
		.init(path: .init(itemsBuilder: {
			.init(name: .identifier(self))
		}))
	}
    
    var inheritedType: InheritedTypeSyntax {
//        InheritedTypeSyntax(typeName: SimpleTypeIdentifier(stringLiteral: self))
		.init(type: SimpleTypeIdentifierSyntax(name: .identifier(self)))
    }
}

func countCompare(_ label: String,_ op: TokenKind, _ count: Int) -> ConditionElementSyntax {
    .init(condition: .expression(.init(SequenceExprSyntax(
        elements: .init {
//            IdentifierExprSyntax(stringLiteral: label)
			ExprSyntax(stringLiteral: label)
            BinaryOperatorExprSyntax(operatorToken: .init(op, presence: .present))
            //IntegerLiteralExprSyntax(stringLiteral: String(count))
			IntegerLiteralExprSyntax(integerLiteral: count)
        }
    ))))
}

func countCompare(_ label: String,_ op: String, _ count: Int) -> ConditionElementSyntax {
    .init(condition: .expression(.init(SequenceExprSyntax(
        elements: .init {
//            IdentifierExprSyntax(stringLiteral: label)
			ExprSyntax(stringLiteral: label)
            BinaryOperatorExprSyntax(operatorToken: .identifier(op))
            //IntegerLiteralExprSyntax(stringLiteral: String(count))
			IntegerLiteralExprSyntax(integerLiteral: count)
        }
    ))))
}

extension Array where Element == CodeBlockItemSyntax {
    var codeBlockList: CodeBlockItemListSyntax { .init(self) }
    var codeBlock: CodeBlockSyntax { .init(statements: codeBlockList) }
}

extension Array where Element == String {
    var codeBlockList: CodeBlockItemListSyntax { .init(compactMap(\._codeBlockItem)) }
    var codeBlock: CodeBlockSyntax { .init(statements: codeBlockList) }
}

public extension String {
    
    var typeSyntax: TypeSyntaxProtocol {
        if hasPrefix("[") {
//            return ArrayTypeSyntax(stringLiteral: self)
			return ArrayTypeSyntax(element: TypeSyntax(stringLiteral: self))
        }
        if hasSuffix("?") {
//            return OptionalType(stringLiteral: self)
			//return OptionalTypeSyntax(wrappedType: TypeSyntax(stringLiteral: self))
			return TypeSyntax(stringLiteral: self)
        }
        
//        return SimpleTypeIdentifier(stringLiteral: self )
		return TypeSyntax(stringLiteral: self)
    }
    
    var returnClause: ReturnClauseSyntax {
        ReturnClauseSyntax(arrow: .arrowToken(), returnType: self.typeSyntax)
    }
}


extension GuardStmtSyntax {
    var codeBlockItem: CodeBlockItemSyntax { .init(item: .init(self)) }
}

extension ExprSyntaxProtocol where Self == MemberAccessExprSyntax {
    static func getClassPointer(_ label: String) -> MemberAccessExprSyntax {
        
        let output = MemberAccessExprSyntax(
//            base: .init(stringLiteral: "__self__"),
			base: ExprSyntax(stringLiteral: "__self__"),
            dot: .periodToken(),
			name: "get\(raw: label)Pointer"
        )
        return output
    }
}

extension FunctionCallExprSyntax {
    
    static func getClassPointer(_ label: String) -> FunctionCallExprSyntax {
        return .init(
            
            calledExpression: .getClassPointer(label),
            leftParen: .leftParenToken(),
            argumentList: .init([]),
            rightParen: .rightParenToken()
        )
    }
    
    static func pyCall<S: ExprSyntaxProtocol>(_ src: S, args: [WrapArgProtocol], cls: WrapClass? = nil) -> FunctionCallExprSyntax {
        let many = args.count > 1
        let tuple = TupleExprElementListSyntax {
            for arg in args {
                
                (arg as! WrapArgSyntax).callTupleElement(many: many)//.with(\.leadingTrivia, .newline)
            }
        }//.with(\.leadingTrivia, .newline)
        
        return .init(
            calledExpression: src,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken()
            //trailingTrivia: .newline
        )
        
        //return .init(calledExpression: .getClassPointer(label), argumentList: tuple)
    }
    
    static func pyCall(_ label: String, args: [WrapArgProtocol]) -> FunctionCallExprSyntax {
        let many = args.count > 1
        let tuple = LabeledExprListSyntax {
            for arg in args {
				(arg as! WrapArgSyntax).callTupleElement(many: many)
//				if arg.type == .other {
//					.pyUnpack(with: arg as! otherArg, many: many)
//				} else {
//					.pyCast(arg: arg, many: many)
//				}
            }
        }
        
        return .init(
            calledExpression: label.expr,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken()
        )
        
        //return .init(calledExpression: .getClassPointer(label), argumentList: tuple)
    }
    var codeBlockItem: CodeBlockItemSyntax { .init(item: .init(self)) }
    
}

extension TupleExprElementSyntax {
    
    static func pyCast(arg: WrapArgProtocol, many: Bool) -> Self {
        switch arg {
        default:
			return .init(label: arg.label, expression: TryExprSyntax.pyCast(arg: arg, many: many))
//            return .init(
//                label: arg.label,
//                expression: .init(TryExprSyntax.pyCast(arg: arg, many: many))
//            )
        }
        
    }
    
    static func optionalPyCast(arg: WrapArgProtocol, many: Bool) -> Self {
        
        let id = IdentifierExprSyntax(identifier: .identifier("optionalPyCast"))
        var label: String {
            if many { return "__args__[\(arg.idx)]"}
            return arg.name
        }
        let tuple = TupleExprElementListSyntax {
            "from"._tuplePExprElement(label)
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken()
        )
        
        return .init(
            label: arg.label,
            expression: f_exp //.init(f_exp)
        )
        
        
    }
    
    static func pyUnpack(with arg: otherArg, many: Bool) -> Self {
//        return .init(
//            label: arg.label,
//            expression: .init(TryExprSyntax.unPackPyPointer(with: arg, many: many) as TryExpr)
//        )
//		/if arg.argType == "OscMessage" { fatalError("otherType: \(arg.argType)") }
		return .init(
			            label: arg.label,
			            expression: TryExprSyntax.unPackPyPointer(with: arg, many: many)  as TryExprSyntax
			        )
    }
    
    
}

extension TryExprSyntax {
    
    static func pyCast(arg: WrapArgProtocol, many: Bool) -> TryExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier("pyCast"))
        var label: String {
            if many { return "__args__[\(arg.idx)]"}
            return arg.name
        }
        let tuple = TupleExprElementListSyntax {
            "from"._tuplePExprElement(label)
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken()
        )
		return TryExprSyntax(tryKeyword: .keyword(.try), expression: f_exp)
		//return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    //static func unPackPySwiftObject(with src: String, as type: String) -> TryExprSyntax {
    static func unPackPySwiftObject(with src: String, as type: String) -> FunctionCallExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier("UnPackPySwiftObject"))
        
        let tuple = LabeledExprListSyntax {
            //TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
			LabeledExprSyntax(label: "with", expression: ExprSyntax(stringLiteral: src))
            LabeledExprSyntax(
                label: "as",
                expression: MemberAccessExprSyntax(
                    base: ExprSyntax(stringLiteral: type),
                    dot: .periodToken(),
                    name: .identifier("self")
                )
            )
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken()
        )
        return f_exp

        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    
    static func unPackPySwiftObject(with arg: otherArg, many: Bool) -> FunctionCallExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier("UnPackPySwiftObject"))
        var label: String {
            if many { return "__args__[\(arg.idx)]"}
            return arg.name
        }
        let tuple = TupleExprElementListSyntax {
            //TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: label)))
            "with"._tuplePExprElement(label)
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken(leadingTrivia: .newlines(2))
        )
        return f_exp
        
        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    
    static func unPackPyPointer(with arg: otherArg, many: Bool, type: String? = nil) -> TryExprSyntax {
        
//		.init(tryKeyword: .tryKeywordSyntax(trailingTrivia: .keyword(.space)), expression: unPackPyPointer(with: arg, many: many) as FunctionCallExprSyntax)
		.init(tryKeyword: .keyword(.try, trailingTrivia: .space), expression: unPackPyPointer(with: arg, many: many) as FunctionCallExprSyntax)
    }
    
    static func unPackPyPointer(with arg: otherArg, many: Bool, type: String? = nil) -> FunctionCallExprSyntax {
		//fatalError("unPackPyPointer\(arg.argType)")
        let id = IdentifierExprSyntax(identifier: .identifier("UnPackPyPointer"))

        var _arg: String {
            if many { return "__args__[\(arg.idx)]"}
            return arg.name
        }
        let tuple = LabeledExprListSyntax {
            //TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: label)))
//            "with"._tuplePExprElement("\(arg.other_type ?? "Unknown")PyType.pytype")
			"with"._tuplePExprElement("\(arg.other_type ?? "Unknown").PyType")
            "from"._tuplePExprElement(_arg)
            "as"._tuplePExprElement("\( type ?? (arg.other_type ?? "Unknown")).self")
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParenToken(),
            argumentList: tuple,
            rightParen: .rightParenToken()
        )
        return f_exp
        
        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    
    
    
    
}
public extension LabeledExprSyntax {
	
	init(label: String, _ expression: String) {
		self.init(label: label, expression: ExprSyntax(stringLiteral: expression))
	}
	init(_ expression: String) {
		self.init(expression: ExprSyntax(stringLiteral: expression))
	}
}

public extension FunctionCallExprSyntax {
    
    var initClause: InitializerClauseSyntax {
        .init(value: self)
    }
	
	init(
		name: String,
		trailingClosure: ClosureExprSyntax? = nil,
		additionalTrailingClosures: MultipleTrailingClosureElementListSyntax = [],
		@LabeledExprListBuilder argumentList: () -> LabeledExprListSyntax = { [] }
	) {
		self.init(callee: ExprSyntax(stringLiteral: name), trailingClosure: trailingClosure, additionalTrailingClosures: additionalTrailingClosures, argumentList: argumentList)
	}
}



extension PythonType {
    
    var typeSyntax: TypeSyntaxProtocol {
        //SimpleTypeIdentifier(stringLiteral: rawValue )
		TypeSyntax(stringLiteral: rawValue)
    }
    var typeExpr: TypeExprSyntax {
        .init(type: typeSyntax)
    }
}


extension ExprSyntax {
	init(closure: String) {
		//self.init(fromProtocol: ClosureExprSyntax(stringLiteral: closure))
		self.init(stringLiteral: closure)
	}
	static var `nil`: Self { .init(fromProtocol: NilLiteralExprSyntax()) }
}

extension ExprSyntaxProtocol {
	
	static var `nil`: Self { Self.init(NilLiteralExprSyntax())! }
}
