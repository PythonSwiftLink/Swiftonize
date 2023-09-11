//
//  File.swift
//  
//
//  Created by MusicMaker on 24/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PyAstParser
import PythonSwiftCore
//import SwiftSyntaxParser
import SwiftParser

extension TypeAnnotation {
    static let pythonObject = TypeAnnotation(type: SimpleTypeIdentifier(stringLiteral: "PythonObject"))
    static let pyPointer = TypeAnnotation(type: SimpleTypeIdentifier(stringLiteral: "PyPointer"))
}

//extension TypeSyntaxProtocol {
//    static let pyPointer = TypeSyntax(stringLiteral: "PyPointer")
//}

func CreateDeclMember(_ token: Token, name: String, type: TypeAnnotation, _private: Bool = false, initializer: InitializerClause? = nil) -> MemberDeclListItem {
    return .init(decl: createClassDecl(
        token,
        name: name,
        type: type,
        _private: _private,
        initializer: initializer
    ))
}

func createClassDecl(_ token: Token, name: String, type: TypeAnnotation, _private: Bool = false, initializer: InitializerClause? = nil) -> VariableDeclSyntax {
    return .init(
        modifiers: _private ? .init(arrayLiteral: .init(name: .private)) : nil,
        token,
        name: .init(identifier: .identifier(name)),
        type: type,
        initializer: initializer
    )
}

class PyCallbacksGenerator {
    
    let cls: WrapClass
    
    public init(cls: WrapClass) {
        self.cls = cls
        
    }
    
    var assignCallback: SequenceExpr {
        .init {
            .init {
                IdentifierExpr(stringLiteral: "_pycall")
                AssignmentExpr()
                FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .period, name: "init")) {
                    "ptr"._tuplePExprElement("callback")
                }
            }
        }
    }
    var assignCallbackKeep: SequenceExpr {
        .init {
            .init {
                IdentifierExpr(stringLiteral: "_pycall")
                AssignmentExpr()
                FunctionCallExprSyntax(callee: MemberAccessExprSyntax(dot: .period, name: "init")) {
                    "ptr"._tuplePExprElement("callback")
                    "keep_alive"._tuplePExprElement("true")
                }
            }
        }
    }
    
    var initializeCallbacks: CodeBlockItemList { .init {
        let conditions = ConditionElementList {
            FunctionCallExprSyntax(stringLiteral: "PythonDict_Check(callback)")
        }
        IfStmt(conditions: conditions) {
            assignCallback
            for cp in cls.callbacks {
                cp.assignFromDict
            }
        } elseBody: {
            assignCallbackKeep
            for cp in cls.callbacks {
                cp.assignFromClass
            }
        }.withLeadingTrivia(.newlines(2))

    }}
    
    
    var _init: InitializerDecl {
        let sig = FunctionSignature(input: .init(
            parameterList: .init(itemsBuilder: {
                .init(
                    firstName: .identifier("callback"),
                    colon: .colon,
                    type: SimpleTypeIdentifier(stringLiteral: "PyPointer"))
            })
        ))
        
        return .init(signature: sig) {
            initializeCallbacks
        }
    }
    
    var _deinit: DeinitializerDecl {
        .init("deinit") {
            
        }
    }
    
    var code: ClassDeclSyntax {
        let new_callback = ( cls.bases.count == 0)
        let inher: TypeInheritanceClauseSyntax? = new_callback ? nil : .init {
            for base in cls.bases { base.inheritedType }
            for cp in cls.callback_protocols { cp.inheritedType }
        }
        let cls_title = cls.new_class ?  cls.title : "\(cls.title)PyCallback"
        let cls_dect = ClassDeclSyntax(
            attributes: nil,
            identifier: cls_title,
            inheritanceClause: inher) {
                .init {
                    
                    CreateDeclMember(.var, name: "_pycall", type: .pythonObject).withLeadingTrivia(.newlines(2))
                    for f in cls.callbacks {
                        CreateDeclMember(.var, name: "_\(f.name)", type: .pyPointer, _private: true)
                    }
                    
                    _init.withLeadingTrivia(.newlines(2))
                    
                    _deinit.withTrailingTrivia(.newline)
                    for f in cls.callbacks {
                        PythonCall(function: f).functionDecl.withTrailingTrivia(.newline)
                    }
                }.withTrailingTrivia(.newline)
            }
        
        return cls_dect
    }
    
}

