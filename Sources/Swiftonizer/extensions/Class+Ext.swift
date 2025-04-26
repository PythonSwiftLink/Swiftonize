//
//  File.swift
//  
//
//  Created by CodeBuilder on 13/02/2024.
//

import Foundation
import PyWrapper
import PyAst

extension PyWrap.Class {
	
	func bases() -> [WrapClassBase] {
		var output = [WrapClassBase]()
		guard let ast = ast else { return output }
		
		if let bases = ast.decorator_list.first(name: "bases") {
			if let call = bases as? AST.Call {
				output += call.args.map({$0 as! AST.Name}).compactMap {
					WrapClassBase(rawValue: $0.id)
				}
				
			}
		}
		output += ast.bases.compactMap({ expr in
			if let name = expr as? AST.Name {
				return WrapClassBase(rawValue: name.id)
			}
			return nil
		})
		
//		if let bases = ast?.decorator_list.contains(where: { deco in
//			if let call = deco as? AST.Call {
//				return (call._func as? AST.Name)?.id == "bases"
//			}
//			return false
//		}) {
//			for deco in ast?.decorator_list ?? [] {
//				if let call = deco as? AST.Call, (call._func as! AST.Name).id == "bases" {
//					output.append(contentsOf:
//						call.args.compactMap({$0 as! AST.Name}).compactMap({
//							WrapClassBase(rawValue: $0.id)
//						})
//					)
//				}
//			}
//		}
//		output.append(contentsOf:
//			ast.bases.compactMap({ expr in
//				if let name = expr as? AST.Name {
//					return WrapClassBase(rawValue: name.id)
//				}
//				return nil
//			}) ?? []
//		)
		return output
	}
}

extension PyWrap.Class.Callbacks {
	func bases() -> [WrapClassBase] {
		if let bases = cls?.ast?.decorator_list.contains(where: { deco in
			if let call = deco as? AST.Call {
				return (call._func as? AST.Name)?.id == "bases"
			}
			return false
		}) {
			for deco in cls?.ast?.decorator_list ?? [] {
				if let call = deco as? AST.Call, (call._func as! AST.Name).id == "bases" {
					return call.args.compactMap({$0 as! AST.Name}).compactMap({
						WrapClassBase(rawValue: $0.id)
					})
				}
			}
		}
		return cls?.ast?.bases.compactMap({ expr in
			if let name = expr as? AST.Name {
				return WrapClassBase(rawValue: name.id)
			}
			return nil
		}) ?? []
	}
}
