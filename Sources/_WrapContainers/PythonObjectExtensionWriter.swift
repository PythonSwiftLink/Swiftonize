//
//  PythonObjectExtensionWriter.swift
//  KivySwiftLink
//
//  Created by MusicMaker on 28/02/2022.
//

import SwiftUI
import PySwiftCore

private let types_array: [Any] = [
    PythonObject.self,
    PythonObject?.self,
    String.self,
    Int.self,
    UInt.self
]


enum CPythonTargetTypes: String , CaseIterable {
    case PythonObject = "PythonPointer"
    case PythonObjectUnwrapped = "PythonPointerU"
    case String
    case Int
    case UInt
    case Int64
    case UInt64
    case Int32
    case UInt32
    case Int16
    case UInt16
    case Int8
    case UInt8
    case Float
    case Double
}

let PythonObjectOnly: [CPythonTargetTypes] = [.PythonObject, .PythonObjectUnwrapped]

let PythonObjectExcluded: [CPythonTargetTypes] = CPythonTargetTypes.allCases.filter{
    switch $0 {
    case .PythonObject, .PythonObjectUnwrapped:
        return false
    default:
        return true
    }
}

func swiftTypeAsCPythonTarget(T: CPythonTargetTypes) -> String? {
    switch T {
    case .PythonObject:
        return nil
    case .PythonObjectUnwrapped:
        return nil
    case .String:
        return "PyUnicode_AsUTF8"
    case .Int, .Int32, .Int16, .Int8:
        return "PyLong_AsLong"
    case .UInt, .UInt32, .UInt16, .UInt8:
        return "PyLong_AsUnsignedLong"
    case .Int64:
        return "PyLong_AsLongLong"
    case .UInt64:
        return "PyLong_AsUnsignedLongLong"
    case .Float, .Double:
        return "PyFloat_AsDouble"
    }
}



func swiftTypeFromCPythonTarget(T: CPythonTargetTypes) -> String? {
    switch T {
    case .PythonObject:
        return nil
    case .PythonObjectUnwrapped:
        return nil
    case .String:
        return "PyUnicode_FromString"
    case .Int, .Int32, .Int16, .Int8:
        return "PyLong_FromLong"
    case .UInt, .UInt32, .UInt16, .UInt8:
        return "PyLong_FromUnsignedLong"
    case .Int64:
        return "PyLong_FromLongLong"
    case .UInt64:
        return "PyLong_FromUnsignedLongLong"
    case .Float, .Double:
        return "PyFloat_FromDouble"
    }
}

func castIfNeededAs(T: CPythonTargetTypes) -> String? {
    switch T {
    case .Int32, .Int16, .Int8:
        return T.rawValue
    case .UInt32, .UInt16, .UInt8:
        return T.rawValue
    case .Double, .Float:
        return T.rawValue
    case .String:
        return T.rawValue
    default:
        return nil
    }
}

func castIfNeededFrom(T: CPythonTargetTypes) -> String? {
    switch T {
    case .Int32, .Int16, .Int8:
        return "Int"
    case .UInt32, .UInt16, .UInt8:
        return "UInt"
    case .Float:
        return "Double"
    default:
        return nil
    }
}




