//
//  File.swift
//  
//
//  Created by MusicMaker on 09/04/2023.
//

import Foundation

extension WrapClassProperty {
    
    fileprivate func setter_extract_line(target: String, callValue: String, cls_title: String) -> String {
        //var setter_extract = ""
        let arg = arg_type
        
        let optional = arg.options.contains(.optional)
        let is_object = arg.type == .object
        let is_protocol = arg.options.contains(._protocol)
        
        
        if is_protocol {
            if let other_type = arg.other_type {
                return """
                guard let v = v, PythonObject_TypeCheck(v, \(other_type)PyType.pytype) else { return 1 }
                let newValue = v.get\(other_type)Pointer()
                """.newLineTabbed.newLineTabbed
            }
        }
        
        if name == "py_callback" {
            return """
            guard let v = v else { return 1 }
            let newValue = \(cls_title)PyCallback(callback: v)
            """.newLineTabbed.newLineTabbed
        }
        
        return "guard let v = v, let newValue = try? \(arg.type.swiftType)(object: v) else { return 1 }"
        return optional ? "guard let v = v, let newValue = try? \(arg.type.swiftType)(object: v) else { return 1 }" :  (is_object ? "v" : "\(arg.type.swiftType)(v)")
        
    }
    
    fileprivate func getter_extract_line(target: String, callValue: String) -> String {
        
        let optional = arg_type.options.contains(.optional)
        var getter_extract = ""
        
        switch arg_type {
        case let extract as PyCallbackExtactable:
//            return """
//            \(extract.cb_extractLine(many: false, for: "v") ?? "//extract line missing: \(arg_type.name) - \(arg_type.__swiftType__)")
//            """
            var prop: String {
                return "UnPackPySwiftObject(with: s, as: \(target).self).\(name)"
            }
            
            if name == "py_callback" { return """
            if let cb = \(prop) { return cb._pycall.xINCREF }
                return .PyNone
            """}
            
            if arg_type.options.contains(._protocol) || name == "delegate" { return "optionalPyPointer( \(prop) as? \(arg_type.other_type ?? extract.argType) )"}
            
            if arg_type is optionalArg {
                return "optionalPyPointer( \(prop) )"
            }
            
            return "\(prop).pyPointer"
        default:
            if arg_type.options.contains(._protocol) {
                if let other_type = arg_type.other_type {
                    getter_extract = """
                guard let v = (\(target) as? \(other_type)) else { return .PyNone }
                """.newLineTabbed
                } else {
                    getter_extract = (optional ? "guard let v = \(target) else { return .PyNone }" : "let v = \(callValue)")
                }
            } else {
                
                getter_extract = (optional ? "guard let v = \(target) else { return .PyNone }" : "let v = \(callValue)")
            }
            
            return getter_extract
            
        }
        
        
        
    }
    
