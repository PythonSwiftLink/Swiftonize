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
    var parameterList: FunctionParameterList {
        return .init {
            for par in self {
                par.functionParameter
            }
        }
    }
    
    var parameterClause: ParameterClauseSyntax {
        .init(parameterList: parameterList)
    }
    var argConditions: [ConditionElementSyntax] {
        map(\.optionalGuardUnwrap)
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
//        let call = FunctionCallExpr.
////        let call = FunctionCallExprSyntax.pyCall(
////            src_member,
////            args: _args_,
////            cls: wrap_class
////        )
//        return call.withRightParen(.rightParen.withLeadingTrivia(.newline))//.withRightParen(.rightParen.withTrailingTrivia(.newline)).withTrailingTrivia(.newline)
//    }
    
    
    var pyCall: FunctionCallExprSyntax {
        //let cls_pointer: FunctionCallExprSyntax = .getClassPointer(wrap_class?.title ?? "Unknown")
        if let wrap_class = wrap_class {
            let src_member = MemberAccessExprSyntax(
                base: TryExprSyntax.unPackPySwiftObject(with: "_self_", as: wrap_class.title),
                dot: .period,
                name: .identifier(call_target ?? name)
            )
            let call = FunctionCallExprSyntax.pyCall(
                src_member,
                args: _args_,
                cls: wrap_class
            )
            return call.withRightParen(_args_.count > 0 ? .rightParen.withLeadingTrivia(.newline) : .rightParen)
        }
        let call = FunctionCallExprSyntax.pyCall(
            IdentifierExpr(stringLiteral: call_target ?? name),
            args: _args_
        )
        return call.withRightParen(_args_.count > 0 ? .rightParen.withLeadingTrivia(.newline) : .rightParen)
    }
	
	func pyCallDefault(maxArgs: Int) -> FunctionCallExprSyntax {
		//let cls_pointer: FunctionCallExprSyntax = .getClassPointer(wrap_class?.title ?? "Unknown")
		let args = Array(_args_[0..<maxArgs])
		if let wrap_class = wrap_class {
			let src_member = MemberAccessExprSyntax(
				base: TryExprSyntax.unPackPySwiftObject(with: "_self_", as: wrap_class.title),
				dot: .period,
				name: .identifier(call_target ?? name)
			)
			let call = FunctionCallExprSyntax.pyCall(
				src_member,
				args: args,
				cls: wrap_class
			)
			return call.withRightParen(_args_.count > 0 ? .rightParen.withLeadingTrivia(.newline) : .rightParen)
		}
		let call = FunctionCallExprSyntax.pyCall(
			IdentifierExpr(stringLiteral: call_target ?? name),
			args: args
		)
		return call.withRightParen(_args_.count > 0 ? .rightParen.withLeadingTrivia(.newline) : .rightParen)
	}
    
    
    var returnPattern: PatternBindingSyntax {
        let pattern = PatternSyntax(stringLiteral: "\(name)_result")
        return .init(pattern: pattern, initializer: nil)
    }
    
    var pyCallReturn: VariableDeclSyntax {
		let call: ExprSyntaxProtocol = self.throws ? TryExpr(expression: pyCall) : pyCall
        let _var = VariableDeclSyntax(
            .let,
            name: .init(stringLiteral: "\(name)_result"),
            initializer: .init(equal: .equal, value: call)
        )
        
        return _var.withTrailingTrivia(.newline)
    }
	
	func pyCallDefaultReturn(maxArgs: Int) -> VariableDeclSyntax {
		let _var: VariableDeclSyntax
		if self.throws {
			
			_var = .init(
				.let,
				name: .init(stringLiteral: "\(name)_result"),
				initializer: .init(equal: .equal, value: pyCallDefault(maxArgs: maxArgs))
			)
		} else {
			_var = .init(
				.let,
				name: .init(stringLiteral: "\(name)_result"),
				initializer: .init(equal: .equal, value: TryExpr(expression: pyCallDefault(maxArgs: maxArgs)))
			)
		}
		return _var.withTrailingTrivia(.newline)
	}
    
    var assignFromClass: SequenceExpr {
        .init {
            .init {
                IdentifierExpr(stringLiteral: "_\(name)")
                AssignmentExpr()
                pyGetAttr
                //MemberAccessExprSyntax(base: pyGetAttr, dot: .period, name: .identifier("xDECREF"))
            }
        }
    }
    
    var assignFromDict: SequenceExpr {
        .init {
            .init {
                IdentifierExpr(stringLiteral: "_\(name)")
                AssignmentExpr()
                pyDictGet
            }
        }
    }
    
    var pyGetAttr: FunctionCallExpr {
        .init(callee: IdentifierExpr(stringLiteral: "PyObject_GetAttr")) {
            "callback".tupleExprElement
            name._tupleExprElement
        }
    }
    
    var pyDictGet: FunctionCallExpr {
        .init(callee: IdentifierExpr(stringLiteral: "PyDict_GetItem")) {
            "callback".tupleExprElement
            name._tupleExprElement
        }
    }
}