//
//public class PyCallbacks {
//
//
//    public init() {
//
//    }
//
//
//    public func test2(string: String) {
//        let test = Parser.parse(source: string).children(viewMode: .all).first!.children(viewMode: .all).first!
//        let visit = TestVisitor(viewMode: .all)
//        for item in test.children(viewMode: .all) {
//            print(item.syntaxNodeType, item.description)
//            if let fcall = item.as(FunctionCallExprSyntax.self) {
//                visit.visit(fcall)
//            }
//        }
//
//    }
//
//
//    public func test1(string: String) {
//        let test = Parser.parse(source: string).children(viewMode: .all).first!.children(viewMode: .all).first!
//        for item in test.children(viewMode: .all) {
//            print(item.syntaxNodeType, item.description)
//            let visit = TestVisitor(viewMode: .all)
//            if let guards = item.as(GuardStmtSyntax.self) {
//                visit.visit(guards)
//            }
//        }
//    }
//
//    public func test0(string: String) throws {
//        //let source = SourceFileSyntax {
//        let args: [WrapArgProtocol] = [
//            otherArg(_name: "peripheral", _type: .other, _other_type: "CBPeripheral", _idx: 0, _options: []),
//            intArg(_name: "a", _type: .int32, _other_type: nil, _idx: 1, _options: []),
//            floatArg(_name: "b", _type: .double, _other_type: nil, _idx: 2, _options: [])
//
//        ]
//        let rtn = WrapArg(name: "", type: .object, other_type: nil, idx: 0, arg_options: [.return_])
//        let _func_ = PySwiftFunction(function: .init(name: "testFunc", args: [], rtn: rtn, options: []))
//        _func_.function._args_ = args
//        _func_.function._return_ = objectArg(_name: "", _type: .object, _other_type: nil, _idx: 0, _options: [])
//
//        //print(_func_.functionDecl.formatted().description)
//        print(_func_.functionCallExpr.formatted().description)
//
//        _func_.function._return_ = objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [])
//        print(_func_.functionCallExpr.formatted().description)
//
//
//
//
//        return
//           let cls = ClassDeclSyntax(identifier: "abc" ) {
//                DeclSyntax("let a = \"\" ")
//
//                DeclSyntax(
//                    """
//                    func with\(raw: "Joe")(_ \(raw: "moe"): \(raw: "String")) -> Person {
//                        var result = self
//                        result.\(raw: "joe") = \(raw: "moe")
//                        return result
//                    }
//                    """
//                )
//            }
//        //}
//
//
//
//        let f = DeclSyntax(
//                    """
//                    func with\(raw: "Joe")(_ \(raw: "moe"): \(raw: "String")) -> Person {
//                        var result = self
//                        result.\(raw: "joe") = \(raw: "moe")
//                        return result
//                    }
//                    """
//        )
//        for i in f.children(viewMode: .all) {
//            //print(i.syntaxNodeType, i)
//            for x in i.children(viewMode: .all) {
//                //print("\t -> \(x.syntaxNodeType) : \(x)")
//            }
//        }
//        let fsyntax = FunctionSignatureSyntax(
//            input: .init(parameterList: .init(itemsBuilder: {
//                FunctionParameter("joe: moe", for: .functionParameters)
//                FunctionParameter("joe: moe", for: .functionParameters)
//            }))
//        )
//        let func_syntax = FunctionSignatureSyntax(
//            input: .init(parameterList: .init(itemsBuilder: {
//                FunctionParameter("joe: String", for: .functionParameters)
//                FunctionParameter("moe: Int", for: .functionParameters)
//            })),
//            output: ReturnClauseSyntax(arrow: TokenSyntax.arrow, returnType: SimpleTypeIdentifierSyntax(stringLiteral: "String")   )
//        )
//        let bodylist = CodeBlockItemList {
//            CodeBlockItemSyntax(item: .decl(DeclSyntax("let a = 1 + 1")))
//        }
//
//
//
//        let block = CodeBlockSyntax(statements: bodylist)
//
//        let the_func = FunctionDeclSyntax(identifier: .identifier("JoeMoe"), signature: func_syntax, body: block)
//        //return source
//        print("\n######################################\n")
//        print(the_func.formatted())
//        print("\n######################################\n")
//
//
//        let clossure = """
//        { s, _args_, nargs in
//            do {
//                guard nargs > 1, let _args_ = _args_, let s = s else { throw PythonError.call }
//                let a = _args_[0]!
//                let b = _args_[1]!
//
//                s.getWrapTestClassPointer().hmmmmmm(a: a, b: b)
//                return PythonNone
//            }
//            catch let err as PythonError {
//                switch err {
//                case .call: err.triggerError("wanted 2 got 2")
//                default: err.triggerError("hmmmmmm")
//                }
//
//            }
//            catch let other_error {
//                other_error.pyExceptionError()
//            }
//            return nil
//        }
//        """
//
//        let csyntax = Parser.parse(source: clossure).children(viewMode: .all).first!.children(viewMode: .all).first!
//
//        for item in csyntax.children(viewMode: .all) {
//            print(item.syntaxNodeType)
//            for child in item.children(viewMode: .all) {
//                print(child.syntaxNodeType, child.description)
//                if let closure = child.as(ClosureSignatureSyntax.self) {
//                    print(closure.input!.syntaxNodeType, closure.input!, closure.inTok, closure.unexpectedBetweenThrowsTokAndOutput, closure.unexpectedBetweenCaptureAndInput)
//                    for input in closure.input!.children(viewMode: .all) {
//                        print("\t\(input.syntaxNodeType) - \(input.description)")
//                    }
//                }
//                if let codeblock = child.as(CodeBlockItemListSyntax.self) {
//                    test(CodeBlockItemList: codeblock)
//                }
//            }
//        }
//
//        let c_export = ClosureExprSyntax(signature: ["x","y","z"].closureSignature, statements: ["let v = x + y"].codeBlockList)
//        print("\n######################################\n")
//        print(c_export.formatted().description)
//        print("\n######################################\n")
//    }
//}
//
//
//
//private func test(CodeBlockItemList list: CodeBlockItemListSyntax, indent: Int = 1) {
//    let tabs = createTabs(indent)
//    print("\(tabs)test(CodeBlockItemList):")
//    for item in list.children(viewMode: .all) {
//        print("\n\(tabs)###########\(item.syntaxNodeType)###########")
//        for line in item.children(viewMode: .all) {
//            print(tabs + "\(line.syntaxNodeType)")
//            if let dostmt = line.as(DoStmtSyntax.self) {
//                test(DoStmtSyntax: dostmt, indent: indent + 1)
//            }
//        }
////        print(tab + "\(item.description)")
//        print("\t######################################\n")
//    }
//}
//
//private func test(DoStmtSyntax dostmt: DoStmtSyntax, indent: Int) {
//
//    let tabs = createTabs(indent)
//    print("\(tabs)test(DoStmtSyntax):")
//    for item in dostmt.children(viewMode: .all) {
//        print("\n\(tabs)###########\(item.syntaxNodeType)###########")
//        printSyntax(item)
//        for line in item.children(viewMode: .all) {
//            //print(tabs + "\(line.syntaxNodeType)")
//            printSyntax(line)
//        }
//        print("\(tabs)######################################\n")
//    }
//}
//
//
//
//func createTabs(_ count: Int) -> String {
//    (0..<count).map({_ in tab}).joined()
//}
//
//class TestVisitor: SyntaxVisitor {
//
//    override func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
//        print("visit: ")
//        for n in node.conditions {
//            print(n.syntaxNodeType, n)
//            visit(n)
//        }
//        print(node.body)
//        return .visitChildren
//    }
//
//    override func visit(_ node: CodeBlock) -> SyntaxVisitorContinueKind {
//        print("CodeBlock visit: ")
//        for n in node.statements {
//            print(n.syntaxNodeType, n)
//            //visit(n)
//        }
//        return .visitChildren
//    }
//
//    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
//        print("\tCodeBlock visit: ", node.children(viewMode: .all).map(\.syntaxNodeType))
//        return .visitChildren
//    }
//
//    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
//        print("\tFunctionCallExprSyntax visit: ", node.children(viewMode: .all).map(\.syntaxNodeType))
//        print(node.calledExpression.syntaxNodeType,node.calledExpression)
//        for n in node.argumentList {
//            print(tab, n.syntaxNodeType, n.label ?? .nil, n.expression.syntaxNodeType)
//        }
//        if let closure = node.trailingClosure {
//            print(node.calledExpression, closure.syntaxNodeType, closure)
//            if let sig = closure.signature {
//                print(sig.input!.syntaxNodeType)
//                if let parlist = sig.input!.as(ClosureParamList.self) {
//                    print(parlist.formatted())
//                }
//            }
//            for line in closure.statements {
//                print(line.syntaxNodeType, line)
//            }
//        }
//
//        for n in node.children(viewMode: .all) {
////            /print(tab, n.syntaxNodeType, n)
//        }
//        return .visitChildren
//    }
//}
//
//func printSyntax(_ syntax: SyntaxProtocol) {
//    let visitor = TestVisitor(viewMode: .all)
//    if let codeblock = syntax.as(CodeBlockSyntax.self) {
//        visitor.visit(codeblock)
//    }
//}
