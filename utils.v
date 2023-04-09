module vital

import time
import term

pub const (
	method_get     = 'GET'
	method_post    = 'POST'
	method_put     = 'PUT'
	method_patch   = 'PATCH'
	method_delete  = 'DELETE'
	method_head    = 'HEAD'
	method_connect = 'CONNECT'
	method_options = 'OPTIONS'
	method_trace   = 'TRACE'
)

const method_middleware = 'MIDDLEWARE'

enum Method {
	get
	post
	put
	patch
	delete
	head
	connect
	options
	trace
	middleware
}

fn (m Method) str() string {
	return match m {
		.get { vital.method_get }
		.post { vital.method_post }
		.put { vital.method_put }
		.patch { vital.method_patch }
		.delete { vital.method_delete }
		.head { vital.method_head }
		.connect { vital.method_connect }
		.options { vital.method_options }
		.trace { vital.method_trace }
		.middleware { vital.method_middleware }
	}
}

fn method_from_str(m string) !Method {
	return match m {
		'GET' { Method.get }
		'POST' { Method.post }
		'PATCH' { Method.patch }
		'PUT' { Method.put }
		'DELETE' { Method.delete }
		'HEAD' { Method.head }
		'OPTIONS' { Method.options }
		'TRACE' { Method.trace }
		'CONNECT' { Method.connect }
		else { return error('invalid method') }
	}
}

fn method_from_array(methods []string) []Method {
	if methods.len == 0 {
		return [Method.get,.patch,.delete,.head,.options,.trace,.connect,.post,.put]
	}
	mut methods_list := []Method{cap: 9}
	for m in methods {
		method := method_from_str(m.to_upper()) or {panic(err)}
		if methods_list.contains(method) { continue }
		methods_list << method
	}
	return methods_list
}

enum Color {
	r
	w
	y
	b
	m
	c
	g
}

fn lor_endpoint_list(list []Endpoint){
	for endpoint in list{
		log_route(endpoint.method.str(),endpoint.path)
	}
}

fn log_route(method string, path string) {
	colors := {
		"GET":Color.g,
		"POST":.b,
		"PUT":.y,
		"DELETE":.r
	}
	date_now := time.now()
	method_box_spaces := (10 - method.len) / 2
	start_space := ' '.repeat(method_box_spaces)
	end_space := ' '.repeat(method_box_spaces) + if method.len % 2 ==1 {" "} else {""}
	method_for_log := term.bold(bg_color(start_space + method + end_space, colors[method] or {Color.m}))
	println("[Vital]	- ${date_now}		${method_for_log + " ".repeat(10)}${path}")
}

[noreturn]
fn panic_gently(msg string){
	panic(color(msg,.r))
}

fn bg_color(str string, color Color) string {
	if color == .r {
		return term.bg_red(str)
	}
	if color == .b {
		return term.bg_blue(str)
	}
	if color == .y {
		return term.bg_yellow(str)
	}
	if color == .g {
		return term.bg_green(str)
	}
	if color == .m {
		return term.bg_magenta(str)
	}
	if color == .c {
		return term.bg_cyan(str)
	}
	if color == .w {
		return term.bg_white(str)
	}
	return str
}

fn color(str string, color Color) string {
	if color == .r {
		return term.red(str)
	}
	if color == .b {
		return term.blue(str)
	}
	if color == .y {
		return term.yellow(str)
	}
	if color == .g {
		return term.green(str)
	}
	if color == .m {
		return term.magenta(str)
	}
	if color == .c {
		return term.cyan(str)
	}
	return str
}

interface Logger {
	print(string, string)
	info(string)
	error(string)
	warn(string)
	debug(string)
	verbose(string)
}

const logger_color = {
	"info": Color.g
	"error": .r
	"warn": .y
	"debug": .b
	"verbose": .m
}

struct HandlerLogger {
	path string
}

pub fn (l &HandlerLogger) info(msg string) {
	l.print("info", msg)
}
pub fn (l &HandlerLogger) error(msg string) {
	l.print("error", msg)
}
pub fn (l &HandlerLogger) warn(msg string) {
	l.print("warn", msg)
}
pub fn (l &HandlerLogger) debug(msg string) {
	l.print("debug", msg)
}
pub fn (l &HandlerLogger) verbose(msg string) {
	l.print("verbose", msg)
}

fn (l &HandlerLogger) print(type_log string, msg string){
	date_now := time.now()
	log := color( msg, logger_color[type_log] or {Color.w})
	ty := term.bold(color( '[${type_log.title()}] ->', logger_color[type_log] or {Color.w}))
	// [Vital] - 10/2/2001 21:31:11 /api/user/settings [Info] 'asdasdasdasdasdasdas' 
	println("[Vital]	- ${date_now}	${l.path} ${ty} ${log}")
}