extension WrapArgProtocol {
    
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
    var parameterList: FunctionParameterList {
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

func _generatePythonCall() -> CodeBlockItemList.Element? {
    
    
    
    
    return nil
}

func generatePythonCall() -> String {
    
    return ""
}


public extension String {
    
    var functionParameter: FunctionParameterSyntax {
        .init(self, for: .functionParameters)
    }
    
    var closureParameter: ClosureParamSyntax {
        .init(name: .identifier(self))
    }
    
    func tuplePExprElement(_ label: String) -> TupleExprElementSyntax {
        .init(label: self, expression: .init(stringLiteral: "\"\(label)\""))
    }
    
    func _tuplePExprElement(_ label: String) -> TupleExprElementSyntax {
        .init(label: self, expression: label.expr)
    }
    
    var tupleExprElement: TupleExprElement { .init(expression: .init(stringLiteral: self)) }
    var _tupleExprElement: TupleExprElement { .init(expression: .init(stringLiteral: "\"\(self)\"")) }

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
        .init(equal: .equal, value: expr)
    }
    
    
    
    var nargsCheck: ConditionElementSyntax {
        .init(condition: .expression(.init(SequenceExprSyntax(
            elements: .init {
                IdentifierExprSyntax(stringLiteral: "nargs")
                BinaryOperatorExpr(operatorToken: .leftAngle)
                IntegerLiteralExpr(stringLiteral: self)
            }
        ))))
    }
    
    var optionalGuardUnwrap: ConditionElementSyntax {
        .init(condition: .optionalBinding(.init(
            letOrVarKeyword: .let,
            pattern: IdentifierPatternSyntax(identifier: .identifier(self)),
            initializer: self.initializerClause
            //trailingTrivia: .space
        )))
    }
    
    var _import: ImportDeclSyntax {
        .init(path: .init(itemsBuilder: {
            .init(name: self)
        }))
    }
	
	var `import`: ImportDeclSyntax {
		.init(path: .init(itemsBuilder: {
			.init(name: self)
		}))
	}
    
    var inheritedType: InheritedTypeSyntax {
        InheritedTypeSyntax(typeName: SimpleTypeIdentifier(stringLiteral: self))
    }
}

func countCompare(_ label: String,_ op: TokenKind, _ count: Int) -> ConditionElementSyntax {
    .init(condition: .expression(.init(SequenceExprSyntax(
        elements: .init {
            IdentifierExprSyntax(stringLiteral: label)
            BinaryOperatorExpr(operatorToken: .init(op, presence: .present))
            IntegerLiteralExpr(stringLiteral: String(count))
        }
    ))))
}

func countCompare(_ label: String,_ op: String, _ count: Int) -> ConditionElementSyntax {
    .init(condition: .expression(.init(SequenceExprSyntax(
        elements: .init {
            IdentifierExprSyntax(stringLiteral: label)
            BinaryOperatorExpr(operatorToken: .identifier(op))
            IntegerLiteralExpr(stringLiteral: String(count))
        }
    ))))
}

extension Array where Element == CodeBlockItem {
    var codeBlockList: CodeBlockItemList { .init(self) }
    var codeBlock: CodeBlockSyntax { .init(statements: codeBlockList) }
}

extension Array where Element == String {
    var codeBlockList: CodeBlockItemList { .init(compactMap(\._codeBlockItem)) }
    var codeBlock: CodeBlockSyntax { .init(statements: codeBlockList) }
}

public extension String {
    
    var typeSyntax: TypeSyntaxProtocol {
        if hasPrefix("[") {
            return ArrayType(stringLiteral: self)
        }
        if hasSuffix("?") {
            return OptionalType(stringLiteral: self)
        }
        
        return SimpleTypeIdentifier(stringLiteral: self )
    }
    
    var returnClause: ReturnClauseSyntax {
        ReturnClause(arrow: .arrow, returnType: self.typeSyntax)
    }
}


extension GuardStmtSyntax {
    var codeBlockItem: CodeBlockItemSyntax { .init(item: .init(self)) }
}

extension ExprSyntaxProtocol where Self == MemberAccessExprSyntax {
    static func getClassPointer(_ label: String) -> MemberAccessExprSyntax {
        
        let output = MemberAccessExprSyntax(
            base: .init(stringLiteral: "_self_"),
            dot: .period,
            name: "get\(label)Pointer"
        )
        return output
    }
}

extension FunctionCallExprSyntax {
    
    static func getClassPointer(_ label: String) -> FunctionCallExprSyntax {
        return .init(
            
            calledExpression: .getClassPointer(label),
            leftParen: .leftParen,
            argumentList: .init([]),
            rightParen: .rightParen
        )
    }
    
