//
//  WrapargsProtocol.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 14/03/2022.
//

import Foundation
import PySwiftCore
import PyAst
import SwiftSyntax
import SwiftSyntaxBuilder

public protocol WrapArgProtocol: Decodable {
    
    var name: String { get }
    var optional_name: String? { get set }
    var type: PythonType { get }
    var other_type: String? { get }
    var idx: Int { get }
    var options: [WrapArgOptions] { get }
    
    func add_option(_ option: WrapArgOptions)
    
    //var python_function_arg: String { get }
    //var python_call_arg: String { get }
    
    //var cython_header_arg: String { get }
    
    //var c_header_arg: String { get }
    
//    var swift_protocol_arg: String { get }
//    var swift_send_func_arg: String { get }
//    var swift_send_call_arg: String { get }
//    
//    var swift_callback_func_arg: String { get }
//    var swift_callback_call_arg: String { get }
//    
    var decref_needed: Bool { get }
//    var conversion_needed: Bool { get }
//    
    func convert_return(arg: String) -> String
//    
//    func convert_return_send(arg: String) -> String
//    
//    var swift_callback_return_type: String { get }
//    
//    var swift_send_return_type: String { get }
//    
//    func swift_property_getter(arg: String) -> String
//    
//    func swift_property_setter(arg: String) -> String
    
//    var typeExpr: TypeExprSyntax { get }
//    
//    var typeSyntax: TypeSyntax { get }
//    
//    var typeAnnotation: TypeAnnotationSyntax { get }
//    
//    func callTupleElement(many: Bool) -> TupleExprElement
//    
//    func extractDecl(many: Bool) -> VariableDeclSyntax?
}



public protocol PyCallbackExtactable {
    
    
    
    var other_type: String? { get }
    
    var options: [WrapArgOptions] { get }
    
    
    func cb_extractLine(many: Bool, for class_pointer: String) -> String?
    
    var function_arg_name: String { get }
    
    var call_arg_name: String { get }
    
    var callback_name: String? { get }
    
    var type: PythonType { get }
    
    var argType: String { get }
    
//    var typeAnnotation: TypeAnnotationSyntax { get }
//    
//    var typeSyntax: TypeSyntax { get }
}

protocol PySendExtactable {
    
    func extractLine(many: Bool,with t: (String?) -> String?, for class_pointer: String) -> String?
    
    var function_call_name: String? { get }
    
    func function_input(many: Bool) -> String
    
    var extract_needed: Bool { get }
    
}

public extension PyCallbackExtactable {
    
    
    var __SwiftType__: String {
        type.__swiftType__ ?? (other_type ?? "TypeNotMatched")
    }
    
    var function_arg: String {
        
        
        return "\(function_arg_name): \(argType)"
    }
    
    
}





public extension WrapArgProtocol {
    
    var __argType__: String {
        (self as? PyCallbackExtactable)?.argType ?? __swiftType__
    }
    
    var __swiftType__: String {
        if type == .callable {
            let call = self as! callableArg
            var call_result: String {
                let cargs = call.callArgs.map(\.__swiftType__).joined(separator: ", ")
                return "(\(cargs))->\(call._return?.swiftType ?? "Void")"
            }
            return options.contains(.optional) ? "\(call_result)?" : call_result
        }
        return type.__swiftType__ ?? (other_type ?? "TypeNotMatched")
    }
    
