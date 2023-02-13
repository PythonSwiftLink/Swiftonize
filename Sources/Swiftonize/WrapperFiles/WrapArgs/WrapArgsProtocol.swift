//
//  WrapargsProtocol.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 14/03/2022.
//

import Foundation
import PythonSwiftCore
import PyAstParser

protocol WrapArgProtocol: Decodable {
    
    var name: String { get }
    var optional_name: String? { get set }
    var type: PythonType { get }
    var other_type: String { get }
    var idx: Int { get }
    var options: [WrapArgOptions] { get }
    
    var python_function_arg: String { get }
    var python_call_arg: String { get }
    
    var cython_header_arg: String { get }
    
    var c_header_arg: String { get }
    
    var swift_protocol_arg: String { get }
    var swift_send_func_arg: String { get }
    var swift_send_call_arg: String { get }
    
    var swift_callback_func_arg: String { get }
    var swift_callback_call_arg: String { get }
    
    var decref_needed: Bool { get }
    var conversion_needed: Bool { get }
    
    func convert_return(arg: String) -> String
    
    func convert_return_send(arg: String) -> String
    
    var swift_callback_return_type: String { get }
    
    var swift_send_return_type: String { get }
    
    func swift_property_getter(arg: String) -> String
    
    func swift_property_setter(arg: String) -> String
    
}

extension WrapArgProtocol {
    
    var swiftType: String {
        if options.contains(.optional) {
            
            return "\(type.swiftType)?"
        }
        return type.swiftType
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
        return strArg(_name: name, _type: type, _other_type: "URL_", _idx: idx, _options: options)
    case .other:
        return objectArg(_name: name, _type: .other, _other_type: _other_type, _idx: idx, _options: options)
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

func _buildWrapArg(idx: Int, _ v: PyAst_Subscript, name: String) -> WrapArgProtocol {
    var options: [WrapArgOptions] = []
    var type: PythonType = .object
    var other_type = ""
    if let _type = PythonType(rawValue: v.value.name) {
        switch _type {
        case .optional:
            
            options.append(.optional)
            type = .init(rawValue: v.slice.name)!
            
        case .tuple:
            options.append(.tuple)
        case .list:
            
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
    if let t = PythonType(rawValue: v.slice.name) {
        if t != .optional {
            type = t
        }
    }
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


func handleWrapArgTypes(args: [WrapArg]) -> [WrapArgProtocol]{
    var out = [WrapArgProtocol]()
    
    for arg in args {
         switch arg.type {
            
        case .int, .int32, .int16, .int8, .uint, .uint32, .uint16, .uint8, .long, .ulong, .short, .ushort:
            out.append(intArg(arg))
        case .float, .float32, .double:
            out.append(floatArg(arg))
        case .str:
            out.append(strArg(arg))
        case .data:
            out.append(dataArg(arg))
         case .jsondata:
             out.append(jsonDataArg(arg))
        case .bool:
            out.append(boolArg(arg))
        case .other:
            guard let mod = wrap_module_shared else { fatalError("WrapModule shared was nil")}
            mod.objectEnums(has: arg.other_type) { e  -> Void in
                switch e.type {
                case .str:
                    break
                case .int:
                    out.append(intEnumArg(arg))
                case .object:
                    switch e.subtype {
                    case .str:
                        out.append(objectStrEnumArg(arg))
                    default: break
                    }
                }
            }
        default:
            
            out.append(objectArg(arg))
        }
        
    }
    
    return out
}



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

class _WrapArg: Decodable {

    
    internal init(_name: String, _type: PythonType, _other_type: String, _idx: Int, _options: [WrapArgOptions]) {
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
    var optional_name: String? = nil
    var _type: PythonType
    var _other_type: String
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
    required init(from decoder: Decoder) throws {
 
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


extension _WrapArg {
    func handleType(T: String) -> String {
        if self._sequence { return "[\(T)]"}
        return T
    }
    func handleSendCallType(T: String) -> String {
        if self._sequence { return "\(_name).array()"}
        if self._type == .str { return "\(_name).string!" }
        if self._type == .jsondata { return "\(_name).jsonData!"}
        if self._type == .data { return "\(_name).bytesAsData()!"}
        return elementConverterPythonType(element: T, T: _type, AsFrom: .FromPythonType)
    }
    
    func handleSendCallType2(T: String) -> String {
        if self._sequence { return "\(T).array()"}
        if self._type == .str { return "\(T).string!" }
        if self._type == .jsondata { return "\(T).jsonData!"}
        if self._type == .data { return "\(T).bytesAsData()!"}
        if self._type == .bool { return "\(T).bool"}
        return elementConverterPythonType(element: T, T: _type, AsFrom: .FromPythonType)
    }
    
    func handleCallbackCallType(T: String) -> String {
        if _tuple { return "\(_name).pythonTuple" }
        if _list { return "\(_name).pythonList" }
        if self._sequence { return "\(_name).array()"}
        
        return elementConverterPythonType(element: T, T: _type, AsFrom: .AsPythonType)
    }
    
    func handleCallbackCallType2(T: String) -> String {
        if _tuple { return "\(T).pythonTuple" }
        if _list { return "\(T).pythonList" }
        if self._sequence { return "\(T).array()"}
        if self._type == .bool { return "asPyBool(\(T))"}
        if self._type == .str { return "\(T).pyPointer"}
        
        return elementConverterPythonType(element: T, T: _type, AsFrom: .AsPythonType)
    }
}
