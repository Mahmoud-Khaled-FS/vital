module vital

import net.http
import net
import json
import time
import os
import net.http.mime
import strconv
import math

const (
	server_header = http.new_header_from_map({
		http.CommonHeader.server: 'Vital'
		// .connection:              'keep-alive'
		// .keep_alive:              'timeout=5'
	})
	content_types = {
		'json': 'application/json; charset=utf-8'
		'text': 'text/plain; charset=utf-8'
		'html': 'text/html; charset=utf-8'
	}
)

pub struct Context {
	route Route
	app &App
	mut:
	conn          &net.TcpConn
	status_code   http.Status = .ok
	body string
	headers       http.Header = vital.server_header
	index int
	pub:
	log HandlerLogger = HandlerLogger{path: '/'}
	pub mut:
	request &Request
}

pub fn (mut c Context) next() {
	c.index++
	if c.index >= c.route.handlers.len{
		return
	}
	handler := c.route.handlers[c.index] or {return}
	handler(mut c) or {c.app.handle_error(exception_from_error(err), mut c)}
}

pub fn (c &Context) param(key string) string {
	return  c.route.params[key]
}

[params]
pub struct Cookie_options {
	name        string    [required]
	value       string    [required]
	path        string = '/'
	domain      string
	max_age     int
	signed      bool
	http_only   bool
	secure      bool
	expires     time.Time
	raw_expires string
}

fn (mut c Context) send_response() {
	c.add_header(.date, time.now().utc_string())
	mut http_response := http.new_response(status: c.status_code, body: c.body, header: c.headers)
	if c.request.method == .head{
		c.body = ''
		c.add_header(.content_length, '0')
	}
	// mut http_response := http.Response{
	// 	status_code: c.status_code.int()
	// 	http_version: vital.http_version
	// 	status_msg: c.status_code.str()
	// }
	// http_response.header = c.headers
	c.conn.write(http_response.bytes()) or { panic(err) }
}

pub fn (mut c Context) add_custom_header(key string, value string) {
	c.add_custom_header_from_map({
		key: value
	})
}

pub fn (mut c Context) add_header(key http.CommonHeader, value string) {
	c.add_header_from_map({
		key: value
	})
}

pub fn (mut c Context) add_custom_header_from_map(header_map map[string]string) {
	header := http.new_custom_header_from_map(header_map) or { panic_gently(err.msg()) }
	c.headers = c.headers.join(header)
}

pub fn (mut c Context) add_header_from_map(header_map map[http.CommonHeader]string) {
	header := http.new_header_from_map(header_map)
	c.headers = c.headers.join(header)
}

pub fn (mut c Context) remove_header(key ...string) {
	for k in key {
		c.headers.delete_custom(k)
	}
}

pub fn (mut c Context) status_code(code int) {
	status := http.status_from_int(code)
	if !status.is_valid() {
		panic_gently('Invalid status code ${code}')
	}
	c.status_code = status
}

pub fn (mut c Context) status(status http.Status) {
	c.status_code = status
}

pub fn (mut c Context) send_status(status http.Status) {
	c.status_code = status
	c.send_response()
}

pub fn (mut c Context) json[T](data T) {
	json_string := json.encode(data)
	c.add_header(.content_type, content_types['json'])
	c.body = json_string
	c.send_response()
}

pub fn (mut c Context) text[T](text T) {
	c.add_header(.content_type, content_types['text'])
	c.body = text.str()
	c.send_response()
}

// TODO: Go Back
pub fn (mut c Context) redirect(url string) {
	c.add_header(.location, url)
	c.status_code = .found
	c.send_response()
}

pub fn (mut c Context) write(bytes []u8) {
	c.conn.write(bytes) or { panic_gently(err.msg()) }
}

pub fn (mut c Context) write_response(response http.Response) {
	c.conn.write(response.bytes()) or { panic_gently(err.msg()) }
}

pub fn (mut c Context) set_cookie(cookie Cookie_options) {
	http_cookie := http.Cookie{
		name: cookie.name
		value: cookie.value
		path: cookie.path
		domain: cookie.domain
		expires: cookie.expires
		raw_expires: cookie.raw_expires
		max_age: cookie.max_age
		secure: cookie.secure
		http_only: cookie.http_only
		raw: cookie.raw_expires
	}
	c.add_header(.set_cookie, http_cookie.str())
}

pub fn (mut c Context) html(path string) {
	if !os.is_readable(path) {
		panic_gently('html file not found')
	}

	content := os.read_file(path) or { panic_gently(err.msg()) }
	c.add_header(.content_type, content_types['html'])
	c.body = content
	c.send_response()
}

[params]
pub struct FileOptions {
	pub:
	path string [required]
	start u64
	stream bool
	chunk int = 65536
	require_range bool
	range_exception Exception
}

pub fn (mut c Context) file(options FileOptions) {
	path := options.path
	range_header := c.request.header.get(.range) or {
		if options.require_range{
		mut ex := options.range_exception
		if ex.msg == '' {
			ex.msg = 'Range header is reqire.'
		}
		if ex.code == 0 {
			ex.code = 400
		}
		// err := new_exception(require_range_message,)
		c.app.handle_error(ex, mut c)
		return
		}
		''
	}
	if !os.exists(path) {
		c.app.not_found_handler(mut c) or {c.app.handle_error(exception_from_error(err), mut c)}
		return
	}
	ext := os.file_ext(path)
	f_size := os.file_size(path)
	mime_type := mime.get_mime_type(ext[1..])
	chunk_size := options.chunk
	range_bytes_str := range_header.find_between('=', '-')
	mut f := os.open(path) or { return }
	defer {
		f.close()
	}
	mut start := strconv.common_parse_uint(range_bytes_str, 10, 64, true, true) or { options.start }
	mut end := if options.stream{ math.min(start + u64(chunk_size), f_size - 1)} else { f_size }
	response := 'HTTP/1.1 206 Partial Content\r\n' +
		'Content-Range: bytes ${start}-${end - 1}/${f_size}\r\n' +
		'Content-Length: ${end - start + 1}\r\n' + 'Accept-Ranges: bytes\r\n' +
		'Content-Type: ${mime_type}\r\n\r\n'
	c.conn.write(response.bytes()) or { panic(err) }
	for {
		if start + u64(chunk_size) >= end {
			bytes := f.read_bytes_at(int(end - start), start)
			c.conn.write(bytes) or { break }
			break
		}
		bytes := f.read_bytes_at(chunk_size, start)
		c.conn.write(bytes) or { break }
		start += u64(chunk_size)
		unsafe {
			bytes.free()
		}
	}
}

pub fn (mut c Context) body[T](typ T) !T {
	return json.decode(T, c.request.data)!
}