func handleObjectToArray() -> String {
    
    let array_strings = CPythonTargetTypes.allCases.map{ T -> String in
        let convertion = swiftTypeAsCPythonTarget(T: T)
        let casting = castIfNeededAs(T: T)
        let force_unwrap = T == .PythonObjectUnwrapped
        var element = "element"
        if T == .PythonObject {element.append("!")}
        if let convertion = convertion {
            element = "\(convertion)(\(element))"
            if let casting = casting {
                if T == .String {
                    element = "String(cString: \(element))"
                } else {
                    if ["UInt8", "UInt16", "UInt32","Int8", "Int16", "Int32"].contains(casting) {
                        element = "\(casting)(truncatingIfNeeded: \(element))"
                    } else {
                        element = "\(casting)(\(element))"
                    }
                }
            }
        }
        
        //let element = "\(if: convertion != nil, casted_convertion , "element")"
        
        return """
            @inlinable
            public __consuming func array() -> [\(T.rawValue)] {
                let fast_list = PySequence_Fast(self, "")
                let list_count = PythonSequence_Fast_GET_SIZE(fast_list)
                let fast_items = PythonSequence_Fast_ITEMS(fast_list)
                let buffer = UnsafeBufferPointer(start: fast_items, count: list_count)
                var array = [\(T.rawValue)]()
                array.reserveCapacity(buffer.count)
                for element in buffer {
                    array.append(\(element)\(if: force_unwrap, "!"))
                }
                Py_DecRef(fast_list)
                return array
            }
        
        
        """
    }.joined(separator: newLine)
    
    
    return """
    import Foundation
    extension PythonPointer {
    
    \(BaseObjectsAsArray)
    \(array_strings)
    }
    """
}

enum ElementConvertOptions {
    case AsPythonType
    case FromPythonType
}

func elementConverter(element: String,T: CPythonTargetTypes, AsFrom: ElementConvertOptions) -> String {
    var subject = element
    var convertion: String? = nil
    var casting: String? = nil
    switch AsFrom {
    case .AsPythonType:
        convertion = swiftTypeAsCPythonTarget(T: T)
        casting = castIfNeededAs(T: T)
        if let convertion = convertion {
            subject = "\(convertion)(\(subject))"
            if let casting = casting {
                if T == .String {
                    subject = "String(cString: \(subject))"
                } else {
                    subject = "\(casting)(\(subject))"
                }
            }
        }
    case .FromPythonType:
        convertion = swiftTypeFromCPythonTarget(T: T)
        casting = castIfNeededFrom(T: T)
        
        if let convertion = convertion {
            
            if let casting = casting {
                subject = "\(casting)(\(subject))"
            }
            subject = "\(convertion)(\(subject))"
        }
    }//switch end
    //print("\tsubject: \(subject), convertion: \(convertion), casting: \(casting)")
    return subject
}
enum Operators: String, CaseIterable {
    case add = "+"
    case subtract = "-"
    case divide = "/"
    case multiply = "*"
    case not = "!"
    case equal = "="
    case less = "<"
    case greater = ">"
    case blank = ""
}

enum PyRichCompares: String, CaseIterable {
    case not = "!"
    case equal = "="
    case less = "<"
    case greater = ">"
    case blank = ""
}

enum OperatorPosition: String, CaseIterable {
    case lhs
    case rhs
}

func PythonOperatorHandler(lhs: CPythonTargetTypes, rhs: CPythonTargetTypes, op: Operators, extra: Operators = .blank, flip: Bool = false) -> String {
    var lhs_value = "lhs"
    var rhs_value = "rhs"
    if flip {
        lhs_value = "rhs"
        rhs_value = "lhs"
    }
    
    var export: String? = nil
    if lhs == .PythonObject {
    }
    
    //handle lhs
    switch lhs {
    case .PythonObject, .PythonObjectUnwrapped:
        switch op {
        case .add:
            export = "PyNumber_Add"
        case .subtract:
            export = "PyNumber_Subtract"
        case .divide:
            export = "PyNumber_TrueDivide"
        case .multiply:
            export = "PyNumber_Multiply"
        default:
            break
        }
    default:
        break
        //lhs_value = elementConverter(element: lhs.rawValue, T: lhs, AsFrom: .As)
    }
    
    switch rhs {
    case .PythonObject, .PythonObjectUnwrapped:
        rhs_value = elementConverter(element: "\(if: flip, "lhs", "rhs")", T: lhs, AsFrom: .AsPythonType)
//        switch lhs {
//        case .PythonObject, .PythonObjectUnwrapped:
//            lhs_value = "abc"
//        default:
//            rhs_value = elementConverter(element: "rhs", T: lhs, AsFrom: .As)
//        }
    default:
        switch lhs {
        case .PythonObject, .PythonObjectUnwrapped:
            rhs_value = elementConverter(element: "\(if: flip, "lhs", "rhs")", T: rhs, AsFrom: .FromPythonType)
        default:
            rhs_value = "cba"
        }
    }
    
    
    if let export = export {
        if flip { return "\(export)( \(rhs_value) , \(lhs_value) )" }
        else { return "\(export)( \(lhs_value) , \(rhs_value) )" }
        
    }
    if flip { return "\(rhs_value) \(op.rawValue) \(lhs_value)" }
    else { return "\(lhs_value) \(op.rawValue) \(rhs_value)"  }
    
}

