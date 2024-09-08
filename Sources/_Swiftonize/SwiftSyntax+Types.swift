//
//  File.swift
//  
//
//  Created by MusicMaker on 01/05/2023.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import PySwiftCore
//import PythonTypeAlias
import WrapContainers

protocol SyntaxTypeConvertable {
    var syntaxType: TypeSyntax {get}
}

extension SyntaxTypeConvertable {
    
    var string: String {
        "\(Self.self)"
    }
    
    var syntaxType: TypeSyntax {
        .init(stringLiteral: string)
    }
}

extension Equatable {
    static var string: String {
        "\(Self.self)"
    }
    
    static var syntaxType: TypeSyntax {
        .init(stringLiteral: string)
    }
}

extension Hashable {
    static var string: String {
        "\(Self.self)"
    }
    
    static var syntaxType: TypeSyntax {
        .init(stringLiteral: string)
    }
}

extension Data {
    static var string: String {
        "\(Self.self)"
    }
    
    static var syntaxType: TypeSyntax {
        .init(stringLiteral: string)
    }
}


public extension WrapContainers.PythonType {
    
    var annotation: TypeAnnotationSyntax {
        
        return .init(type: syntaxType)
    }
    
    var syntaxType: TypeSyntax {
        var T: Any = Void.self
        
        switch self {
        case .int:
            T = Int.self
        case .long:
            T = Int.self
        case .ulong:
            T = UInt.self
        case .uint:
            T = UInt.self
        case .int32:
            T = Int32.self
        case .uint32:
            T = UInt32.self
        case .int8:
            T = Int8.self
        case .char:
            T = Int8.self
        case .uint8:
            T = UInt8.self
        case .uchar:
            T = UInt8.self
        case .ushort:
            T = UInt16.self
        case .short:
            T = Int16.self
        case .int16:
            T = Int16.self
        case .uint16:
            T = UInt16.self
        case .longlong:
            T = Int64.self
        case .ulonglong:
            T = UInt64.self
        case .float:
            T = Double.self
        case .double:
            T = Double.self
        case .float32:
            T = Float.self
        case .str:
            T = String.self
        case .bytes:
            T = String.self
        case .data:
            T = Data.self
        case .json:
            T = String.self
        case .jsondata:
            T = Data.self
        case .list:
            break
        case .sequence:
            break
        case .Array, .array:
            break
        case .memoryview:
            T = "PyPointer"
        case .tuple:
            break
        case .byte_tuple:
            break
            //case .object:
            //    T = PythonObject.self
        case .object:
            T = "PyPointer"
        case .bool:
            T = Bool.self
        case .void:
            T = Void.self
        case .None:
            T = Void.self
        case .CythonClass:
            T = PythonPointer.self
        case .callable:
            T = "PyPointer"
        case .url:
            T = URL.self
        case .error:
            T = Error.self
        case .optional: break
        case .other:
            break
        }
        
        return .init(stringLiteral: String(describing: T))
    }
    
}


extension WrapClassBase {
    public var inheritedType: InheritedTypeSyntax {
            //InheritedTypeSyntax(typeName: SimpleTypeIdentifier(stringLiteral: rawValue))
		.init(type: TypeSyntax(stringLiteral: rawValue))
        }
}
//extension Int: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Int8: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Int16: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Int32: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Int64: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension UInt: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension UInt8: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension UInt16: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension UInt32: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension UInt64: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//
//extension Float: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Float80: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Double: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension String: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Date: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Data: SyntaxTypeConvertable {
//    var syntaxType: TypeSyntax {
//        .init(stringLiteral: string)
//    }
//}
//extension Float: SyntaxTypeConvertable {}