    var swiftType: String {
        let optional = options.contains(.optional)
        let list_tuple = options.contains(.list) || options.contains(.tuple)
        
        var typeString: String {
            if type == .other { return "\(other_type ?? "#WRONG_TYPE#")" }
            if type == .None { return "Void"}
            return type.swiftType
        }
        var typeExport: String {
            
            //for option in options {
                switch type {
                case .list, .tuple, .sequence:
                    return "[\(typeString)]\(if: optional, "?")"
                default: break
                }
            //}
            return typeString
        }
        return typeExport
//        if options.contains(.optional) {
//
//
//
//            if type == .other { return "\(other_type ?? "#WRONG_TYPE#")?" }
//
//            return "\(type.swiftType)?"
//
//        }
//        if type == .other { return "\(other_type ?? "#WRONG_TYPE#")" }
//        return type.swiftType
    }
}

func buildWrapArgReturn(_ v: PyAstObject?) -> WrapArgProtocol {
    var type: PythonType = .None
    var options: [WrapArgOptions] = []
    
    switch v {
    case let sub as PyAst_Subscript:
        if let t = PythonType(rawValue: sub.slice.name) {
            type = t
            if let _type = PythonType(rawValue: sub.name) {
                switch _type {
                case .tuple:
                    options.append(.tuple)
                case .list:
                    options.append(.list)
                case .sequence:
                    options.append(.sequence)
                case .memoryview:
                    options.append(.memoryview)
                default:
                    break
                }
            }
        }
    case let _name as PyAst_Name:
        if let _type = PythonType(rawValue: _name.name) {
            type = _type
        }
    default: fatalError()
    }
    return wrapArgFromType(name: "", type: type, _other_type: "", idx: 0, options: options)
}

func wrapArgFromType(name: String, type: PythonType, _other_type: String, idx: Int, options: [WrapArgOptions]) -> WrapArgProtocol {
    switch type {
        
    case .int, .int32, .int16, .int8, .uint, .uint32, .uint16, .uint8, .long, .ulong, .short, .ushort:
        return intArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: options)
    case .float, .float32, .double:
        return floatArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: options)
    case .str:
        return strArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: options)
    case .data:
        return dataArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: options)
    case .jsondata:
        return jsonDataArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: options)
    case .bool:
        return boolArg(_name: name, _type: .bool, _other_type: "", _idx: idx, _options: options)
    case .url, .error:
        //return strArg(_name: name, _type: .other, _other_type: _other_type, _idx: idx, _options: options)
        return objectArg(_name: name, _type: .other, _other_type: type.rawValue, _idx: idx, _options: options)
    case .other:
        return otherArg(_name: name, _type: .other, _other_type: _other_type, _idx: idx, _options: options)
        //fatalError()
//    case .callable:
//        return callableArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: options)
//    case .other:
//        guard let mod = wrap_module_shared else { fatalError("WrapModule shared was nil")}
//        mod.objectEnums(has: arg.other_type) { e in
//            switch e.type {
//            case .str:
//                break
//            case .int:
//                out.append(intEnumArg(arg))
//                return intArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: [])
//            case .object:
//                switch e.subtype {
//                case .str:
//                    out.append(objectStrEnumArg(arg))
//                    return intArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: [])
//                default: break
//                }
//            }
//        }
    default:
        return intArg(_name: name, _type: type, _other_type: "", _idx: idx, _options: [])
    }
}

private func handleOptional(_ v: PyAstObject, type: inout PythonType, other_type: inout String, options: inout [WrapArgOptions]) {
    options.append(.optional)
    //print("optional: ",v.name)
    let opt_type = v.type
    switch opt_type {
    case .Subscript:
        
        let sub = v as! PyAst_Subscript
        //print("optional Subscript-> name:\(v.name) slice: \(sub.slice.name) ")
        handleSubscript(v: sub, type: &type, other_type: &other_type, options: &options)
        //handleSubscript(v.slice as! PyAst_Subscript, type: &type, other_type: &other_type, options: &options)
    case .Name:
        type = .init(rawValue: v.name) ?? .object
    default:
        print(opt_type)
        fatalError()
    }
}

private func handleSubscript(v: PyAst_Subscript, type: inout PythonType, other_type: inout String, options: inout [WrapArgOptions]) {
    //print("handleSubscript-> name:\(v.name) slice: \(v.slice.name) ")
    
    if let sub_type: PythonType = .init(rawValue: v.name) {
        switch sub_type {
        case .tuple:
            options.append(.tuple)
        case .list:
            options.append(.list)
        case .sequence:
            options.append(.sequence)
        case .memoryview:
            options.append(.memoryview)
        default: break
        }
    }
//    else {
//        type = .other
//        other_type = v.name
//    }
    //fatalError()
    
    if let _type: PythonType = .init(rawValue: v.slice.name) {

        type = _type
        //fatalError(_type.rawValue)
    } else {
        type = .other
        other_type = v.slice.name
        //fatalError(v.slice.name)
    }
    
//
//    switch slice {
//    case let sub as PyAst_Subscript:
//        if let _type: PythonType = .init(rawValue: sub.slice.name) {
//
//
//            fatalError(_type.rawValue)
//        } else {
//            type = .other
//            other_type = sub.slice.name
//            //fatalError(sub.slice.name)
//        }
//    default:
//        print(slice)
//        fatalError()
//    }
    
    //print("other_type", other_type)
    //print(options)
    //fatalError()
}

