

import Foundation
import WrapContainers
import SwiftSyntax
import SwiftSyntaxBuilder



private enum SwiftTypes: String {
	case Int
	case Int32
	case Int16
	case Int8
	case UInt
	case UInt32
	case UInt16
	case UInt8
	case Float
	case Double
	case String
	case Array
	case Data
}

func swiftType_to_WrapArg(type: TypeSyntax) {
	
}
public func wrapArgFromType(name: String, type: TypeSyntax, idx: Int = 0, options: [WrapArgOptions] = [])  -> WrapArgProtocol {
	fatalError()
//	let kind = type.kind
//	var options = options
//	switch kind {
//	case .simpleTypeIdentifier:
//		let simple = type.as(SimpleTypeIdentifier.self)!
//		let type = simple.name.text
//		if type == "String" {
//			return strArg(_name: name, _type: .str, _other_type: nil, _idx: idx, _options: options)
//		}
//		if let pyType = PythonType(rawValue: type.lowercased()) {
//			return _WrapArg.wrapArgFromType(name: name, type: pyType, _other_type: nil, idx: idx, options: options)
//		}
//		//fatalError("\(type)")
//		return otherArg(_name: name, _type: .other, _other_type: type, _idx: idx, _options: options)
//	case .arrayType:
//		let arrayType = type.as(ArrayType.self)!
//		let array = collectionArg(
//			name: name,
//			type: .list,
//			other_type: nil,
//			idx: idx,
//			options: options,
//			element: wrapArgFromType(name: name, type: arrayType.elementType, idx: idx, options: [])
//		)
//		let _array = array as WrapArgSyntax
//		let info = _array.typeAnnotation.description
//		
//		return array
//	case .optionalType:
//		let optional = type.as(OptionalType.self)!
//		options.append(.optional)
//		
//		return optionalArg(
//			name: name,
//			type: .optional,
//			other_type: nil,
//			idx: idx,
//			options: options,
//			wrapped: wrapArgFromType(name: name, type: optional.wrappedType, idx: idx, options: options)
//		)
//	case .attributedType:
//		let attrType = type.as(AttributedType.self)!
//		let baseType = attrType.baseType
//		switch baseType.kind {
//		case .functionType:
//			let functionType = baseType.as(FunctionType.self)!
//			
//			
//			for argument in functionType.arguments {
//				if let arg = argument.type.as(AttributedType.self) {
//					let argBaseType = arg.baseType
//					if let innerCallArg = argBaseType.as(FunctionType.self) {
//				
//						return callableArg(
//							name: name,
//							idx: idx,
//							callArgs: innerCallArg.arguments.map(_WrapArg.fromSyntax),
//							_return: objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [.return_])
//						)
//					}
//				}
//			}
//			return callableArg(
//				name: name,
//				idx: idx,
//				callArgs: functionType.arguments.map(_WrapArg.fromSyntax),
//				_return: objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [.return_])
//			)
//			
//		case .memberTypeIdentifier:
//			
//			break
//		case .simpleTypeIdentifier:
//			
//			fatalError()
//		default: fatalError("\(baseType.kind)")
//		}
//		break
//	default: break
//	}
//	
//	print("\(kind) -> \(name)")
//
//	
//	return otherArg(_name: name, _type: .other, _other_type: "unknownType", _idx: idx, _options: options)
}

extension _WrapArg {
	//FunctionParameterSyntax
	public static func fromSyntax(_ syntax: FunctionParameterSyntax) -> WrapArgProtocol {
		fatalError()
//		let t = syntax.type!
//		var options = [WrapArgOptions]()
//		var name: String {
//			if let firstName = syntax.firstName?.text {
//				if firstName == "_" {
//					
//					options.append(.no_label)
//					if let secondName = syntax.secondName?.text {
//						
//						return secondName
//					}
//				}
//				if let secondName = syntax.secondName?.text {
//					return secondName
//				}
//				return firstName
//			}
//			
//			fatalError("label error")
//		}
//		
//		let idx = syntax.indexInParent
//		return Swiftonize.wrapArgFromType(name: name, type: t, idx: idx, options: options)
	}
	
	//TupleTypeElementSyntax
	
	public static func fromSyntax(_ syntax: TupleTypeElementSyntax) -> WrapArgProtocol {
		fatalError()
//		let idx = syntax.indexInParent
//		let name = syntax.name?.text ?? "arg\(idx)"
//		let t = syntax.type
//		var options = [WrapArgOptions]()
////		let t = syntax.type!
////		var options = [WrapArgOptions]()
////		var name: String {
////			if let firstName = syntax.firstName?.text {
////				if firstName == "_" {
////					
////					options.append(.no_label)
////					if let secondName = syntax.secondName?.text {
////						
////						return secondName
////					}
////				}
////				if let secondName = syntax.secondName?.text {
////					return secondName
////				}
////				return firstName
////			}
////			
////			fatalError("label error")
////		}
//		
//		
//		return Swiftonize.wrapArgFromType(name: name, type: t, idx: idx, options: options)
	}
}

