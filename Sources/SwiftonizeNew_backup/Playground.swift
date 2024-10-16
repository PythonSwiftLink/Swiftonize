//
//  File.swift
//  
//
//  Created by CodeBuilder on 06/02/2024.
//

import Foundation
import PySwiftCore
enum PySendResultFlag: Int32 {
	case RETURN = 0
	case ERROR = -1
	case NEXT = 1
}

extension PySendResultFlag {
	func result() -> PySendResult {
		.init(rawValue)
	}
}
/*PyAsyncMethods(
	am_await: (UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>?,
	am_aiter: (UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>?,
	am_anext: (UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>?,
	am_send: (UnsafeMutablePointer<PyObject>?, UnsafeMutablePointer<PyObject>?, UnsafeMutablePointer<UnsafeMutablePointer<PyObject>?>?) -> PySendResult
 )
*/

let _am_await_code: unaryfunc = { s -> PyPointer? in
		.None
}

let _am_aiter_code: unaryfunc = { s -> PyPointer? in
		.None
}

let _am_anext_code: unaryfunc = { s -> PyPointer? in
		.None
}

let _am_send_code: sendfunc = { s, args , kw  in
	if let s = s {
		let flag: PySendResultFlag = .NEXT
		return flag.result()
	}
	return PYGEN_ERROR
}

func test0() {
	let send: PySendResult = PYGEN_NEXT
}