fileprivate extension PyAst_Subscript {
    
    
    func __buildWrapArg(idx: Int, _ v: PyAst_Arg) -> WrapArgProtocol? {
        if v.name == "self" { return nil }
        return buildWrapArg(idx: idx, v)
    }
    
    func newWrapArg(idx: Int, name: String) -> WrapArgProtocol {
        var options: [WrapArgOptions] = []
        var type: PythonType = .object
        var other_type = ""
        if let _type = PythonType(rawValue: value.name) {
            switch _type {
            case .optional:
                handleOptional(slice, type: &type, other_type: &other_type, options: &options)
            case .tuple:
                options.append(.tuple)
            case .list:
                options.append(.list)
                let collection_arg = collectionArg(
                    name: name,
                    type: .list,
                    other_type: nil,
                    idx: idx,
                    options: options,
                    element: _buildWrapArg(idx: 0, slice)
                )
                return collection_arg
                //return collectionArg(name: <#T##String#>, type: .list, other_type: <#T##String?#>, idx: <#T##Int#>, options: <#T##[WrapArgOptions]#>, element: <#T##WrapArgProtocol#>)
                
            case .sequence:
                options.append(.sequence)
            case .memoryview:
                options.append(.memoryview)
 
            case .callable:
                //options.append(.callable)
                type = .callable
                switch slice.type {
                case .List:
                    let list = slice as! PyAst_List
                    let args = list.elts.enumerated().compactMap(_buildWrapArg)
                    return callableArg(_name: name,  _idx: idx, _options: options, args: args)
                default:
                    return callableArg(_name: name,  _idx: idx, _options: options, args: [])
                }
                
            default:
                type = _type
                other_type = value.name
                fatalError("other: \(self)")
            }
        }
        return wrapArgFromType(name: name, type: type, _other_type: other_type, idx: idx, options: options)
    }
}


func _buildWrapArg(idx: Int, _ v: PyAst_Subscript, name: String) -> WrapArgProtocol {
    var options: [WrapArgOptions] = []
    var type: PythonType = .object
    var other_type = ""
    if let _type = PythonType(rawValue: v.value.name) {
        switch _type {
        case .optional:
            
            handleOptional(v.slice, type: &type, other_type: &other_type, options: &options)
            
        
        case .tuple:
            options.append(.tuple)
            
        case .list:
            //return collectionArg(name: <#T##String#>, type: .list, other_type: <#T##String?#>, idx: <#T##Int#>, options: <#T##[WrapArgOptions]#>, element: <#T##WrapArgProtocol#>)
            options.append(.list)
        case .sequence:
            options.append(.sequence)
        case .memoryview:
            options.append(.memoryview)
        
            
        case .callable:
            //options.append(.callable)
            type = .callable
            switch v.slice.type {
            case .List:
                let list = v.slice as! PyAst_List
                let args = list.elts.enumerated().compactMap(_buildWrapArg)
                return callableArg(_name: name,  _idx: idx, _options: options, args: args)
            default:
                return callableArg(_name: name,  _idx: idx, _options: options, args: [])
            }
            
        default:
            type = _type
            other_type = v.value.name
            fatalError("other: \(v)")
        }
    }
//    if let t = PythonType(rawValue: v.slice.name) {
//        if t != .optional {
//            type = t
//        }
//    }
    //print("_buildWrapArg", name, type, other_type, options)
    return wrapArgFromType(name: name, type: type, _other_type: other_type, idx: idx, options: options)
}


