//
//  File.swift
//  
//
//  Created by MusicMaker on 29/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftParser


extension WrapClass: WithStatementsSyntax {
    public var statements: SwiftSyntax.CodeBlockItemListSyntax {
        code
    }
    
    public func withStatements(_ newChild: SwiftSyntax.CodeBlockItemListSyntax?) -> Self {
        self
    }
    
    public var _syntaxNode: SwiftSyntax.Syntax {
        .init(code)
    }
    
    public static var structure: SwiftSyntax.SyntaxNodeStructure {
        .choices([.node(CodeBlockItemListSyntax.self)])
    }
    
    public func childNameForDiagnostics(_ index: SwiftSyntax.SyntaxChildrenIndex) -> String? {
        code.childNameForDiagnostics(index)
    }
    
    
}

extension WrapClass {
    
    var code: CodeBlockItemListSyntax {
        return .init {
            
//            if let methods = pyMethodDefHandler {
//                methods
//            }
            if callbacks.count > 0 {
                PyCallbacksGenerator(cls: self).code.withLeadingTrivia(.newline)
            }
            pySwiftType.withLeadingTrivia(.newline)
            
            createPyClass
            createPyObjectClass
            
            if let pyProtocol = pyProtocol {
                pyProtocol.withLeadingTrivia(.newline)
            }
            
        }.withLeadingTrivia(.newline)
        
        
    }
    
    var pySwiftType: VariableDeclSyntax {
        let name = IdentifierPatternSyntax(identifier: .identifier("\(title)PyType"))
        let var_decl = VariableDeclSyntax(.let, name: name, initializer: createPySwiftType.initClause )
        return var_decl
    }
    
    var pyGetSets: FunctionCallExprSyntax {
        let exp = IdentifierExprSyntax(stringLiteral: "PyGetSetDefHandler")
        let list = TupleExprElementListSyntax {
            for p in properties {
                let prop = PyGetSetProperty(_property: p, _cls: self)

                TupleExprElementSyntax(expression: prop.callExpr).withLeadingTrivia(.newline)
            }
            if callbacks.count > 0 && !new_class {
                let prop = WrapClassProperty(
                    name: "py_callback",
                    property_type: .GetSet,
                    arg_type: objectArg(_name: "py_callback", _type: .object, _other_type: nil, _idx: 0, _options: [])
                )
                let cb_getset = PyGetSetProperty(
                    _property: prop,
                    _cls: self
                )
                TupleExprElementSyntax(expression: cb_getset.callExpr).withLeadingTrivia(.newline)
            }
            
        }
        
        
        return .init(
            calledExpression: exp,
            leftParen: .leftParen.withTrailingTrivia(.newline ),
            argumentList: list,
            rightParen: .rightParen.withLeadingTrivia(.newline)
        )
    }
    
    private var createPySwiftType: FunctionCallExprSyntax {
        let exp = IdentifierExprSyntax(stringLiteral: "SwiftPyType")
        var prop_check: Bool {
            if callbacks.count > 0 { return false }
            return properties.count == 0
        }
        return .init(
            calledExpression: exp,
            leftParen: .leftParen.withTrailingTrivia(.newline ),
            argumentList: .init {
                TupleExprElementSyntax(
                    label: "name",
                    expression: .init( StringLiteralExprSyntax(content: _title) )
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "functions",
                    expression: .init( pyTypeFunctions )
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "methods",
                    expression: .init(fromProtocol: send_functions.count == 0 ? NilLiteralExprSyntax() : _pyMethodDefHandler )
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "getsets",
                    expression: .init(fromProtocol: prop_check ? NilLiteralExprSyntax() : pyGetSets )
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "sequence",
                    expression: .init(fromProtocol: pySequenceMethods.count == 0 ? NilLiteralExprSyntax() : pySequenceMethodsExpr )
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "buffer",
                    expression: .init(fromProtocol: !self.pyClassMehthods.contains(where: {$0 == .__buffer__}) ? NilLiteralExprSyntax() : pyBufferExpr )
                ).withLeadingTrivia(.newline)
            },
            rightParen: .rightParen.withLeadingTrivia(.newline)
        )
        
    }
    
