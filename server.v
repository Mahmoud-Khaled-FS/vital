module vital

import net
import net.http
import time
import io
import os
import net.urllib

type Handler = fn (mut c Context) !

type Handlers = []Handler

type ErrorHandler = fn (err Exception, mut c Context)

pub struct App {
	Router
	read_timeout time.Duration = 30 * time.second
	write_timeout time.Duration = 30 * time.second
	not_found_handler Handler = fn (mut ctx Context) ! {
		ctx.status(.not_found)
		ctx.text(http.Status.not_found.str())
	}
	method_not_allowed Handler = fn (mut ctx Context) ! {
		ctx.status(.method_not_allowed)
		ctx.text(http.Status.method_not_allowed.str())
	}
	host string
mut:
	handle_error ErrorHandler = fn (err Exception, mut c Context) {
		c.json(err)
	}
	server net.TcpListener
}

pub fn (mut app App) listen(port int) {
	if 0 >= port || port > 65535 {
		panic('Invalid port number ${port}. The port number must be a positive integer between 1 and 65535.')
	}
	app.initialize_server(port)
}

fn (mut app App) initialize_server(port int) {
	app.server = net.listen_tcp(.ip6, '${app.host}:${port}') or {
		panic_gently('Unable to listen on TCP server. Port:${port} Host:${app.host} Code:${err.code()}')
		}
	lor_endpoint_list(app.endpoint_list)
	println("App started and listening on port ${port}.")
	for {
		mut conn := app.server.accept() or {continue}

		app.server_handler(mut conn)
	}
}

fn (mut app App) server_handler(mut conn net.TcpConn) {
	conn.set_read_timeout(app.read_timeout)
	conn.set_write_timeout(app.write_timeout)
	defer {
		conn.close() or { panic_gently(err.msg()) }
		unsafe{
			conn.free()
		}
	}
	mut reader := io.new_buffered_reader(reader: conn)
	defer {
		unsafe {
			reader.free()
		}
	}
	req_http := http.parse_request(mut reader) or { return }
	route := app.handle_request(&req_http)
	request := new_request(req_http)
	mut ctx := &Context{
		index: 0
		request: request
		conn: conn
		route: route
		app: unsafe{&app}
		log: HandlerLogger{
			path: route.path
		}
	}
	first_handler := route.handlers[ctx.index] or {return}
	first_handler(mut ctx) or {ctx.app.handle_error(exception_from_error(err), mut ctx)}
}

fn (mut app App) handle_request(req &http.Request) &Route {
	url := urllib.parse(req.url) or {panic_gently(err.msg())}
	method := method_from_str(req.method.str()) or {Method.get}
	if method !in app.methods {
		return &Route{handlers: [app.method_not_allowed]}
	}
	mut route := app.get_route(url.path, method_from_str(req.method.str()) or { Method.get }) or {
		Route{handlers: [app.not_found_handler]}
	}
	if route.handlers.len == 0 {
		route.handlers << app.not_found_handler
	}
	return &route
}

pub fn (mut app App) error_handler(handler ErrorHandler) {
	app.handle_error = handler
}

pub fn (mut app App) method_not_allowed_handler(handler ErrorHandler) {
	app.handle_error = handler
}

// /path => /
pub fn (mut app App) static_file(path string, dir string) {
 	if !os.exists(dir){
		panic_gently("can not serve dir not exist. Dir: ${dir}")
	}
	handler := create_static_dir(dir)
	app.get('${path}/*file', handler)
}

fn create_static_dir(dir string) Handler {
	return fn [dir] (mut c Context) ! {
		mut file_name := c.param('file')
		if file_name == ""{
			file_name = 'index.html'
		}
		p := os.abs_path(dir + '/' + file_name )
		c.file(path: p)
	}
}