    static func pyCall<S: ExprSyntaxProtocol>(_ src: S, args: [WrapArgProtocol], cls: WrapClass? = nil) -> FunctionCallExprSyntax {
        let many = args.count > 1
        let tuple = TupleExprElementListSyntax {
            for arg in args {
                
                (arg as! WrapArgSyntax).callTupleElement(many: many).withLeadingTrivia(.newline)
            }
        }//.withTrailingTrivia(.newline)
        
        return .init(
            calledExpression: src,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen
            //trailingTrivia: .newline
        )
        
        //return .init(calledExpression: .getClassPointer(label), argumentList: tuple)
    }
    
    static func pyCall(_ label: String, args: [WrapArgProtocol]) -> FunctionCallExprSyntax {
        let many = args.count > 1
        let tuple = TupleExprElementListSyntax {
            for arg in args {
                .pyCast(arg: arg, many: many)
            }
        }
        
        return .init(
            calledExpression: label.expr,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen
        )
        
        //return .init(calledExpression: .getClassPointer(label), argumentList: tuple)
    }
    var codeBlockItem: CodeBlockItemSyntax { .init(item: .init(self)) }
    
}

extension TupleExprElementSyntax {
    
    static func pyCast(arg: WrapArgProtocol, many: Bool) -> Self {
        switch arg {
        default:
            return .init(
                label: arg.label,
                expression: .init(TryExprSyntax.pyCast(arg: arg, many: many))
            )
        }
        
    }
    
    static func optionalPyCast(arg: WrapArgProtocol, many: Bool) -> Self {
        
        let id = IdentifierExprSyntax(identifier: .identifier("optionalPyCast"))
        var label: String {
            if many { return "_args_[\(arg.idx)]"}
            return arg.name
        }
        let tuple = TupleExprElementList {
            "from"._tuplePExprElement(label)
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen
        )
        
        return .init(
            label: arg.label,
            expression: .init(f_exp)
        )
        
        
    }
    
    static func pyUnpack(with arg: otherArg, many: Bool) -> Self {
        return .init(
            label: arg.label,
            expression: .init(TryExprSyntax.unPackPyPointer(with: arg, many: many) as TryExpr)
        )
    }
    
    
}

extension TryExprSyntax {
    
    static func pyCast(arg: WrapArgProtocol, many: Bool) -> TryExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier("pyCast"))
        var label: String {
            if many { return "_args_[\(arg.idx)]"}
            return arg.name
        }
        let tuple = TupleExprElementList {
            "from"._tuplePExprElement(label)
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen
        )
        return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    //static func unPackPySwiftObject(with src: String, as type: String) -> TryExprSyntax {
    static func unPackPySwiftObject(with src: String, as type: String) -> FunctionCallExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier("UnPackPySwiftObject"))
        
        let tuple = TupleExprElementList {
            TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: src)))
            TupleExprElementSyntax(
                label: "as",
                expression: .init(MemberAccessExprSyntax(
                    base: IdentifierExprSyntax(stringLiteral: type),
                    dot: .period,
                    name: .identifier("self")
                ))
            )
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen
        )
        return f_exp

        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    
    static func unPackPySwiftObject(with arg: otherArg, many: Bool) -> FunctionCallExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier("UnPackPySwiftObject"))
        var label: String {
            if many { return "_args_[\(arg.idx)]"}
            return arg.name
        }
        let tuple = TupleExprElementList {
            //TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: label)))
            "with"._tuplePExprElement(label)
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen.withLeadingTrivia(.newlines(2))
        )
        return f_exp
        
        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    
    static func unPackPyPointer(with arg: otherArg, many: Bool, type: String? = nil) -> TryExpr {
        
        .init(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: unPackPyPointer(with: arg, many: many) as FunctionCallExpr)
    }
    
    static func unPackPyPointer(with arg: otherArg, many: Bool, type: String? = nil) -> FunctionCallExprSyntax {
        let id = IdentifierExprSyntax(identifier: .identifier("UnPackPyPointer"))

        var _arg: String {
            if many { return "_args_[\(arg.idx)]"}
            return arg.name
        }
        let tuple = TupleExprElementList {
            //TupleExprElementSyntax(label: "with", expression: .init(IdentifierExprSyntax(stringLiteral: label)))
            "with"._tuplePExprElement("\(arg.other_type ?? "Unknown")PyType.pytype")
            "from"._tuplePExprElement(_arg)
            "as"._tuplePExprElement("\( type ?? (arg.other_type ?? "Unknown")).self")
        }
        let f_exp = FunctionCallExprSyntax(
            calledExpression: id,
            leftParen: .leftParen,
            argumentList: tuple,
            rightParen: .rightParen
        )
        return f_exp
        
        //return TryExprSyntax(tryKeyword: .tryKeyword(trailingTrivia: .space), expression: f_exp)
    }
    
    
    
    
}


public extension FunctionCallExprSyntax {
    
    var initClause: InitializerClause {
        .init(value: self)
    }
}



extension PythonType {
    
    var typeSyntax: TypeSyntaxProtocol {
        SimpleTypeIdentifier(stringLiteral: rawValue )
    }
    var typeExpr: TypeExpr {
        .init(type: typeSyntax)
    }
}
