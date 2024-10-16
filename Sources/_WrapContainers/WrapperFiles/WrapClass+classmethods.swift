
import Foundation
import PySwiftCore
import PyAst



fileprivate enum PyPropertyKeys: String {
    case setter
    case _protocol = "protocol"
	case target
}

fileprivate extension Array where Element == PyAst_Keyword {
    var propertiesOptions: [(PyPropertyKeys,PyAst_Keyword)] {
        compactMap { keyword in
            if let key = PyPropertyKeys(rawValue: keyword.name) {
                return (key, keyword)
            }
            return nil
        }
    }
}

extension WrapClass {
    
    func handleProperties(call: PyAst_Call, target: PyAstObject) {
        
        var setter = true
        var _protocol = false
        var prop_type: ClassPropertyType = .GetSet
		var target_overwrite: String?

        for option in call.keywords.propertiesOptions {
            switch option.0 {
            case .setter: setter = Bool(option.1.value.name) ?? true
            case ._protocol: _protocol = Bool(option.1.value.name) ?? false
			case .target:
				target_overwrite = .init(option.1.value.name)
				//fatalError(target_overwrite!)
            }
            
        }

        prop_type = setter ? .GetSet : .Getter
        
        if let _t = call.args.first {
            let arg_type = _WrapArg.fromAst(index: 0, _t)
            if _protocol { arg_type.add_option(._protocol) }
            properties.append(
                .init(name: target.name, property_type: prop_type, arg_type: _WrapArg.fromAst(index: 0, _t), target_name: target_overwrite)
            )
        }

    }
}
