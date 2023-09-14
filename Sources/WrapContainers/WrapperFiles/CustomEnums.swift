//
//  CustomEnums.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 17/02/2022.
//

import Foundation



enum CustomEnumType: String, Codable {
    case str
    case int
    case object
}

enum QuantumValue: Codable {
    
    case int(Int), string(String)
    
    init(from decoder: Decoder) throws {
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
            return
        }
        
        if let string = try? decoder.singleValueContainer().decode(String.self) {
            self = .string(string)
            return
        }
        
        throw QuantumError.missingValue
    }
    
    enum QuantumError:Error {
        case missingValue
    }
}

class EnumValue: Codable {
    let key: String
    let value: QuantumValue
    var valueAsString: String {
        switch value {
        case .string(let string): return string
        case .int(let int): return String(int)
        }
    }
    var valueAsAny: Any {
        switch value {
        case .string(let string): return string
        case .int(let int): return int
        }
    }
    
}

public class CustomEnum: Codable {
    
    let title: String
    let type: CustomEnumType
    let subtype: CustomEnumType!
    let keys: [EnumValue]
    
    private enum CodingKeys: CodingKey {
        case title
        case keys
        case type
        case subtype
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        keys = try container.decode([EnumValue].self, forKey: .keys)
        type = try container.decode(CustomEnumType.self, forKey: .type)
        if container.contains(.subtype) {
            subtype = try container.decode(CustomEnumType.self, forKey: .subtype)
        } else { subtype = nil }
        
    }
}
