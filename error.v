module vital

import net.http

pub struct Exception {
	pub mut:
	msg  string @[json: 'message']
	code int @[json: 'status']
}

pub const (
	bad_request_exception = Exception{
		msg: http.Status.bad_request.str()
		code: http.Status.bad_request.int()
	}
	not_found_exception = Exception{
		msg: http.Status.not_found.str()
		code: http.Status.not_found.int()
	}
	forbidden_exception = Exception{
		msg: http.Status.forbidden.str()
		code: http.Status.forbidden.int()
	}
	unauthorized_exception= Exception{
		msg: http.Status.unauthorized.str()
		code: http.Status.unauthorized.int()
	}
	not_acceptable_exception= Exception{
		msg: http.Status.not_acceptable.str()
		code: http.Status.not_acceptable.int()
	}
	internal_server_error_exception= Exception{
		msg: http.Status.internal_server_error.str()
		code: http.Status.internal_server_error.int()
	}
	bad_gateway_exception= Exception{
		msg: http.Status.bad_gateway.str()
		code: http.Status.bad_gateway.int()
	}
	method_not_allowed_exception= Exception{
		msg: http.Status.method_not_allowed.str()
		code: http.Status.method_not_allowed.int()
	}
)

pub fn (e Exception) msg() string{
	return e.msg
}
pub fn (e Exception) code() int {
	return e.code
}
pub fn (e Exception) str() string {
	return "${e.msg()}"
}


fn exception_from_error(err IError) Exception {
	if err is Exception{
		return *err
	}
	mut ex := Exception{}

	ex = Exception{
		msg: err.msg()
		code: if err.code() > 600 && err.code() <= 0 { 500 } else { err.code() }
	}
	
	return ex
}

pub fn new_exception(msg string, code http.Status) Exception {
	return Exception{
		msg: msg
		code: code.int()
	}
}
pub fn (mut c Context) error(msg string, code http.Status) Exception {
	return Exception{
		msg: msg
		code: code.int()
	}
}

