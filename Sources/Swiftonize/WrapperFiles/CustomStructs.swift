
import Foundation

enum CustomStructType: String, Codable {
    case Codable
}


//class CustomStruct: Codable {
//
//    let title: String
//    let sub_classes: [CustomStructType]
//    var assigns: [WrapArg]
//
//    private enum CodingKeys: CodingKey {
//        case title
//        case assigns
//        case sub_classes
//    }
//
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        title = try container.decode(String.self, forKey: .title)
//        assigns = try container.decode([WrapArg].self, forKey: .assigns)
//        sub_classes = try container.decode([CustomStructType].self, forKey: .sub_classes)
//
//
//    }
//}

//
//
//extension CustomStruct {
//    
//    
//    func call_arg(arg_name: String, options: [StructTypeOptions]) -> String {
//        if options.contains(.python) {
//            
//            if sub_classes.contains(.Codable) {
//                return "json.dumps(\(arg_name).__dict__).encode()"
//            }
//            
//            
//            
//        }
//        return ""
//    }
//    
//    func export(options: [StructTypeOptions]) -> String {
//        let subclasses = sub_classes.map{$0.rawValue}
//        if options.contains(.swift) {
//            let args = assigns.map { arg -> String in
//                "var \(arg.name): \(arg.swift_type)"
//            }
//            let init_args = assigns.map { arg -> String in
//                "\(arg.name) = try container.decode(\(arg.pyType2Swift).self, forKey: .\(arg.name))"
//            }.joined(separator: newLineTabTab)
//            return """
//            struct \(title)\(if: subclasses.count != 0, ": \(subclasses.joined(separator: ", "))", "") {
//                \(args.joined(separator: newLineTab))
//                
//                private enum CodingKeys: CodingKey {
//                    \(assigns.map{"case \($0.name)"}.joined(separator: newLineTabTab))
//                }
//
//                init(from decoder: Decoder) throws {
//                    let container = try decoder.container(keyedBy: CodingKeys.self)
//                    \(init_args)
//                }
//            }
//            """
//        }
//        if options.contains(.python) {
//            let args = assigns.map { arg -> String in
//                "\(arg.name): \(arg.type.rawValue)"
//            }
//            
//            return """
//            cdef class \(title):
//                cdef dict __dict__
//                \(args.joined(separator: newLineTab))
//            """
//        }
//      
//        return """
//        
//        """
//    }
//}
