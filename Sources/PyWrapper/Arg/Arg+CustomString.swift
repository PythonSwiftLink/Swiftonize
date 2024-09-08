//
//  File.swift
//  
//
//  Created by CodeBuilder on 16/02/2024.
//

import Foundation


extension PyWrap.CollectionArg: CustomStringConvertible {
	public var description: String {
		"\(name): CollectionArg<\(type.element.self)>"
	}
}

extension PyWrap.FloatingPointArg: CustomStringConvertible {
	public var description: String {
		"\(name): FloatingPointArg<\(type.self)>"
	}
}

extension PyWrap.IntegerArg: CustomStringConvertible {
	public var description: String {
		"\(name): IntegerArg<\(type.self)>"
	}
}

extension PyWrap.OtherArg: CustomStringConvertible {
	public var description: String {
		"\(name): OtherArg<\(type.wrapped)>"
	}
}

extension PyWrap.TupleArg: CustomStringConvertible {
	public var description: String {
		"\(name): TupleArg<\(type.element.self)>"
	}
}
