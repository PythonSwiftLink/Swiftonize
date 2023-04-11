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
        let arg = arg_type_new
        
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
        
        return optional ? "guard let v = v, let newValue = try? \(arg.type.swiftType)(object: v) else { return 1 }" :  (is_object ? "v" : "\(arg.type.swiftType)(v)")
        
    }
    
    fileprivate func getter_extract_line(target: String, callValue: String) -> String {
        
        let optional = arg_type_new.options.contains(.optional)
        var getter_extract = ""
        if arg_type_new.options.contains(._protocol) {
            if let other_type = arg_type_new.other_type {
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
    
    fileprivate func generate(GetSet swift_pointer: String, cls_title: String) -> String {
        let arg = arg_type_new
        let is_object = arg.type == .object
        let optional = arg.options.contains(.optional)
        let prop_name = name == "py_callback" ? "py_callback" : name
        //        let target = "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"
        let target = "\(swift_pointer).\(name)"
        let call = "\(arg.swift_property_getter(arg: target))"
//        var setValue = optional ? "guard let v = v, let newValue = try? \(arg.type.swiftType)(object: v) else { return 1 }" :  (is_object ? "v" : "\(arg.type.swiftType)(v)")
        var callValue = target//is_object ? "\(call)" : call
        if name == "py_callback" {
            callValue = "\(call)?._pycall.ptr"
        }
        
        // \(arg.options.contains(._protocol) || !(arg.name == "py_callback") ? setValue : "guard let v = v, let newValue = \(setValue) else { return 1 } // fool")
        return """
        fileprivate let \(cls_title)_\(name) = PyGetSetDefWrap(
            pySwift: "\(name)",
            getter: {s,clossure in
                \(getter_extract_line(target: target, callValue: callValue))
                return v\(if: (name != "py_callback"), ".pyPointer", "// hmmm")
            },
            setter: { s,v,clossure in
                \(setter_extract_line(target: target, callValue: callValue, cls_title: cls_title))
                \(swift_pointer).\(prop_name) = newValue
                return 0
            }
        )
        """.replacingOccurrences(of: newLine, with: newLineTab)
    }
    
    fileprivate func generate(Getter swift_pointer: String, cls_title: String) -> String {
        let arg = arg_type_new
        //let is_object = arg.type == .object
        let optional = arg.options.contains(.optional)
        //let target = "(s.getSwiftPointer() as \(cls_title)).\(prop.name)"
        let target = "\(swift_pointer).\(name)"
        //let call = "\(arg.swift_property_getter(arg: "(s.getSwiftPointer() as \(cls_title)).\(name)"))"
        let callValue = target//is_object ? "PyPointer(\(call))" : call
        
        let getter_extract = optional ? "guard let v = \(target) else { return .PyNone }" : "let v = \(callValue)"
        return """
        fileprivate let \(cls_title)_\(name) = PyGetSetDefWrap(
            pySwift: "\(name)",
            getter: { s,clossure in
                \(getter_extract)
                return v.pyPointer
            }
        )
        """.replacingOccurrences(of: newLine, with: newLineTab)
    }
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
            _properties.insert(.init(name: "py_callback", property_type: .GetSet, arg_type: .init(name: "", type: .object, other_type: "", idx: 0, arg_options: [])), at: 0)
        }
        let swift_pointer = getSwiftPointer.replacingOccurrences(of: "?", with: "")
        let properties = _properties.map { p -> String in
            switch p.property_type {
            case .Getter:
                return p.generate(Getter: swift_pointer, cls_title: title)
            case .GetSet:
                //return generate(GetSet: p, cls_title: title)
                return p.generate(GetSet: swift_pointer, cls_title: title)
            default:
                return ""
            }
        }.joined(separator: newLine)
        
        return """
        \(properties)
        
        fileprivate let \(title)_PyGetSets = PyGetSetDefHandler(
            \(_properties.map { "\(title)_\($0.name)"}.joined(separator: ",\n\t") )
        )
        """
    }
    
    
    
    
}