let operator_queue: [(Operators, Operators)] = [
    (.add, .equal),
    (.subtract, .equal),
    (.divide, .equal),
    (.multiply, .equal),
    (.add, .blank),
    (.subtract, .blank),
    (.divide, .blank),
    (.multiply, .blank),
    //(.less, .blank),
    //(.less, .equal),
    //(.greater, .blank),
    //(.greater, .equal)
    
]

enum CompareFunctionsMode {
    case mode0
    case mode1
}

func handleCompareFunctions(T: CPythonTargetTypes, targets: [CPythonTargetTypes], mode: CompareFunctionsMode) -> String {
    
    var operators: String = ""
    
    switch mode {
        
    case .mode0:
        operators = targets.map{ T -> String in
    //        let convertion = swiftTypeFromCPythonTarget(T: T)
    //        let casting = castIfNeededFrom(T: T)
            let element = elementConverter(element: "rhs", T: T, AsFrom: .FromPythonType)
            let compare_string = """
                @inlinable static func == (lhs: Self, rhs: \(T.rawValue)) -> Bool {
                    return PyObject_RichCompareBool(lhs, \(element), Py_EQ) == 1
                }
                
                @inlinable static func != (lhs: Self, rhs: \(T.rawValue)) -> Bool {
                    if rhs == nil {
                        return PyObject_RichCompareBool(PythonNone, \(element), Py_NE) == 1
                    }
                    return PyObject_RichCompareBool(lhs, \(element), Py_EQ) == 0
                }
            """
                
            return compare_string
        }.joined(separator: newLine)
        // T = lhs   C = rhs
    case .mode1:
        operators = targets.map{ C -> String in
            let lhs_value = elementConverter(element: "lhs", T: T, AsFrom: .FromPythonType)
            let rhs_value = elementConverter(element: "rhs", T: C, AsFrom: .FromPythonType)
            let compare_string = """
                @inlinable static func == (lhs: Self, rhs: \(C.rawValue)) -> Bool {
                    return PyObject_RichCompareBool(\(lhs_value), \(rhs_value), Py_EQ) == 1
                }
                
                @inlinable static func != (lhs: Self, rhs: \(C.rawValue)) -> Bool {
                    if rhs == nil {
                        return PyObject_RichCompareBool(PythonNone, \(lhs_value), Py_NE) == 1
                    }
                    return PyObject_RichCompareBool(\(lhs_value), \(rhs_value), Py_NE) == 1
                }
            
                @inlinable static func < (lhs: Self, rhs: \(C.rawValue)) -> Bool {
                    return PyObject_RichCompareBool(\(lhs_value), \(rhs_value), Py_LT) == 1
                }

                @inlinable static func <= (lhs: Self, rhs: \(C.rawValue)) -> Bool {
                    return PyObject_RichCompareBool(\(lhs_value), \(rhs_value), Py_LE) == 1
                }
            
                @inlinable static func > (lhs: Self, rhs: \(C.rawValue)) -> Bool {
                    return PyObject_RichCompareBool(\(lhs_value), \(rhs_value), Py_GT) == 1
                }
            
                @inlinable static func >= (lhs: Self, rhs: \(C.rawValue)) -> Bool {
                    return PyObject_RichCompareBool(\(lhs_value), \(rhs_value), Py_GE) == 1
                }
            
            """
            let operator_string = operator_queue.map{ O -> String? in
                let operation = O.0.rawValue + O.1.rawValue
                //print("\(operation) - lhs: \(T.rawValue) , rhs: \(C.rawValue)")
                if T == .String && (O != (.add, .blank) && O != (.add, .equal)) { return nil }
                var operation_strings: [String] = [
                """
                    @inlinable static func \(operation) (lhs:  Self, rhs: \(C.rawValue)) -> Self {
                        return \( PythonOperatorHandler(lhs: T, rhs: C, op: O.0, extra: O.1) )
                    }
                """]
                if T != C {
                    operation_strings.append(
                    """
                        @inlinable static func \(operation) (lhs:  \(C.rawValue), rhs: Self) -> Self {
                            return \( PythonOperatorHandler(lhs: T, rhs: C, op: O.0, extra: O.1, flip: true) )
                        }
                        
                    """)
                }
                return operation_strings.joined(separator: newLine)
            }.compactMap{$0}.joined(separator: newLine)
            return """
            \(compare_string)
            
            \(operator_string)
            """
        }.joined(separator: newLine)
    }
    
        
    
    
    
    
    return """
    
    extension \(T.rawValue) {
    
    \(operators)
    
    }
    """
}

