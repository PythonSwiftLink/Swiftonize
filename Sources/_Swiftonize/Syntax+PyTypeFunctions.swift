//
//  File.swift
//  
//
//  Created by MusicMaker on 01/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser
//import SwiftSyntaxParser
import WrapContainers

class PyTypeFunctions {
    
    enum FunctionType: String {
        case tp_init
        case tp_new
        case tp_dealloc
        case tp_getattr
        case tp_setattr
        //case tp_as_number
        //case tp_as_sequence
        case tp_call
        case tp_str
        case tp_repr
        case tp_hash
        //case tp_as_buffer
        
    }
    
    var options: [FunctionType]
    weak var _cls: WrapClass?
    var cls: WrapClass { _cls! }
    
    init(options: [FunctionType]) {
        self.options = options
    }
    
    
    
    var tp_init: ClosureExprSyntax {
        if !cls.ignore_init {
            return create_tp_init
        }
        return ExprSyntax(stringLiteral: """
        { s, _args_, kw -> Int32 in
            PyErr_SetString(PyExc_NotImplementedError,"\(cls.title) can only be inited from swift")
            return -1
        }
        """).as(ClosureExprSyntax.self)!
    }
    
    var tp_new: ClosureExprSyntax {
		ExprSyntax(stringLiteral: """
		{ type, args, kw -> PyPointer? in
			PySwiftObject_New(type)
		}
		""").as(ClosureExprSyntax.self)!
    }
    
    var tp_dealloc: ClosureExprSyntax {
		
        let closure = ExprSyntax(stringLiteral: "{ s in }").as(ClosureExprSyntax.self)!
		return closure.with(\.statements, .init {
			let if_ptr = ExprSyntax(stringLiteral: "if let ptr = PySwiftObject_Cast(s).pointee.swift_ptr { }").as(IfExprSyntax.self)!
			//let if_ptr = IfStmt(stringLiteral: "if let ptr = PySwiftObject_Cast(s).pointee.swift_ptr { }")
			if_ptr.with(\.body, .init {
				ExprSyntax(stringLiteral: "Unmanaged<\(cls.title)>.fromOpaque(ptr).release()")
			})
//            if_ptr.withBody(.init {
//                FunctionCallExprSyntax(stringLiteral: "Unmanaged<\(cls.title)>.fromOpaque(ptr).release()")
//            })
        })
    }
    
    var tp_getattr: ClosureExprSyntax? {
        guard options.contains(.tp_getattr) else { return nil }
        return ExprSyntax(stringLiteral: """
        { type, args, kw -> PyPointer? in
            // TODO
        }
        """).as(ClosureExprSyntax.self)
    }
    
    var tp_hash: ClosureExprSyntax? {
        guard options.contains(.tp_hash) else { return nil }
        return ExprSyntax(stringLiteral: """
        { _self_ -> Int in
            UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__hash__
        }
        """).as(ClosureExprSyntax.self)
    }
    var tp_str: ClosureExprSyntax? {
        guard options.contains(.tp_str) else { return nil }
        return ExprSyntax(stringLiteral: """
        
        { _self_ -> PyPointer? in
            UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__str__().pyPointer
        }
        """).as(ClosureExprSyntax.self)
    }
    
    var tp_repr: ClosureExprSyntax? {
        guard options.contains(.tp_repr) else { return nil }
        return ExprSyntax(stringLiteral: """
        { _self_ -> PyPointer? in
            UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__repr__().pyPointer
        }
  """).as(ClosureExprSyntax.self)
    }
}


extension PyTypeFunctions {
    
    private var create_tp_init: ClosureExprSyntax {
        
		let closure = ExprSyntax(stringLiteral: "{ __self__, _args_, kw -> Int32 in }").as(ClosureExprSyntax.self)!
		return closure.with(\.statements, .init {
			if cls.debug_mode { ExprSyntax(stringLiteral: #"print("tp_init - <\#(cls.title)>")"#) }
			createTP_Init(cls: cls, args: cls.init_function?._args_ ?? []).code
			"return 1"
		})
//        return closure.withStatements(.init {
//            if cls.debug_mode { ExprSyntax(stringLiteral: #"print("tp_init - <\#(cls.title)>")"#) }
//            createTP_Init(cls: cls, args: cls.init_function?._args_ ?? []).code
//            ReturnStmtSyntax(stringLiteral: "return 1")
//        })
        
        
    }
    
}


extension PyTypeFunctions {
    
    func export(_ t: FunctionType) -> ExprSyntax {
        
        switch t {
            
        case .tp_init:
            return .init(fromProtocol: tp_init)
        case .tp_new:
            return .init(fromProtocol: tp_new)
        case .tp_dealloc:
            return cls.unretained ? .init(fromProtocol: NilLiteralExprSyntax() ) : .init(stringLiteral:
                tp_dealloc.formatted().description
                    .replacingOccurrences(of: "d < ", with: "d<")
                    .replacingOccurrences(of: " > .", with: ">.")
            )
        case .tp_getattr:
            if let tp_getattr = tp_getattr {
                return .init(fromProtocol: tp_getattr )
            }
            return .init(fromProtocol: NilLiteralExprSyntax() )
        case .tp_setattr:
            return .init(fromProtocol: NilLiteralExprSyntax() )
//        case .tp_as_number:
//            return .init(fromProtocol: NilLiteralExprSyntax() )
//        case .tp_as_sequence:
//            return .init(fromProtocol: cls.pySequenceMethodsExpr )
        case .tp_call:
            return .init(fromProtocol: NilLiteralExprSyntax() )
        case .tp_str:
            return .init(fromProtocol: tp_str ?? NilLiteralExprSyntax() )
        case .tp_repr:
            return .init(fromProtocol: tp_repr ?? NilLiteralExprSyntax() )
        case .tp_hash:
            return .init(fromProtocol: tp_hash ?? NilLiteralExprSyntax() )
//        case .tp_as_buffer:
//            return .init(fromProtocol: NilLiteralExprSyntax() )
        }
        
    }
}


public func createPyMethodDefHandler(functions: [WrapFunction]) -> FunctionCallExprSyntax {
	let exp = DeclReferenceExprSyntax(baseName: .identifier("PyMethodDefHandler"))
    return .init(
        
        calledExpression: exp,
        //leftParen: .leftParen.withTrailingTrivia(.newline.appending(.tabs(1))),
		leftParen: .leftParenToken(trailingTrivia: .newline.appending(.tab)),
        argumentList: .init {
            for (i, f) in functions.enumerated() {
                switch i {
                case 0:  
						LabeledExprSyntax(expression: PySwiftFunction(function: f).FunctionCallExprSyntax)
						//.init(expression: PySwiftFunction(function: f).FunctionCallExprSyntax)
                default: LabeledExprSyntax(expression: PySwiftFunction(function: f).FunctionCallExprSyntax)
                        //.with(\.leadingTrivia, .newlines(2))
						//.with(\.leadingTrivia, .newLine)
                }
                
            }
        },
		rightParen: .rightParenToken(leadingTrivia: .newline)
				//.rightParen.with(\.leadingTrivia, .newline)
    )
}
