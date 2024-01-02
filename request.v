module vital

import net.http
import net.urllib

pub struct Request {
	http.Request
mut:
	request_data map[string]string
	query_parsed urllib.Values
pub:
	host string
	params []string
	query  map[string][]string
}

fn new_request(req http.Request) &Request {
	req_host := req.header.get(http.CommonHeader.host) or { '' }
	query_parsed := urllib.parse(req.url) or { urllib.URL{} }
	query := query_parsed.query()
	return &Request{
		Request: req
		host: req_host
		query: query.to_map()
		query_parsed: query
	}
}

pub fn (mut r Request) set(key string, value string) {
	r.request_data[key] = value
}

pub fn (r &Request) get(key string) string {
	value := r.request_data[key] or { '' }
	return value
}

pub fn (r &Request) get_query(key string) []string {
	value := r.query[key] or { [] }
	return value
}

pub fn (r &Request) get_query_array() []string {
	return r.query_parsed.values()
}