func _buildWrapArg(idx: Int, _ v: PyAst_Arg) -> WrapArgProtocol? {
    if v.name == "self" { return nil }
    return buildWrapArg(idx: idx, v)
}

func _buildWrapArg(idx: Int, _ v: PyAstObject) -> WrapArgProtocol {
    
    
    switch v {
    case let arg as PyAst_Arg:
        return buildWrapArg(idx: idx, arg)
    case let sub as PyAst_Subscript:
        //return sub.newWrapArg(idx: idx, name: sub.name)
        return _buildWrapArg(idx: idx, sub, name: sub.name)
    case let n as PyAst_Name:
        return wrapArgFromType(name: n.name, type: .init(rawValue: v.name) ?? .other, _other_type: v.name, idx: idx, options: [])
    default:
        //print(v)
        fatalError(String(describing: v))
    }
}

func buildWrapArg(idx: Int, _ v: PyAst_Arg) -> WrapArgProtocol {

    var type: PythonType = .None
    var options: [WrapArgOptions] = []
    
    if let anno = v.annotation {
        switch anno {
        case let sub as PyAst_Subscript:
            return _buildWrapArg(idx: idx, sub, name: v.name)
            
        case let _name as PyAst_Name:
            if let _type = PythonType(rawValue: _name.name) {
                type = _type
            } else {
                return wrapArgFromType(name: v.name, type: .other, _other_type: anno.name, idx: idx, options: options)
            }
        default: fatalError()
        }

        
    }

    //print("\t\t\tbuildWrapArg -> \(v.name): \(type)")
    return wrapArgFromType(name: v.name, type: type, _other_type: "", idx: idx, options: options)
}


func handleWrapArgType(_name: String, _type: PythonType, _other_type: String, _idx: Int, _options: [WrapArgOptions] ) -> WrapArgProtocol {
  
        switch _type {
            
        case .int, .int32, .int16, .int8, .uint, .uint32, .uint16, .uint8, .long, .ulong, .short, .ushort:
            return intArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
        case .float, .float32, .double:
            return floatArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
        case .str:
            return strArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
        case .data:
            return dataArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
        case .jsondata:
            return jsonDataArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
        case .bool:
            return boolArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
        case .other:
            guard let mod = wrap_module_shared else { fatalError("WrapModule shared was nil")}
            if let enumarg =  mod.objectEnums(has: _other_type, out: { e -> WrapArgProtocol in
                switch e.type {
                case .str:
                    return objectStrEnumArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
                case .int:
                    //out.append(intEnumArg(arg))
                    return intEnumArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
                case .object:
                    switch e.subtype {
                    case .str:
                        //out.append(objectStrEnumArg(arg))
                        return objectStrEnumArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
                    default:
                        return objectArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
                    }
                }
                
            }) {
                return enumarg
            }
            
        default:
            fatalError()
            break
            //out.append(objectArg(arg))
        }
        
    return objectArg(_name: _name, _type: _type, _other_type: _other_type, _idx: _idx, _options: _options)
    
}


//func handleWrapArgTypes(args: [WrapArg]) -> [WrapArgProtocol]{
//    var out = [WrapArgProtocol]()
//
//    for arg in args {
//         switch arg.type {
//
//        case .int, .int32, .int16, .int8, .uint, .uint32, .uint16, .uint8, .long, .ulong, .short, .ushort:
//            out.append(intArg(arg))
//        case .float, .float32, .double:
//            out.append(floatArg(arg))
//        case .str:
//             out.append(strArg(arg)!)
//        case .data:
//            out.append(dataArg(arg))
//         case .jsondata:
//             out.append(jsonDataArg(arg))
//        case .bool:
//            out.append(boolArg(arg))
//        case .other:
//             //print(arg.name, arg.type, arg.other_type)
//             out.append(objectArg(arg))
//             //fatalError()
////            guard let mod = wrap_module_shared else { fatalError("WrapModule shared was nil")}
////            mod.objectEnums(has: arg.other_type) { e  -> Void in
////                switch e.type {
////                case .str:
////                    break
////                case .int:
////                    out.append(intEnumArg(arg))
////                case .object:
////                    switch e.subtype {
////                    case .str:
////                        out.append(objectStrEnumArg(arg))
////                    default: break
////                    }
////                }
////            }
//        default:
//
//            out.append(objectArg(arg))
//        }
//
//    }
//
//    return out
//}