    private var pyTypeFunctions: FunctionCallExprSyntax {
        let exp = IdentifierExprSyntax(stringLiteral: "PyTypeFunctions")
        var py_type_options: [PyTypeFunctions.FunctionType] = [
            .tp_new, .tp_dealloc
        ]
        if init_function != nil {
            py_type_options.append(.tp_init)
        }
        for opt in pyClassMehthods {
            switch opt {
                
            case .__init__:
                continue
            case .__repr__:
                py_type_options.append(.tp_repr)
            case .__str__:
                py_type_options.append(.tp_str)
            case .__hash__:
                py_type_options.append(.tp_hash)
            case .__set_name__:
                continue
            case .__call__:
                py_type_options.append(.tp_call)
            case .__iter__:
                continue
            case .__buffer__:
                continue
            }
        }
        let py_type_funcs = PyTypeFunctions(options: py_type_options)
        py_type_funcs._cls = self
        return .init(
            calledExpression: exp,
            leftParen: .leftParen.withTrailingTrivia(.newline ),
            argumentList: .init {
                TupleExprElementSyntax(
                    label: "tp_init",
                    expression: py_type_funcs.export(.tp_init)
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_new",
                    expression: py_type_funcs.export(.tp_new)
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_dealloc",
                    expression: py_type_funcs.export(.tp_dealloc)
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_getattr",
                    expression: py_type_funcs.export(.tp_getattr)
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_setattr",
                    expression: py_type_funcs.export(.tp_setattr)
                ).withLeadingTrivia(.newline)
//                TupleExprElementSyntax(
//                    label: "tp_as_number",
//                    expression: py_type_funcs.export(.tp_as_number)
//                ).withLeadingTrivia(.newline)
//                TupleExprElementSyntax(
//                    label: "tp_as_sequence",
//                    expression: py_type_funcs.export(.tp_as_sequence)
//                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_call",
                    expression: py_type_funcs.export(.tp_call)
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_str",
                    expression: py_type_funcs.export(.tp_str)
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_repr",
                    expression: py_type_funcs.export(.tp_repr)
                ).withLeadingTrivia(.newline)
                TupleExprElementSyntax(
                    label: "tp_hash",
                    expression: py_type_funcs.export(.tp_hash)
                ).withLeadingTrivia(.newline)
//                TupleExprElementSyntax(
//                    label: "tp_as_buffer",
//                    expression: py_type_funcs.export(.tp_as_buffer)
//                ).withLeadingTrivia(.newline)
   
            },
            rightParen: .rightParen.withLeadingTrivia(.newline)
        )
        
    }
    
    var pyBufferExpr: FunctionCallExprSyntax {
        
        
        return .init(stringLiteral: """
        PyBufferProcsHandler(
            _getBuffer: { s, buf, flags in
            if let buf = buf {
                let _s = unsafeBitCast(s, to: PyPointer.self)
                let result = UnPackPySwiftObject(with: s, as: \(title).self).__buffer__(s: _s, buffer: buf)
                if result != -1 {
                    _s.incref()
                }
                return result
            }
            PyErr_SetString(PyExc_ValueError, "view in getbuffer is nil")
            return -1
            
            },
            _releaseBuffer: { s, buf in
            
            }
        )
        
        """)
    }
    
    var pySequenceMethodsExpr: FunctionCallExprSyntax {
        let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
        
        return .init(
            
            calledExpression: exp,
            leftParen: .leftParen,
            argumentList: .init {
                TupleExprElementSyntax(
                    label: "methods",
                    expression: .init( PySequenceMethodWrapExpr )
                )
            },
            rightParen: .rightParen.withLeadingTrivia(.newline)
        )
    }
    
    var PySequenceMethodWrapExpr: FunctionCallExprSyntax {
        let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
        
        var length_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        var concat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        var repeat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        var get_item_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        var set_item_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        var contains_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        var inplace_concat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        var inplace_repeat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax())
        
        for method in pySequenceMethods {
            switch method {
            case .__len__:
                length_expr = .init(fromProtocol: method.callExpr)
            case .__getitem__(_, _):
                break//get_item_expr = .init(fromProtocol: method.callExpr)
            case .__setitem__(_, _):
                set_item_expr = .init(fromProtocol: method.callExpr)
            case .__delitem__(_):
                break
            case .__missing__:
                break
            case .__reversed__:
                break
            case .__contains__:
                break
            }
        }
        
        
        return .init(
            
            calledExpression: exp,
            leftParen: .leftParen.withTrailingTrivia(.newline),
            argumentList: .init {
                
                TupleExprElementSyntax(
                    label: "length",
                    expression: length_expr
                ).withLeadingTrivia(.newline)
                
                
                TupleExprElementSyntax(
                    label: "concat",
                    expression: concat_expr
                ).withLeadingTrivia(.newline)
                
                TupleExprElementSyntax(
                    label: "repeat_",
                    expression: repeat_expr
                ).withLeadingTrivia(.newline)
                
                TupleExprElementSyntax(
                    label: "get_item",
                    expression: get_item_expr
                ).withLeadingTrivia(.newline)
                
                TupleExprElementSyntax(
                    label: "set_item",
                    expression: set_item_expr
                ).withLeadingTrivia(.newline)
                
                TupleExprElementSyntax(
                    label: "contains",
                    expression: contains_expr
                ).withLeadingTrivia(.newline)
                
                TupleExprElementSyntax(
                    label: "inplace_concat",
                    expression: inplace_concat_expr
                ).withLeadingTrivia(.newline)
                
                TupleExprElementSyntax(
                    label: "inplace_repeat",
                    expression: inplace_repeat_expr
                ).withLeadingTrivia(.newline).withTrailingTrivia(.newline)
 
            },
            rightParen: .rightParen.withLeadingTrivia(.newline)
        )
    }
    
    public var pyMethodDefHandler: VariableDeclSyntax? {
        if send_functions.isEmpty { return nil }
        let name = IdentifierPatternSyntax(identifier: .identifier("\(title)_PyMethods"))
        let var_decl = VariableDeclSyntax(.let, name: name, initializer: _pyMethodDefHandler.initClause )
        
        return var_decl.withModifiers(.init(DeclModifierSyntax(name: .fileprivate)))
    }
    
    public var _pyMethodDefHandler: FunctionCallExprSyntax {
        createPyMethodDefHandler(functions: send_functions)
//        let exp = IdentifierExprSyntax(identifier: .identifier("PyMethodDefHandler"))
//        return .init(
//
//            calledExpression: exp,
//            leftParen: .leftParen.withTrailingTrivia(.newline.appending(.tabs(1))),
//            argumentList: .init(itemsBuilder: {
//                for (i, f) in send_functions.enumerated() {
//                    switch i {
//                    case 0:  .init(expression: PySwiftFunction(function: f).functionCallExpr)
//                    default: .init(expression: PySwiftFunction(function: f).functionCallExpr)
//                                .withLeadingTrivia(.newlines(2))
//                    }
//
//                }
//            }),
//            rightParen: .rightParen.withLeadingTrivia(.newline)
//        )
    }
    
    public var _classMethods: PatternBindingListSyntax {
        let name = IdentifierPatternSyntax(identifier: .identifier("\(title)_PyMethods"))
        let binding = PatternBindingSyntax(
            pattern: name,
            initializer: .init(value: _pyMethodDefHandler)
        )
        return .init {
            binding
        }
    }
}

extension WrapClass {
    
    fileprivate var createPyClass: CodeBlockItemSyntax {
        .init(item: .decl(.init(stringLiteral: """
        func create_py\(title)(_ target: \(title)) -> PyPointer {
            let new = _PySwiftObject_New(\(title)PyType.pytype)
            PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
            return new!
        }
        """))).withLeadingTrivia(.newline)
    }
    fileprivate var createPyObjectClass: CodeBlockItemSyntax {
        .init(item: .decl(.init(stringLiteral: """
        func _create_py\(title)(_ target: \(title)) -> PythonObject {
            let new = PySwiftObject_New(\(title)PyType.pytype)
            PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
            return .init(ptr: new, from_getter: true)
        }
        """))).withLeadingTrivia(.newline)
    }
    
}






