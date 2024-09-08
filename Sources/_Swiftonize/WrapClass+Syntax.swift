//
//  File.swift
//  
//
//  Created by MusicMaker on 29/04/2023.
//

import Foundation
import SwiftSyntax
import SwiftParser
import WrapContainers

extension WrapClass: WithStatementsSyntax {
	public var statements: SwiftSyntax.CodeBlockItemListSyntax {
		get {
			code
		}
		set(newValue) {
			
		}
	}
	
//    public var statements: SwiftSyntax.CodeBlockItemListSyntax {
//        code
//    }
    
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
        //code.childNameForDiagnostics(index)
		nil
    }
    
    
}



extension WrapClass {
    
    var code: CodeBlockItemListSyntax {
        return .init {
            
//            if let methods = pyMethodDefHandler {
//                methods
//            }
            if callbacks.count > 0 {
                PyCallbacksGenerator(cls: self).code.with(\.leadingTrivia, .newline)
            }
            pySwiftType.with(\.leadingTrivia, .newline)
			pySwiftTypeForCheck.with(\.leadingTrivia, .newline)
			
            createPyClass
			createPyClassUnRetained
            createPyObjectClass
			createPyObjectClassUnretained
            
            if let pyProtocol = pyProtocol {
                pyProtocol.with(\.leadingTrivia, .newline)
            }
            
        }.with(\.leadingTrivia, .newline)
        
        
    }
    
    public var pySwiftType: VariableDeclSyntax {
		let name = PatternSyntax(stringLiteral: "\(title)PyType")
        //let name = IdentifierPatternSyntax(identifier: .identifier("\(title)PyType"))
		let var_decl = VariableDeclSyntax(modifiers: [.init(name: .keyword(.public))],.let, name: name, initializer: createPySwiftType.initClause )
        return var_decl
    }
	public var pySwiftTypeForCheck: VariableDeclSyntax {
//		let name = IdentifierPatternSyntax(identifier: .identifier("py\(title)_Type"))
		let name = PatternSyntax(stringLiteral: "py\(title)_Type")
		let var_decl = VariableDeclSyntax(
			modifiers: [.init(name: .keyword(.public))],
			.let,
			name: name,
			//initializer: .init(value: MemberAccessExprSyntax(stringLiteral: "\(title)PyType.pytype"))
			initializer: .init(value: ExprSyntax(stringLiteral:  "\(title)PyType.pytype"))
		)
		return var_decl
	}
	
	
    
    var pyGetSets: FunctionCallExprSyntax {
        //let exp = IdentifierExprSyntax(stringLiteral: "PyGetSetDefHandler")
		let exp: ExprSyntax = "PyGetSetDefHandler"
        let list = TupleExprElementListSyntax {
            for p in properties {
                let prop = PyGetSetProperty(_property: p, _cls: self)

                TupleExprElementSyntax(expression: prop.callExpr).with(\.leadingTrivia, .newline)
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
                TupleExprElementSyntax(expression: cb_getset.callExpr).with(\.leadingTrivia, .newline)
            }
            
        }
        
        
        return .init(
            calledExpression: exp,
			leftParen: .leftParenToken(trailingTrivia: .newline),//.leftParen.withTrailingTrivia(.newline ),
            argumentList: list,
			rightParen: .rightParenToken(leadingTrivia: .newline)//.with(\.leadingTrivia, .newline)
        )
    }
    
	var createPySwiftType: FunctionCallExprSyntax {
//        let exp = IdentifierExprSyntax(stringLiteral: "SwiftPyType")
		let exp: ExprSyntax = "SwiftPyType"
        var prop_check: Bool {
            if callbacks.count > 0 { return false }
            return properties.count == 0
        }
        return .init(
            calledExpression: exp,
            leftParen: .leftParenToken(trailingTrivia: .newline),
            argumentList: .init {
//                TupleExprElementSyntax(
//                    label: "name",
//                    expression: .init( StringLiteralExprSyntax(content: _title) )
//                ).with(\.leadingTrivia, .newline)
				LabeledExprSyntax(
					label: "name",
					expression: StringLiteralExprSyntax(content: _title)
				).with(\.leadingTrivia, .newline)
				
                TupleExprElementSyntax(
                    label: "functions",
                    expression: pyTypeFunctions
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "methods",
                    //expression: .init(fromProtocol: send_functions.count == 0 ? NilLiteralExprSyntax() : _pyMethodDefHandler )
					expression: ExprSyntax(fromProtocol: send_functions.count == 0 ? NilLiteralExprSyntax() : _pyMethodDefHandler)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "getsets",
                    expression: ExprSyntax(fromProtocol: prop_check ? NilLiteralExprSyntax() : pyGetSets )
					//expression: ExprSyntax(nilOrExpression: prop_check ? nil : pyGetSets)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "sequence",
                    //expression: ExprSyntax(fromProtocol: pySequenceMethods.count == 0 ? NilLiteralExprSyntax() : pySequenceMethodsExpr )
					expression: ExprSyntax.init(nilOrExpression: pySequenceMethods.count == 0 ? nil : pySequenceMethodsExpr )
                ).with(\.leadingTrivia, .newline)
				TupleExprElementSyntax(
					label: "mapping",
					//expression: ExprSyntax(fromProtocol: pySequenceMethods.count == 0 ? NilLiteralExprSyntax() : pySequenceMethodsExpr )
					expression: ExprSyntax.init(nilOrExpression: !bases.contains(where: {$0 == .MutableMapping}) ? nil : pyMappingMethodsExpr )
				).with(\.leadingTrivia, .newline)
//                TupleExprElementSyntax(
//                    label: "buffer",
//                    expression: ExprSyntax(fromProtocol: !self.pyClassMehthods.contains(where: {$0 == .__buffer__}) ? NilLiteralExprSyntax() : pyBufferExpr )
//                ).with(\.leadingTrivia, .newline)
            },
            rightParen: .rightParenToken(leadingTrivia: .newline)
        )
        
    }
    