func generateGetSetAttributeExtention(T: CPythonTargetTypes)  -> String {
    
    let pythonpoint_getattrs = CPythonTargetTypes.allCases.map { C -> String in
        let element = elementConverter(element: "attr", T: C, AsFrom: .AsPythonType)
        return """
            
            @inlinable
            func get(key: String) -> \(C.rawValue) {
                let attr = PyObject_GetAttrString(self, key)
                let value = \(element)
                Py_DecRef(attr)
                return value\(if: C == .PythonObjectUnwrapped, "!")
            }
        
            @inlinable
            func get(key: PythonPointerU) -> \(C.rawValue) {
                let attr = PyObject_GetAttr(self, key)
                let value = \(element)
                Py_DecRef(attr)
                return value\(if: C == .PythonObjectUnwrapped, "!")
            }
        
            @inlinable
            func get(key: PythonPointer) -> \(C.rawValue) {
                let attr = PyObject_GetAttr(self, key)
                let value = \(element)
                Py_DecRef(attr)
                return value\(if: C == .PythonObjectUnwrapped, "!")
            }
        
        """
    }.joined(separator: newLine)
    
    let pythonpoint_setattrs = PythonObjectExcluded.map { C -> String in
        let element = elementConverter(element: "value", T: C, AsFrom: .FromPythonType)
        return """
        
            @inlinable
            func set(key: String, value: \(C.rawValue)) {
                PyObject_SetAttrString(self, key, \(element))
            }
            
            @inlinable
            func set(key: PythonPointer, value: \(C.rawValue)) {
                PyObject_SetAttr(self, key, \(element))
            }
        
            @inlinable
            func set(key: PythonPointerU, value: \(C.rawValue)) {
                PyObject_SetAttr(self, key, \(element))
            }
        
        """
    }.joined(separator: newLine)
    
    return """
    extension \(T.rawValue) {
    
    \(pythonpoint_setattrs)
    
    \(pythonpoint_getattrs)

    }
    """
}

