//
//  WrapArg.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 06/12/2021.
//


let PythonTypes_String = PythonType.allCases.map({$0.rawValue})

import Foundation


enum WrapArgOptions: String, CaseIterable, Codable {
    case list
    case json
    case data
    case tuple
    case enum_
    case return_
    case memoryview
    case array
    case codable
    case dispatch
    case sequence
    case py_object
    case object_str_enum
    case callable
    case optional
}

private func WrapArgHasOption(arg: WrapArg,option: WrapArgOptions) -> Bool {
    return arg.options.contains(option)
}

class WrapArg: Codable, Equatable {
    var name: String
    var type: PythonType
    var other_type: String
    var idx: Int
    
    let asObject: Bool
    
    //var is_return: Bool
    //var is_list: Bool
    //var is_json: Bool
    //var is_data: Bool
    //var is_tuple: Bool
    //var is_enum: Bool
    
    var objc_name: String
    var objc_type: String
    
    var pyx_name: String
    var pyx_type: String
    var swift_type: String
    
    var size: Int
    
    var options: [WrapArgOptions]
    var asObjectEnum: CustomEnum!
    var tuple_types: [WrapArg]!
    var cls: WrapClass!
    
    private enum CodingKeys: CodingKey {
        case name
        case type
        case other_type
        case idx
        case options
        }
    
    init(name: String, type: PythonType, other_type: String, idx: Int, arg_options: [WrapArgOptions]) {
        self.name = name
        self.type = type
        self.other_type = other_type
        self.idx = idx
        //self.is_return = is_return
        //self.is_list = is_list
        //self.is_json = is_json
        //self.is_data = is_data
        //self.is_tuple = is_tuple
        //self.is_enum = is_enum
        self.options = arg_options
        asObject = options.contains(.py_object)
        pyx_name = name
        objc_name = "arg\(idx)"
        
//        var pyx_type_options: [PythonTypeConvertOptions] = []
//        var objc_type_options: [PythonTypeConvertOptions] = [.objc]
//        if options.contains(.list) {
//            pyx_type_options.append(.is_list)
//            objc_type_options.append(.is_list)
//        }
        if type == .other {
            size = 8
            pyx_type = other_type
            objc_type = other_type
            swift_type = other_type
        } else {
            size = TYPE_SIZES[type.rawValue]!
            pyx_type = ""
            objc_type = ""
            swift_type = SWIFT_TYPES[type.rawValue] ?? ""
            pyx_type = convertPythonType(options: [])
            objc_type = convertPythonType(options: [.objc])
        }
        
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try! container.decode(String.self, forKey: .name).replacingOccurrences(of: "*", with: "")
        idx = try! container.decode(Int.self, forKey: .idx)
        do {
            type = try container.decode(PythonType.self, forKey: .type)
        } catch {
            type = .other
        }
        if container.contains(.other_type) {
            other_type = try container.decode(String.self, forKey: .other_type)
        } else {
            other_type = try container.decode(String.self, forKey: .type)
        }

        if container.contains(.options) {
            options = try container.decode([WrapArgOptions].self, forKey: .options)
        } else {
            options = []
        }

        asObject = options.contains(.py_object)

        pyx_name = name
        objc_name = "arg\(idx)"
        
//        var pyx_type_options: [PythonTypeConvertOptions] = []
//        var objc_type_options: [PythonTypeConvertOptions] = [.objc]
//        if self.options.contains(.list) {
//            pyx_type_options.append(.is_list)
//            objc_type_options.append(.is_list)
//        }
        if type == .other {
            size = 8
            pyx_type = other_type
            objc_type = other_type
            swift_type = other_type
        } else {
            size = TYPE_SIZES[type.rawValue]!
            pyx_type = ""
            objc_type = ""
            if let swift_t = SWIFT_TYPES[type.rawValue] {
                swift_type = swift_t
            } else {
                swift_type = ""
            }
            pyx_type = convertPythonType(options: [])
            objc_type = convertPythonType(options: [.objc])
        }
        
                
    }
    