enum ExtractKeys: CodingKey {
    case type
}

func handleWrapArgTypes(decoder: Decoder) throws -> [WrapArgProtocol]{
    var out = [WrapArgProtocol]()
    var c = try decoder.container(keyedBy: ExtractKeys.self)

//    for arg in args {
//         switch arg.type {
//
//        case .int, .int32, .int16, .int8, .uint, .uint32, .uint16, .uint8, .long, .ulong, .short, .ushort:
//            out.append(intArg(arg))
//        case .float, .float32, .double:
//            out.append(floatArg(arg))
//        case .str:
//            out.append(strArg(arg))
//        case .data:
//            out.append(dataArg(arg))
//         case .jsondata:
//             out.append(jsonDataArg(arg))
//        case .bool:
//            out.append(boolArg(arg))
//        case .other:
//            guard let mod = wrap_module_shared else { fatalError("WrapModule shared was nil")}
//            mod.objectEnums(has: arg.other_type) { e in
//                switch e.type {
//                case .str:
//                    break
//                case .int:
//                    out.append(intEnumArg(arg))
//                case .object:
//                    switch e.subtype {
//                    case .str:
//                        out.append(objectStrEnumArg(arg))
//                    default: break
//                    }
//                }
//            }
//        default:
//
//            out.append(objectArg(arg))
//        }
//
//    }
//
    return out
}

class WrapArgsContainer: Decodable {
    
    
    let arg: WrapArgProtocol
    
    private enum CodingKeys: CodingKey {
        case type
        case other_type
    }
    
    

    required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: CodingKeys.self)
//        let asdf = try c.nestedContainer(keyedBy: CodingKeys.self, forKey: .type)
        let t = try c.decode(String.self, forKey: .type)

        var type: PythonType
        do {
            type = try c.decode(PythonType.self, forKey: .type)
        } catch {
            type = .other
        }

        switch type {
        case .int, .int32, .int16, .int8, .uint, .uint32, .uint16, .uint8, .long, .ulong, .short, .ushort:
            arg = try intArg(from: decoder)
        case .float, .float32, .double:
            arg = try floatArg(from: decoder)
        case .str:
            arg = try strArg(from: decoder)
        case .data:
            arg = try dataArg(from: decoder)
        case .jsondata:
            arg = try jsonDataArg(from: decoder)
        case .bool:
            arg = try boolArg(from: decoder)
        case .other:
            let mod = wrap_module_shared!

            var other_type: String
            if c.contains(.other_type) {
                other_type = try c.decode(String.self, forKey: .other_type)
            } else {
                other_type = try c.decode(String.self, forKey: .type)
            }
            

            if let objectenum = mod.objectEnums(has: other_type) {
                switch objectenum.type {
                case .str:
                    arg = try intEnumArg(from: decoder)
                case .int:
                    arg = try intEnumArg(from: decoder)
                case .object:
                    switch objectenum.subtype {
                    case .str:
                        arg = try objectStrEnumArg(from: decoder)
                    default: arg = try objectStrEnumArg(from: decoder)
                    }
                }
            } else {
                arg = try objectArg(from: decoder)
            }
        default:
            arg = try objectArg(from: decoder)
        }
        
    }// init
    
}

public class _WrapArg: Decodable {

    
    public init(_name: String, _type: PythonType, _other_type: String?, _idx: Int, _options: [WrapArgOptions]) {
        self._name = _name
        self._type = _type
        self._other_type = _other_type
        self._idx = _idx
        self._options = _options
        
        self._sequence = _options.contains(where: { option in
            switch option {
            case .list, .tuple, .memoryview, .array, .sequence: return true
            default: break
            }
            return false
        })
        self._tuple = _options.contains(.tuple)
        self._list = _options.contains(.list)
        self._options = _options
        
        
//        self._sequence = _sequence
//        self._tuple = _tuple
//        self._list = _list
    }
    
    
    var _name: String
    public var optional_name: String? = nil
    var _type: PythonType
    var _other_type: String?
    var _idx: Int
    var _options: [WrapArgOptions]
    var _sequence: Bool
    var _tuple: Bool
    var _list: Bool
    