func generateSubscripts() -> String {
    let list_subscripts = PythonObjectExcluded.map { T -> String in
        //let get_tuple = elementConverter(element: "PyTuple_GetItem(self, index)", T: T, AsFrom: .As)
        //let get_list = elementConverter(element: "PyList_GetItem(self, index)", T: T, AsFrom: .As)
        let set_value = elementConverter(element: "newValue", T: T, AsFrom: .FromPythonType)
        let element_as = elementConverter(element: "temp", T: T, AsFrom: .AsPythonType)
        //let element_from = elementConverter(element: "newValue", T: T, AsFrom: .From)
        return """
            @inlinable
            public subscript(index: Int) -> \(T.rawValue) {
                
                get {
                    if PythonList_Check(self) {
                        let temp = PyList_GetItem(self, index)
                        let value = \(element_as)
                        Py_DecRef(temp)
                        return value
                    }
                    if PythonTuple_Check(self) {
                        let temp = PyTuple_GetItem(self, index)
                        let value = \(element_as)
                        Py_DecRef(temp)
                        return value
                    }
                    fatalError()
                    }
                    
                set {
                    if PythonList_Check(self) {
                        let temp = \(set_value)
                        PyList_SetItem(self, index, temp)
                        Py_DecRef(temp)
                    }
                    if PythonTuple_Check(self) {
                        let temp = \(set_value)
                        PyTuple_SetItem(self, index, temp)
                        Py_DecRef(temp)
                    }
                }
            }
        
            @inlinable
            public subscript(bounds: Range<Int>) -> [\(T.rawValue)] {
                get {
                    if PythonList_Check(self) {
                        let temp = PyList_GetSlice(self, bounds.lowerBound, bounds.upperBound)
                        let array: [\(T.rawValue)] = temp.array()
                        Py_DecRef(temp)
                        return array
                    }
                    fatalError()
                }
                set {
                    if PythonList_Check(self) {
                        let list = newValue.list_object
                        PyList_SetSlice(self, bounds.lowerBound, bounds.upperBound, list)
                        Py_DecRef(list)
                    }
                }
            }
            
        """
    }.joined(separator: newLine)
    
    return """
    import Foundation
    
    extension PythonPointer {
    
        @inlinable
        public subscript(index: Int) -> PythonPointer {
            
            get {
                if PythonList_Check(self) {
                    return PyList_GetItem(self, index)!
                }
                if PythonTuple_Check(self) {
                    return PyTuple_GetItem(self, index)!
                }
                return nil
                }
                
            set {
                if PythonList_Check(self) {
                    PyList_SetItem(self, index, newValue)
                }
                if PythonTuple_Check(self) {
                    PyTuple_SetItem(self, index, newValue)
                }
            }
        }

        @inlinable
        public subscript(index: Int) -> PythonPointerU {
            
            get {
                if PythonList_Check(self) {
                    return PyList_GetItem(self, index)
                }
                if PythonTuple_Check(self) {
                    return PyTuple_GetItem(self, index)
                }
                fatalError()
                }
                
            set {
                if PythonList_Check(self) {
                    PyList_SetItem(self, index, newValue)
                }
                if PythonTuple_Check(self) {
                    PyTuple_SetItem(self, index, newValue)
                }
            }
        }
    
        @inlinable
        public subscript(bounds: Range<Int>) -> PythonPointerU {
            get {
                if PythonList_Check(self) { return PyList_GetSlice(self, bounds.lowerBound, bounds.upperBound) }
                fatalError()
            }
            set {
                if PythonList_Check(self) { PyList_SetSlice(self, bounds.lowerBound, bounds.upperBound, newValue) }
            }
        }
        
        @inlinable
        public subscript(bounds: Range<Int>) -> PythonPointer {
            get {
                if PythonList_Check(self) { return PyList_GetSlice(self, bounds.lowerBound, bounds.upperBound) }
                return nil
            }
            set {
                if PythonList_Check(self) { PyList_SetSlice(self, bounds.lowerBound, bounds.upperBound, newValue) }
            }
        }
    
        \(list_subscripts)
    
    }
    """
}

func generateArrayToObject() -> String {
    let lists = PythonObjectExcluded.map { T -> String in
        let element_from = elementConverter(element: "element", T: T, AsFrom: .FromPythonType)
        return """
        extension Collection where Element == \(T.rawValue) {
            
            public var list_object: PythonPointer {
                let list = PyList_New(0)
                for element in self {
                    PyList_Append(list, \(element_from))
                }
                return list
            }

            public var tuple_object: PythonPointer {
                let tuple = PyTuple_New(self.count)
                for (i, element) in self.enumerated() {
                    PyTuple_SetItem(tuple, i, \(element_from))
                }
                return tuple
            }
        
            public var _list_object: PythonPointerU {
                let list = PyList_New(0)
                for element in self {
                    PyList_Append(list, \(element_from))
                }
                return list!
            }

            public var _tuple_object: PythonPointerU {
                let tuple = PyTuple_New(self.count)
                for (i, element) in self.enumerated() {
                    PyTuple_SetItem(tuple, i, \(element_from))
                }
                return tuple!
            }
        }
        
        """
    }.joined(separator: newLine)
    
    return """
    \(lists)
    """
}


