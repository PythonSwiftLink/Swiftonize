//
//  File.swift
//  
//
//  Created by MusicMaker on 12/04/2023.
//

import Foundation
import PySwiftCore
import PyAst

extension _WrapArg {
    
    public static func fromAst(index: Int,_ v: PyAstObject) -> WrapArgProtocol {
        //print(tab,tab,"fromAst:", v)
        switch v {
        case let arg as PyAst_Arg:
            //print(v.name,arg.annotation)
            
            return _fromAst(index: index, arg.annotation!, name: arg.name)
        case let sub as PyAst_Subscript:
            //return sub.newWrapArg(idx: idx, name: sub.name)
            
            return fromSubscript(index: index, value: sub, name: sub.value.name)
        case let n as PyAst_Name:
            return wrapArgFromType(name: n.name, type: .init(rawValue: v.name) ?? .other, _other_type: n.name, idx: index, options: [])
        default:
            print(v.name)
            fatalError(String(describing: v))
        }
    }
    
    static func _fromAst(index: Int,_ v: PyAstObject, name: String) -> WrapArgProtocol {
        //print(tab,tab,tab,"_fromAst:", name, v.name)
        
        switch v {
        case let arg as PyAst_Arg:
            return _fromAst(index: index, arg.annotation!, name: name)
        case let sub as PyAst_Subscript:
            //return sub.newWrapArg(idx: idx, name: sub.name)
            //print(tab,tab,tab,"sub as PyAst_Subscript: ",sub,sub.name,sub.value.name, sub.slice)
            return fromSubscript(index: index, value: sub, name: name)
        case let n as PyAst_Name:
            return wrapArgFromType(name: name, type: .init(rawValue: n.name) ?? .other, _other_type: n.name, idx: index, options: [])
        case let c as PyAst_Constant:
            return wrapArgFromType(name: name, type: .init(rawValue: c.name) ?? .other, _other_type: c.name, idx: index, options: [])
        case let l as PyAst_List:
            if let ltype = l.elts.first {
                return _fromAst(index: index, ltype, name: name)
            }
            return wrapArgFromType(name: name, type: .list, _other_type: nil, idx: index, options: [])
		case let a as PyAst_AnnAssign:
			return wrapArgFromType(name: name, type: .init(rawValue: a.annotation.name) ?? .other, _other_type: a.annotation.name, idx: index, options: [])
        default:
            //print(v)
            fatalError(String(describing: v))
        }
    }
    
    static func fromSubscript(index: Int, value v: PyAst_Subscript, name: String) -> WrapArgProtocol {
        
        let slice = v.slice
        //print("fromSubscript",v.value.name, slice.name)
        if let _type = PythonType(rawValue: v.value.name) {
            switch _type {
            case .optional:
                let optional_wrapped = _fromAst(index: 0, slice, name: name)
                optional_wrapped.add_option(.optional)
                return optionalArg(
                    name: name,
                    type: optional_wrapped.type,
                    other_type: optional_wrapped.other_type,
                    idx: index,
                    options: [],
                    wrapped: optional_wrapped)
            case .list, .tuple, .sequence, .array, .Array:
                let element = _fromAst(index: 0, slice, name: name)
                return collectionArg(
                    name: name,
                    type: _type,
                    other_type: element.other_type,
                    idx: index,
                    options: [],
                    element: element
                )
            case .callable:
                
                return callableArg(_name: name, _idx: index, ast: slice)
                let args: [WrapArgProtocol]
                switch slice.type {
                case .Tuple:
                    let tuple = slice as! PyAst_Tuple
                    let telts = tuple.elts
                    guard telts.count > 0 else { break }
                    switch telts[0] {
                    case let _tuple as PyAst_Tuple:
                        args = _tuple.elts.enumerated().map { i, a in _fromAst(index: i, a, name: "__arg\(i)__") }
                    case let _list as PyAst_List:
                        args = _list.elts.enumerated().map { i, a in _fromAst(index: i, a, name: "__arg\(i)__") }
                    default:
                        
                        fatalError("\(telts[0])")
                    }
                    
                    if telts.count > 1 {
                        _fromAst(index: 0, telts[1], name: "returns")
                    }
                    //let args = tuple.elts.enumerated().map { i, a in _fromAst(index: i, a, name: "__arg\(i)__") }
                    return callableArg(_name: name,  _idx: index, _options: [], args: args)
                case .List:
                    let list = slice as! PyAst_List
                    //let args = list.elts.enumerated().map(fromAst)
                    let args = list.elts.enumerated().map { i, a in _fromAst(index: i, a, name: "__arg\(i)__") }
                    return callableArg(_name: name,  _idx: index, _options: [], args: args)
                default:
                    return callableArg(_name: name,  _idx: index, _options: [], args: [])
                }
            
            default: return _fromAst(index: index, slice, name: name)
            }
        }
        
        fatalError(v.name)
    }
    
    public static func wrapArgFromType(name: String, type: PythonType, _other_type: String?, idx: Int, options: [WrapArgOptions]) -> WrapArgProtocol {
        switch type {
            
        case .int, .int32, .int16, .int8, .uint, .uint32, .uint16, .uint8, .long, .ulong, .short, .ushort:
            return intArg(_name: name, _type: type, _other_type: nil, _idx: idx, _options: options)
        case .float, .float32, .double:
            return floatArg(_name: name, _type: type, _other_type: nil, _idx: idx, _options: options)
        case .str:
            return strArg(_name: name, _type: type, _other_type: nil, _idx: idx, _options: options)
        case .data:
            return dataArg(_name: name, _type: type, _other_type: nil, _idx: idx, _options: options)
        case .jsondata:
            return jsonDataArg(_name: name, _type: type, _other_type: nil, _idx: idx, _options: options)
        case .bool:
            return boolArg(_name: name, _type: .bool, _other_type: nil, _idx: idx, _options: options)
        case .url, .error:
            //return strArg(_name: name, _type: .other, _other_type: _other_type, _idx: idx, _options: options)
            return strArg(_name: name, _type: type, _other_type: type.rawValue, _idx: idx, _options: options)
        
        case .other:
			
            return otherArg(_name: name, _type: .other, _other_type: _other_type, _idx: idx, _options: options)
        case .None, .void:
            return objectArg(_name: name, _type: type, _other_type: nil, _idx: idx, _options: options)
        default:
            return objectArg(_name: name, _type: .object, _other_type: nil, _idx: idx, _options: options)
        }
    }
    
}