    static func ==(lhs: WrapArg , rhs: WrapArg) -> Bool {
            return lhs.type == lhs.type
        }

    func has_option(_ option: WrapArgOptions) -> Bool {
        return options.contains(option)
    }
    
    func postProcess(mod: WrapModule, cls: WrapClass) {
        if mod.custom_structs.first(where: { (custom) -> Bool in custom.title == other_type }) != nil {
            options.append(.codable)
        }
        
        if type == .other {
            if let e = mod.custom_enums.first(where: { e -> Bool in e.title == other_type }) {
                asObjectEnum = e
            } else { asObjectEnum = nil }
        }
    }
    
    func export(options: [PythonTypeConvertOptions]) -> String! {
        //var options = options
        var _name: String
        let is_list = has_option(.list)
        let is_sequence = has_option(.sequence)
        let codable = has_option(.codable)
        let enum_ = has_option(.enum_)
        let dispatch_object = has_option(.dispatch)
        if options.contains(.use_names) {
            _name = name
        } else {
            _name = objc_name
        }
        
        let enum_names = wrap_module_shared.enumNames
        
        if options.contains(.objc) {
            //if is_list {options.append(.is_list)}
//            if options.contains(.header) {
//                var header_string = ""
//                switch idx {
//                case 0:
//                    if type == .other {
//
//                    } else {
//                        header_string.append(":(\(convertPythonType(options: options) ))\(name)")
//                    }
//
//                default:
//                    //header_string.append("\(name):(\(convertPythonType(type: type, options: options) ))\(name)")
//                    header_string.append(":(\(convertPythonType(options: options) ))\(name)")
//                }
//                //let func_string = "\(convertPythonType(type: type, is_list: is_list, objc: objc, header: header)) \(objc_name!)"
//                return header_string
//            } else {
                if codable {return "PythonData \(_name)"}
                if enum_names.contains(other_type) {return "long \(name)"}
                if type == .other {return "\(other_type) \(_name)"}
                let func_string = "\(convertPythonType(options: options)) \(_name)"
                return func_string
//            }
        }
        
        if options.contains(.swift) {
            //if is_list {options.append(.is_list)}
            if options.contains(.callback) {
                if dispatch_object {return "\(_name): \(other_type)"}
                return "\(_name): \(PythonObjectAsSwiftType(arg: self, option: .callback))"
            }
            if options.contains(.protocols) {
                if dispatch_object {return "\(_name): \(other_type)"}
                
                if enum_names.contains(other_type) {return "\(name): \(other_type)"}
                return "\(_name): \(PythonObjectAsSwiftType(arg: self, option: .protocols))"
            }
            
            if codable {return "_ \(_name): PythonData"}
            if enum_names.contains(other_type) {return "_ \(name): Int"}
            //
            return "_ \(_name): \(PythonObjectAsSwiftType(arg: self, option: .pre))"
        }
        
        
        if options.contains(.py_mode) {
            
            if codable {
                return "PythonData \(name)"
                
            }
            if is_list {
                var list_type = ""
                
                if codable {
                    return "PythonData"
                } else {
                    list_type = PurePythonTypeConverter(type: type)
                }
                return "\(name): List[\(list_type)]"
                
            }
            if is_sequence { return "\(name): Sequence[\(PurePythonTypeConverter(type: type))]" }
            
            if type == .other {
                
                return "\(name): \(other_type)"
            }
            if asObject {
                if type == .float {
                    return "\(name): object"
                }
            }
            return "\(name): \(PurePythonTypeConverter(type: type))"
        }
        let arg_options = options
//        if is_list {
//            arg_options.append(.is_list)
//        }
        if codable { return "PythonData \(_name)" }
        if enum_names.contains(other_type) {return "long \(name)"}
        if type == .other {return "\(other_type) \(_name)"}
        let func_string = "\(convertPythonType(options: arg_options)) \(_name)"
        //let func_string = "\(convertPythonType(type: PurePythonTypeConverter(type: type), options: options)) \(_name)"
        return func_string
    }
}


