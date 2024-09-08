//
//  File.swift
//  
//
//  Created by CodeBuilder on 12/02/2024.
//

import Foundation

public enum PythonType: String, CaseIterable,Codable {
	case other
	case int
	case long
	case ulong
	case uint
	case int32
	case uint32
	case int8
	case char
	case uint8
	case uchar
	case ushort
	case short
	case int16
	case uint16
	case longlong
	case ulonglong
	case float
	case double
	case float32
	case str
	case bytes
	case data
	case json
	case jsondata
	case list
	case sequence
	case array
	case Array
	case memoryview
	case tuple
	case byte_tuple
	case object
	case dict
	case bool
	case void
	case None
	case callable
	case optional = "Optional"
	case error = "Error"
	case url = "URL"
}


public enum PythonSubscriptType: String, CaseIterable, Codable {
	case list
	case sequence
	case array
	case Array
	case memoryview
	case tuple
	case callable
	case dict
	case optional = "Optional"
	case other
}


public enum PythonIntegers: String, CaseIterable {
	case int
	case long
	case ulong
	case uint
	case int32
	case uint32
	case int8
	case char
	case uint8
	case uchar
	case ushort
	case short
	case int16
	case uint16
	case longlong
	case ulonglong
}


public enum PythonFloatingPoints: String, CaseIterable {
	case float
	case double
	case float32
	//case float16
	
	public init(from: PythonType) {
		self = .init(rawValue: from.rawValue) ?? .double
	}
}
