//
//  File.swift
//  
//
//  Created by CodeBuilder on 13/02/2024.
//

import Foundation


enum WrapperClassOptions: String {
	case py_init
	case debug_mode
	case type
	case target
	case service_mode
	case new
	case unretained
	case pytype
}

public enum WrapClassBase: String {
	case NSObject
	case SwiftBase
	case SwiftObject
	
	
	case Iterable
	case Iterator
	case Collection
	
	case MutableMapping
	case Mapping
	
	case Sequence
	case MutableSequence
	
	case Set
	case MutableSet
	
	case Buffer
	case Bytes
	
	case AsyncIterable
	case AsyncIterator
	case AsyncGenerator
	
	case Number
	
	case Str = "String"
	case Float
	case Int
	case Hashable
	case Callable
}

