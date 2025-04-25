//
//  Class+DynamicMember.swift
//  Swiftonize
//
//  Created by CodeBuilder on 08/03/2025.
//

import SwiftSyntax
import PyWrapper

public struct DynamicMemberLookup {
    
    let cls_var: String
    
    init(cls_var: String) {
        self.cls_var = cls_var
    }
    
    
    var code: SubscriptDeclSyntax {
        let parameters = FunctionParameterListSyntax {
            .init(
                firstName: .identifier("dynamicMember"),
                secondName: .identifier("member"),
                type: .String
            )
        }
        let genericParameters = GenericParameterClauseSyntax(parameters: .init {
            .init(name: .identifier("T"),colon: .colonToken(), inheritedType: TypeSyntax(stringLiteral: "PySerialize & PyDeserialize"))
        })
        
        return .init(
            genericParameterClause: genericParameters,
            parameterClause: .init(parameters: parameters),
            returnClause: .T,
            accessorBlock: """
            {
            get {
                let gil = PyGILState_Ensure()
                let result: T = try! PyDeserializing.PyObject_GetAttr(\(raw: cls_var), member)
                PyGILState_Release(gil)
                return result
            }
            set {
                member.withCString { string in
                    let gil = PyGILState_Ensure()
                    let object = newValue.pyPointer
                    PyObject_SetAttrString(\(raw: cls_var), string, object)
                    Py_DecRef(object)
                    PyGILState_Release(gil)
                }
            }
            }
            """
        )
    }
}