func generatePythonObjectToType() -> String {
    let type2object = PythonObjectExcluded.map { C -> String in
        let element = elementConverter(element: "self", T: C, AsFrom: .FromPythonType)
        return """
        extension \(C.rawValue) {
            var object: PythonPointerU { \(element) }
        }
        """
    }.joined(separator: newLine)
    return """
    import Foundation
    
    \(type2object)
    
    """
}

func writeArraysFile() {
    let fm = FileManager.default
    //let cur_dir = ROOT_URL
    //let support_files = cur_dir.appendingPathComponent("project_support_files")
    let support_files = URL(fileURLWithPath: "/Users/musicmaker/Documents/GitHub/KivySwiftSupportFiles/project_support_files", isDirectory: true)
    let python_object_support = support_files.appendingPathComponent("PythonObjectSupport", isDirectory: true)
    if !fm.fileExists(atPath: python_object_support.path) {
        try! fm.createDirectory(at: python_object_support, withIntermediateDirectories: true, attributes: [:])
    }
    try! handleObjectToArray().write(to: python_object_support.appendingPathComponent("PythonPointer->Array.swift"), atomically: true, encoding: .utf8)
    let targets: [CPythonTargetTypes] = [.PythonObject]
    let string0 = targets.filter{$0 != .PythonObjectUnwrapped}.map{ T -> String in
        handleCompareFunctions(T: T, targets: CPythonTargetTypes.allCases, mode: .mode1)
    }.joined(separator: newLine)
    
    let string1 = PythonObjectExcluded.map{ T -> String in
        handleCompareFunctions(T: T, targets: PythonObjectOnly, mode: .mode1)
    }.joined(separator: newLine)
        
    try! ["import Foundation\n",string0,string1].joined(separator: newLine + newLine).write(to: python_object_support.appendingPathComponent("PythonPointer+Equatable.swift"), atomically: true, encoding: .utf8)
    
    try! generateGetSetAttributeExtention(T: .PythonObject).write(to: python_object_support.appendingPathComponent("PythonPointer+Attributes.swift"), atomically: true, encoding: .utf8)
    
    try! generatePythonObjectToType().write(to: python_object_support.appendingPathComponent("PythonPointer->Object.swift"), atomically: true, encoding: .utf8)
    
    try! generateSubscripts().write(to: python_object_support.appendingPathComponent("PythonPointer+Subscripts.swift"), atomically: true, encoding: .utf8)
    
    try! generateArrayToObject().write(to: python_object_support.appendingPathComponent("Array->PythonPointer.swift"), atomically: true, encoding: .utf8)
}


let BaseObjectsAsArray = """
    @inlinable
    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {

        let fast_list = PySequence_Fast(self, "fastMap only accepts Lists or Tuples")
        let list_count = PythonSequence_Fast_GET_SIZE(fast_list)
        let fast_items = PythonSequence_Fast_ITEMS(fast_list)
        let buffer = UnsafeBufferPointer(start: fast_items,
                                         count: list_count)
        let initialCapacity = list_count
        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)
        for element in buffer {
            guard let element = element else {return []}
            result.append(try transform(element))
        }
        Py_DecRef(fast_list)
        return Array(result)
    }


    @inlinable
    public func map2<T>( _ transform: (Element) throws -> T) rethrows -> [T] {
        let initialCapacity = underestimatedCount
        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)

        let fast_list = PySequence_Fast(self, "fastMap only accepts Lists or Tuples")
        let list_count = PythonSequence_Fast_GET_SIZE(fast_list)
        let fast_items = PythonSequence_Fast_ITEMS(fast_list)!
        //let buffer = UnsafeBufferPointer(start: fast_items, count: list_count)
        for i in 0..<list_count {
            result.append(try transform(fast_items[i]!))
        }
        Py_DecRef(fast_list)
        return Array(result)
    }


"""