    private enum CodingKeys: CodingKey {
        case name
        case type
        case other_type
        case idx
        case options
    }
    required public init(from decoder: Decoder) throws {
 
        let c = try decoder.container(keyedBy: CodingKeys.self)
        _name = try c.decode(String.self, forKey: .name)
        _idx = try c.decode(Int.self, forKey: .idx)

        do {
            _type = try c.decode(PythonType.self, forKey: .type)
        } catch {
     
            _type = .other
        }
        if c.contains(.other_type) {
            _other_type = try c.decode(String.self, forKey: .other_type)
        } else {
            _other_type = try c.decode(String.self, forKey: .type)
        }

        if c.contains(.options) {
            let options = try c.decode([WrapArgOptions].self, forKey: .options)
            _sequence = options.contains(where: { option in
                switch option {
                case .list, .tuple, .memoryview, .array, .sequence: return true
                default: break
                }
                return false
            })
            _tuple = options.contains(.tuple)
            _list = options.contains(.list)
            _options = options
        } else {
            _options = []
            _sequence = false
            _list = false
            _tuple = false
        }
    }
    
    init() {
        _name = ""
        _type = .void
        _other_type = ""
        _idx = 0
        _options = [.return_]
        _sequence = false
        _list = false
        _tuple = false
    }
    
    init(_ arg: WrapArg) {
        _name = arg.name
        _type = arg.type
        _other_type = arg.other_type
        _idx = arg.idx
        let options = arg.options
        _options = options
        _sequence = options.contains(where: { option in
            switch option {
            case .list, .tuple, .memoryview, .array, .sequence: return true
            default: break
            }
            return false
        })
        _tuple = options.contains(.tuple)
        _list = options.contains(.list)
    }
    
    
}

//
extension _WrapArg {
//    func handleType(T: String) -> String {
//        //rprint("handleType", T)
//        
//        if self._sequence { return "[\(T)]\(if: self._options.contains(.optional), "?")"}
//        return "\(T)\(if: self._options.contains(.optional), "?")"
//    }
//    func handleSendCallType(T: String) -> String {
//        if self._sequence { return "\(_name).array()"}
//        if self._type == .str { return "\(_name).string!" }
//        if self._type == .jsondata { return "\(_name).jsonData!"}
//        if self._type == .data { return "\(_name).bytesAsData()!"}
//        return elementConverterPythonType(element: T, T: _type, AsFrom: .FromPythonType)
//    }
//    
    func handleSendCallType2(T: String) -> String {
        if self._sequence { return "\(T).array()"}
        if self._type == .str { return "\(T).string!" }
        if self._type == .jsondata { return "\(T).jsonData!"}
        if self._type == .data { return "\(T).bytesAsData()!"}
        if self._type == .bool { return "\(T).bool"}
        return elementConverterPythonType(element: T, T: _type, AsFrom: .FromPythonType)
    }
//    
//    func handleCallbackCallType(T: String) -> String {
//        if _tuple { return "\(_name).pythonTuple" }
//        if _list { return "\(_name).pythonList" }
//        if self._sequence { return "\(_name).array()"}
//        if _type == .str {
//            if _options.contains(.optional) {
//                return "(\(_name) != nil ? \(_name)?.withCString(PyUnicode_FromString) : .PyNone)"
//            }
//            return "\(_name).withCString(PyUnicode_FromString)"
//        }
//        
//        return elementConverterPythonType(element: T, T: _type, AsFrom: .AsPythonType)
//    }
//    
//    func handleCallbackCallType2(T: String) -> String {
//        if _tuple { return "\(T).pythonTuple" }
//        if _list { return "\(T).pythonList" }
//        if self._sequence { return "\(T).array()"}
//        if self._type == .bool { return "asPyBool(\(T))"}
//        if self._type == .str { return "\(T).pyPointer"}
//        
//        return elementConverterPythonType(element: T, T: _type, AsFrom: .AsPythonType)
//    }
}
