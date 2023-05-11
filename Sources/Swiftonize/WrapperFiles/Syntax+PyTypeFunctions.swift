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
import SwiftSyntaxParser


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
    
    
    
    var tp_init: ClosureExpr {
        if !cls.ignore_init {
            return create_tp_init
        }
        return .init(stringLiteral: """
        { s, _args_, kw -> Int32 in
            PyErr_SetString(PyExc_NotImplementedError,"\(cls.title) can only be inited from swift")
            return -1
        }
        """)
    }
    
    var tp_new: ClosureExpr {
        .init(stringLiteral: """
        { type, args, kw -> PyPointer? in
            PySwiftObject_New(type)
        }
        """)
    }
    
    var tp_dealloc: ClosureExpr {
        let closure = ClosureExpr(stringLiteral: "{ s in }")
        return closure.withStatements(.init {
            let if_ptr = IfStmt(stringLiteral: "if let ptr = PySwiftObject_Cast(s).pointee.swift_ptr { }")
            if_ptr.withBody(.init {
                FunctionCallExpr(stringLiteral: "Unmanaged<\(cls.title)>.fromOpaque(ptr).release()")
            })
        })
    }
    
    var tp_getattr: ClosureExpr? {
        guard options.contains(.tp_getattr) else { return nil }
        return .init(stringLiteral: """
        { type, args, kw -> PyPointer? in
            // TODO
        }
        """)
    }
    
    var tp_hash: ClosureExpr? {
        guard options.contains(.tp_hash) else { return nil }
        return .init(stringLiteral: """
        { _self_ -> Int in
            UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__hash__
        }
        """)
    }
    var tp_str: ClosureExpr? {
        guard options.contains(.tp_str) else { return nil }
        return .init(stringLiteral: """
        
        { _self_ -> PyPointer? in
            UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__str__().pyPointer
        }
        """)
    }
    
    var tp_repr: ClosureExpr? {
        guard options.contains(.tp_repr) else { return nil }
        return .init(stringLiteral: """
        { _self_ -> PyPointer? in
            UnPackPySwiftObject(with: _self_, as: \(cls.title).self).__repr__().pyPointer
        }
        """)
    }
}


extension PyTypeFunctions {
    
    private var create_tp_init: ClosureExpr {
        
        let closure = ClosureExpr(stringLiteral: "{ __self__, _args_, kw -> Int32 in }")
        
        return closure.withStatements(.init {
            if cls.debug_mode { Expr(stringLiteral: #"print("tp_init - <\#(cls.title)>")"#) }
            createTP_Init(cls: cls, args: cls.init_function?._args_ ?? []).code
            ReturnStmt(stringLiteral: "return 1")
        })
        
        
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
            return .init(stringLiteral:
                tp_dealloc.formatted().description
                    .replacingOccurrences(of: "d < ", with: "d<")
                    .replacingOccurrences(of: " > .", with: ">.")
            )
        case .tp_getattr:
            if let tp_getattr = tp_getattr {
                return .init(fromProtocol: tp_getattr )
            }
            return .init(fromProtocol: NilLiteralExpr() )
        case .tp_setattr:
            return .init(fromProtocol: NilLiteralExpr() )
//        case .tp_as_number:
//            return .init(fromProtocol: NilLiteralExpr() )
//        case .tp_as_sequence:
//            return .init(fromProtocol: cls.pySequenceMethodsExpr )
        case .tp_call:
            return .init(fromProtocol: NilLiteralExpr() )
        case .tp_str:
            return .init(fromProtocol: tp_str ?? NilLiteralExpr() )
        case .tp_repr:
            return .init(fromProtocol: tp_repr ?? NilLiteralExpr() )
        case .tp_hash:
//            if let tp_hash = tp_hash {
//                return .init(tp_hash)
//            }
            return .init(fromProtocol: tp_hash ?? NilLiteralExpr() )
//        case .tp_as_buffer:
//            return .init(fromProtocol: NilLiteralExpr() )
        }
        
    }
}


public func createPyMethodDefHandler(functions: [WrapFunction]) -> FunctionCallExprSyntax {
    let exp = IdentifierExprSyntax(identifier: .identifier("PyMethodDefHandler"))
    return .init(
        
        calledExpression: exp,
        leftParen: .leftParen.withTrailingTrivia(.newline.appending(.tabs(1))),
        argumentList: .init {
            for (i, f) in functions.enumerated() {
                switch i {
                case 0:  .init(expression: PySwiftFunction(function: f).functionCallExpr)
                default: .init(expression: PySwiftFunction(function: f).functionCallExpr)
                        .withLeadingTrivia(.newlines(2))
                }
                
            }
        },
        rightParen: .rightParen.withLeadingTrivia(.newline)
    )
}