func swiftToPythonType(type: TypeSyntax) -> PythonType {
	//let t = type.description.trimmingCharacters(in: .whitespaces)
	fatalError()
//	switch type.kind {
//	case .simpleTypeIdentifier:
//		if let t = type.as(SimpleTypeIdentifier.self) {
//			if t.name.text == "String" { return .str }
//			if let pyType = PythonType(rawValue: t.name.text.lowercased()) {
//				print(pyType)
//				return pyType
//			}
//			//fatalError("\(t.name.text)")
//			return .other
//		}
//		fatalError("\(type.kind)")
//	case .arrayType:
//		let arrayType = type.as(ArrayType.self)!
//		let t = arrayType.elementType.as(SimpleTypeIdentifier.self)!
//		if t.name.text == "String" { return .str }
//		if let pyType = PythonType(rawValue: t.name.text.lowercased()) {
//			return pyType
//		}
//		
//		fatalError("\(t.name.text)")
//	case .optionalType:
//		return .optional
//	case .tupleType:
//		return .tuple
//	default:
//		fatalError("\(type.kind)")
//	}
}



extension WrapClass {
	convenience init(syntax: ClassDeclSyntax) {
		fatalError()
//		self.init(syntax.identifier.text)
//		let members = syntax.members.members
//		properties = members
//			.compactMap({ member in member.decl.as(VariableDeclSyntax.self) })
//			.filter({$0.modifiers?.contains(where: {d in d.name.text != "private"} ) ?? true})
//			.map(WrapClassProperty.init)
//		functions = members.compactMap { member in
//			let decl = member.decl
//			if let f =  decl.as(FunctionDeclSyntax.self) {
//				switch f.identifier.text {
//				case "hash", "==": return nil
//				default: break
//				}
//				return .init(syntax: f)
//			}
//			return nil
//		}
		
	}
}


extension WrapFunction {
	convenience init(syntax: FunctionDeclSyntax) {
		
		let name = syntax.identifier.text
		
		let signature = syntax.signature
		
		let parameters = signature.input
		let returnClause = signature.output
		
		let pyReturn: WrapArgProtocol
		if let returnClause = returnClause {
			let returnPyType = swiftToPythonType(type: returnClause.returnType)
			if returnPyType == .void {
				pyReturn = objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [.return_])
			} else {
				pyReturn = _WrapArg.wrapArgFromType(name: "", type: returnPyType, _other_type: nil, idx: 0, options: [.return_])
			}
		} else {
			pyReturn = objectArg(_name: "", _type: .void, _other_type: nil, _idx: 0, _options: [.return_])
		}
		

		
		let parameterList = parameters.parameterList.map(_WrapArg.fromSyntax)
		
		//let _args_: [WrapArgProtocol] = parameterList
		//fatalError()
		self.init(
			name: name,
			_args_: parameterList,
			_return_: pyReturn,
			options: [.no_protocol],
			wrap_class: nil
		)
	}
}


extension WrapClassProperty {
	convenience init(syntax: VariableDeclSyntax) {
		fatalError()
//		if let binding = syntax.bindings.first {
//			var pyType: PythonType = .object
//			var getset: ClassPropertyType = .Getter
//			if let accessor = binding.accessor {
//				switch accessor.kind {
//				case .codeBlock:
//					let codeBlock = accessor.as(CodeBlock.self)!
//					
//				case .accessorBlock:
//					let acc = accessor.as(AccessorBlock.self)!
//					if acc.accessors.contains(where: {a in a.accessorKind.text == "set"}) {
//						getset = .GetSet
//					}
//				default:
//					fatalError("\(accessor.kind)")
//				}
//				
//			}
//			if let type = binding.typeAnnotation?.type {
//				pyType = swiftToPythonType(type: type)
//			}
//			self.init(
//				name: binding.pattern.description,
//				property_type: getset,
//				arg_type: _WrapArg.wrapArgFromType(name: "", type: pyType, _other_type: nil, idx: 0, options: [])
//			)
//			return
//		}
		
		fatalError()
		//self.init(name: <#T##String#>, property_type: <#T##ClassPropertyType#>, arg_type: <#T##WrapArgProtocol#>)
	}
}
import SwiftParser
public extension WrapModule {
	convenience init(filename: String, file: String) {
		fatalError()
//		self.init(filename: "mySwiftTestfile")
//		for blockItem in Parser.parse(source: file).statements {
//			let item = blockItem.item
//			switch item {
//			case .decl(let decl):
//				switch decl.kind {
//				case .importDecl: break
//				case .classDecl:
//					classes.append( .init(syntax: decl.as(ClassDecl.self)! ))
//				case .extensionDecl: break
//				case .VariableDeclSyntax: break
//				case .protocolDecl: break
//				case .functionDecl:
//					functions.append( .init(syntax: decl.as(FunctionDecl.self)! ))
//				default:
//					fatalError("\(decl.kind)")
//				}
//				
//			case .expr(let expr): fatalError()
//			case .stmt(let stmt): fatalError()
//			case .tokenList(_): fatalError()
//			case .nonEmptyTokenList(_): fatalError()
//			}
//		}
	}
}