    fileprivate func generate(PropertyLine with: ClassPropertyType, swift_pointer: String, cls_title: String) -> String {
        
        
        var getter: String {
            """
            getter: {s,clossure in
                \(getter_extract_line(target: cls_title, callValue: ""))
            }
            """
        }
        
        var setter: String? {
            var setter_target = "UnPackPySwiftObject(with: s, as: \(cls_title).self)"
            var assign = "// #NotMatched"
            
            switch arg_type {
            case _ where name == "delegate":
                assign = "UnPackOptionalPyPointer(with: \(arg_type.swiftType)PyType.pytype, from: v, as: \(arg_type.swiftType).self)"
            case _ as optionalArg:
                setter_target = """
                UnPackPySwiftObject(with: s, as: \(cls_title).self)
                """
                assign = "optionalPyCast(from: v)"
            
            default:
                
                assign = "try pyCast(from: v)"
                
            }
            var code = """
            \(setter_target).\(name) = \(assign)
            """
            
            if name == "py_callback" {
                assign = "\(cls_title)PyCallback(callback: v)"
                code = """
                guard let v = v else { return 1 }
                \(setter_target).\(name) = \(assign)
                """.newLineTabbed.newLineTabbed
                
            }
            
            
            
            //\(setter_extract_line(target: "target", callValue: "callValue", cls_title: cls_title))
            //\(swift_pointer).\(name) = optionalPyCast(from: v)
            //\(setter_target)
            
            switch with {
            case .GetSet: return {
                """
                setter: { s,v,clossure in
                    do {
                        \(code)
                        return 0
                    }
                    catch let err as PythonError {
                        err.triggerError("\(name)")
                    }
                    catch let other_error {
                        other_error.pyExceptionError()
                    }
                    return 1
                }
                """
            }()
            default: return nil
            
            }
        }
        let getset_string = [getter,setter].compactMap({$0?.newLineTabbed}).joined(separator: ",\n\t")
        return """
        fileprivate let \(cls_title)_\(name) = PyGetSetDefWrap(
            pySwift: "\(name)",
            \(getset_string)
        )
        """.replacingOccurrences(of: newLine, with: newLineTab)
    }
    
//    fileprivate func generate(GetSet swift_pointer: String, cls_title: String) -> String {
//        let arg = arg_type
//        let is_object = arg.type == .object
//        let optional = arg.options.contains(.optional)
//        let prop_name = name == "py_callback" ? "py_callback" : name
//        //        let target = "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"
//        let target = "\(swift_pointer).\(name)"
//        let call = "\(arg.swift_property_getter(arg: cls_title))"
////        var setValue = optional ? "guard let v = v, let newValue = try? \(arg.type.swiftType)(object: v) else { return 1 }" :  (is_object ? "v" : "\(arg.type.swiftType)(v)")
//        var callValue = target//is_object ? "\(call)" : call
//        if name == "py_callback" {
//            callValue = "\(call)?._pycall.ptr"
//        }
//        //var getterLine = getter_extract_line(target: cls_title, callValue: <#T##String#>)
//        // \(arg.options.contains(._protocol) || !(arg.name == "py_callback") ? setValue : "guard let v = v, let newValue = \(setValue) else { return 1 } // fool")
//        return """
//        fileprivate let \(cls_title)_\(name) = PyGetSetDefWrap(
//            pySwift: "\(name)",
//            getter: {s,clossure in
//                \(getter_extract_line(target: cls_title, callValue: ""))
//            },
//            setter: { s,v,clossure in
//                //\(setter_extract_line(target: target, callValue: callValue, cls_title: cls_title))
//                \(swift_pointer).\(prop_name) = optionalPyCast(from: v)
//                return 0
//            }
//        )
//        """.replacingOccurrences(of: newLine, with: newLineTab)
//    }
////
//    fileprivate func generate(Getter swift_pointer: String, cls_title: String) -> String {
//        let arg = arg_type
//        //let is_object = arg.type == .object
//        let optional = arg.options.contains(.optional)
//        //let target = "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"
//        let target = "\(swift_pointer).\(name)"
//        //let call = "\(arg.swift_property_getter(arg: "(s.getSwiftPointer() as \(cls_title)).\(name)"))"
//        let callValue = target//is_object ? "PyPointer(\(call))" : call
//
//        let getter_extract = optional ? "guard let v = \(target) else { return .PyNone }" : "let v = \(callValue)"
//        return """
//        fileprivate let \(cls_title)_\(name) = PyGetSetDefWrap(
//            pySwift: "\(name)",
//            getter: { s,clossure in
//                \(getter_extract)
//                return v.pyPointer
//            }
//        )
//        """.replacingOccurrences(of: newLine, with: newLineTab)
//    }
}

extension WrapClass {
    var PyGetSets: String {
        var _properties = properties.filter { p in
            p.property_type == .GetSet || p.property_type == .Getter
        }
        let cls_callbacks = functions.first(where: {$0.has_option(option: .callback)}) != nil
        if _properties.isEmpty && !cls_callbacks {
            //return "fileprivate let \(cls.title)_PyGetSets = nil"
            return ""
        }
        if cls_callbacks && !new_class {
//            _properties.insert(.init(name: "py_callback", property_type: .GetSet, arg_type: .init(name: "", type: .object, other_type: "", idx: 0, arg_options: [])), at: 0)
            _properties.append(.init(name: "py_callback", property_type: .GetSet, arg_type: objectArg._new_))
        }
        let swift_pointer = getSwiftPointer.replacingOccurrences(of: "?", with: "")
//        let properties = _properties.map { p -> String in
//            switch p.property_type {
//            case .Getter:
//                //return p.generate(Getter: swift_pointer, cls_title: title)
//            case .GetSet:
//                //return generate(GetSet: p, cls_title: title)
//                return p.generate(GetSet: swift_pointer, cls_title: title)
//            default:
//                return ""
//            }
//        }.joined(separator: newLine)
        let properties = _properties
            .map({$0.generate(PropertyLine: $0.property_type, swift_pointer: swift_pointer, cls_title: title)})
            .joined(separator: newLine)
        return """
        \(properties)
        
        fileprivate let \(title)_PyGetSets = PyGetSetDefHandler(
            \(_properties.map { "\(title)_\($0.name)"}.joined(separator: ",\n\t") )
        )
        """
    }
    
    
    
    
}
