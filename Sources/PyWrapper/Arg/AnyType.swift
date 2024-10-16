//
//  File.swift
//  
//
//  Created by CodeBuilder on 13/02/2024.
//

import Foundation


public final class AnyType {
	var type: any TypeProtocol
	
	init(type: any TypeProtocol) {
		self.type = type
	}
}