    private var pyTypeFunctions: FunctionCallExprSyntax {
//        let exp = IdentifierExprSyntax(stringLiteral: "PyTypeFunctions")
		let exp: ExprSyntax = "PyTypeFunctions"
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
			leftParen: .leftParenToken(trailingTrivia: .newline),//.withTrailingTrivia(.newline ),
            argumentList: .init {
                TupleExprElementSyntax(
                    label: "tp_init",
                    expression: py_type_funcs.export(.tp_init)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_new",
                    expression: py_type_funcs.export(.tp_new)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_dealloc",
					expression: self.unretained ? .init(NilLiteralExprSyntax()) : py_type_funcs.export(.tp_dealloc)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_getattr",
                    expression: py_type_funcs.export(.tp_getattr)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_setattr",
                    expression: py_type_funcs.export(.tp_setattr)
                ).with(\.leadingTrivia, .newline)
//                TupleExprElementSyntax(
//                    label: "tp_as_number",
//                    expression: py_type_funcs.export(.tp_as_number)
//                ).with(\.leadingTrivia, .newline)
//                TupleExprElementSyntax(
//                    label: "tp_as_sequence",
//                    expression: py_type_funcs.export(.tp_as_sequence)
//                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_call",
                    expression: py_type_funcs.export(.tp_call)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_str",
                    expression: py_type_funcs.export(.tp_str)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_repr",
                    expression: py_type_funcs.export(.tp_repr)
                ).with(\.leadingTrivia, .newline)
                TupleExprElementSyntax(
                    label: "tp_hash",
                    expression: py_type_funcs.export(.tp_hash)
                ).with(\.leadingTrivia, .newline)
//                TupleExprElementSyntax(
//                    label: "tp_as_buffer",
//                    expression: py_type_funcs.export(.tp_as_buffer)
//                ).with(\.leadingTrivia, .newline)
   
            },
			rightParen: .rightParenToken(leadingTrivia: .newline)//.with(\.leadingTrivia, .newline)
        )
        
    }
    
    var pyBufferExpr: FunctionCallExprSyntax {
		let f: FunctionCallExprSyntax = try! .init("""
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
			_releaseBuffer : { s, buf in
			
			}
		)
		""")
        return f
    
    }
    
    var pySequenceMethodsExpr: FunctionCallExprSyntax {
        //let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
		let exp: ExprSyntax = ".init"
        return .init(
            
            calledExpression: exp,
            leftParen: .leftParenToken(),
            argumentList: .init {
                TupleExprElementSyntax(
                    label: "methods",
					expression: GenPySequenceMethods(cls: self).output
                )
            },
			rightParen: .rightParenToken(leadingTrivia: .newline)//.with(\.leadingTrivia, .newline)
        )
    }
	
	var pyMappingMethodsExpr: ExprSyntax {
		//let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
		let exp: ExprSyntax = ".init"
		return WrapClass.PyMappingMethods(cls: self).output
//		return .init(
//			
//			calledExpression: exp,
//			leftParen: .leftParenToken(),
//			argumentList: .init {
//				TupleExprElementSyntax(
//					label: "mapping",
//					expression: WrapClass.PyMappingMethods(cls: self).output
//				)
//			},
//			rightParen: .rightParenToken(leadingTrivia: .newline)//.with(\.leadingTrivia, .newline)
//		)
	}
    
    var PySequenceMethodWrapExpr: FunctionCallExprSyntax {
        let exp = IdentifierExprSyntax(identifier: .identifier(".init"))
        
        var length_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        var concat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        var repeat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        var get_item_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        var set_item_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        var contains_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        var inplace_concat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        var inplace_repeat_expr: ExprSyntax = .init(fromProtocol: NilLiteralExprSyntax() )
        
        for method in pySequenceMethods {
            switch method {
            case .__len__:
				length_expr = .init(fromProtocol: method.callExpr(cls: title))
            case .__getitem__(_, _):
                //break//
				get_item_expr = .init(fromProtocol: method.callExpr(cls: title))
            case .__setitem__(_, _):
                set_item_expr = .init(fromProtocol: method.callExpr(cls: title))
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
			leftParen: .leftParenToken(leadingTrivia: .newline),//.with(\.leadingTrivia, .newline),
            argumentList: .init {
                
                TupleExprElementSyntax(
                    label: "length",
                    expression: length_expr
                ).with(\.leadingTrivia, .newline)
                
                
                TupleExprElementSyntax(
                    label: "concat",
                    expression: concat_expr
                ).with(\.leadingTrivia, .newline)
                
                TupleExprElementSyntax(
                    label: "repeat_",
                    expression: repeat_expr
                ).with(\.leadingTrivia, .newline)
                
                TupleExprElementSyntax(
                    label: "get_item",
                    expression: get_item_expr
                ).with(\.leadingTrivia, .newline)
                
                TupleExprElementSyntax(
                    label: "set_item",
                    expression: set_item_expr
                ).with(\.leadingTrivia, .newline)
                
                TupleExprElementSyntax(
                    label: "contains",
                    expression: contains_expr
                ).with(\.leadingTrivia, .newline)
                
                TupleExprElementSyntax(
                    label: "inplace_concat",
                    expression: inplace_concat_expr
                ).with(\.leadingTrivia, .newline)
                
                TupleExprElementSyntax(
                    label: "inplace_repeat",
                    expression: inplace_repeat_expr
                ).with(\.leadingTrivia, .newline).with(\.leadingTrivia, .newline)
 
            },
			rightParen: .rightParenToken(leadingTrivia: .newline)//.with(\.leadingTrivia, .newline)
        )
    }
    
    public var pyMethodDefHandler: VariableDeclSyntax? {
        if send_functions.isEmpty { return nil }
        //let name = IdentifierPatternSyntax(identifier: .identifier("\(title)_PyMethods"))
		let name: PatternSyntax = "\(raw: title)_PyMethods"
        let var_decl = VariableDeclSyntax(.let, name: name, initializer: _pyMethodDefHandler.initClause )
        
        //return var_decl.withModifiers(.init(DeclModifierSyntax(name: .fileprivate)))
		return var_decl.with(\.modifiers, .init(arrayLiteral: .init(name: .keyword(.fileprivate))))
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
//                    case 0:  .init(expression: PySwiftFunction(function: f).FunctionCallExprSyntax)
//                    default: .init(expression: PySwiftFunction(function: f).FunctionCallExprSyntax)
//                                .with(\.leadingTrivia, .newlines(2))
//                    }
//
//                }
//            }),
//            rightParen: .rightParen.with(\.leadingTrivia, .newline)
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
        public func create_py\(title)(_ target: \(title)) -> PyPointer {
            let new = PySwiftObject_New(py\(title)_Type)
            PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
            return new!
        }
        """))).with(\.leadingTrivia, .newline)
    }
    fileprivate var createPyObjectClass: CodeBlockItemSyntax {
        .init(item: .decl(.init(stringLiteral: """
        public func _create_py\(title)(_ target: \(title)) -> PythonObject {
            let new = PySwiftObject_New(py\(title)_Type)!
            PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passRetained(target).toOpaque()
            return .init(ptr: new, from_getter: true)
        }
        """))).with(\.leadingTrivia, .newline)
    }
	
	fileprivate var createPyClassUnRetained: CodeBlockItemSyntax {
		.init(item: .decl(.init(stringLiteral: """
		public func create_py\(title)(unretained target: \(title)) -> PyPointer {
			let new = PySwiftObject_New(py\(title)_Type)
			PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
			return new!
		}
		"""))).with(\.leadingTrivia, .newline)
	}
	fileprivate var createPyObjectClassUnretained: CodeBlockItemSyntax {
		.init(item: .decl(.init(stringLiteral: """
		public func _create_py\(title)(unretained target: \(title)) -> PythonObject {
			let new = PySwiftObject_New(py\(title)_Type)!
			PySwiftObject_Cast(new).pointee.swift_ptr = Unmanaged.passUnretained(target).toOpaque()
			return .init(ptr: new, from_getter: true)
		}
		"""))).with(\.leadingTrivia, .newline)
	}
    
}






