module vital 

struct Endpoint {
	path string
	method Method
}

pub struct Router {
	methods []Method = method_from_array([])
	root_path string = '/'
pub mut:
	case_sensitive bool
mut:
	endpoint_list []Endpoint
	tree map[string]&Node
}

enum NodeType {
	static_node
	params
	all
}

pub fn new_router(path string) Router {
	return Router{
		root_path: path
	}
}

[heap]
struct Node {
	type_node NodeType = .static_node
mut:
	path       string
	full_path  string
	children   []&Node
	handlers   []Handler
	is_leaf    bool
	middleware []Handler
}

struct Route {
	path string
	params Params
	mut:
	handlers Handlers
}

type Params = map[string]string

type Use = string | Handler | Router

pub fn (mut r Router) use(any... Use) {
	mut path := "/"
	mut handlers := []Handler{cap: any.len}
	if any.len == 1 && any[0] is Router{
		mut router := &any[0] as Router
		r.merge_router(mut router)
		return
	}
	for index, hand in any {
		if index == 0 && hand is string {
			path = hand as string
			continue
		}
		if hand !is Handler {
			panic_gently("Invalid handler type provided, Index:${index}")
		}
		handlers << hand as Handler
	}
	if handlers.len == 0 {
		panic_gently('"use" function requires at least one handler function to be passed as an argument.')
	}
	r.create_route(Method.middleware, path,handlers )
}

pub fn (mut r Router) get(path string, handler ...Handler) {
	r.create_route(Method.get, path, handler)
}

pub fn (mut r Router) post(path string, handler ...Handler) {
	r.create_route(Method.post, path, handler)
}

pub fn (mut r Router) put(path string, handler ...Handler) {
	r.create_route(Method.put, path, handler)
}

pub fn (mut r Router) delete(path string, handler ...Handler) {
	r.create_route(Method.delete, path, handler)
}

pub fn (mut r Router) patch(path string, handler ...Handler) {
	r.create_route(Method.patch, path, handler)
}

pub fn (mut r Router) head(path string, handler ...Handler) {
	r.create_route(Method.head, path, handler)
}

pub fn (mut r Router) options(path string, handler ...Handler) {
	r.create_route(Method.options, path, handler)
}

pub fn (mut r Router) trace(path string, handler ...Handler) {
	r.create_route(Method.trace, path, handler)
}

pub fn (mut r Router) connect(path string, handler ...Handler) {
	r.create_route(Method.connect, path, handler)
}

fn (mut n Node) match_node(path string) ?Route {
	//create Params
	mut params := Params(map[string]string{})
	mut current_node := unsafe { &n }
	if path == '/' {
		size := current_node.middleware.len + current_node.handlers.len
		mut handlers := []Handler{cap: size}
		handlers << current_node.middleware
		handlers << current_node.handlers
		return Route{
			path: current_node.full_path
			handlers: handlers
			params: params
		}
	}
	mut handler_chain := []Handler{}
	if n.middleware.len > 0{
		handler_chain << n.middleware
	}
	path_levels := get_path_level(path)
	for i,p in path_levels {
		for child in current_node.children {
			if child.type_node == .all {
				params[child.path[1..]] = p
				current_node = child
				break
			}
			if child.type_node == .params {
				params[child.path[1..]] = p
				if i == path_levels.len -1 {
					current_node = child
					break
				}
			}
			if child.path == p {
				if child.middleware.len > 0 {
					handler_chain << child.middleware
				}
				current_node = child
				break
			}
		}
	}
	if path != current_node.full_path && current_node.type_node == .static_node {
		return none
	}
	if !current_node.is_leaf {
		return none
	}
	handler_chain << current_node.handlers
	return Route{
		path: current_node.full_path
		handlers: handler_chain
		params: params
	}
}

fn (mut n Node) new_empty_node(path string) &Node {
	mut full_path := n.full_path + path
	if n.full_path != '/' {
		full_path = n.full_path + '/' + path
	}

	child := &Node{
		path: path
		full_path: full_path
		handlers: []
		is_leaf: false
	}
	return child
}

fn (mut n Node) new_node(path string, handlers Handlers, handler_type string) &Node {
	mut full_path := n.full_path + path
	if n.full_path != '/' {
		full_path = n.full_path + '/' + path
	}
	// get Node Type here
	node_type := get_node_type(path)

	mut child := &Node{
		path: path
		full_path: full_path
		is_leaf: true
		type_node: node_type
	}

	if handler_type == 'handler' {
		child.handlers = handlers
	} else if handler_type == 'middleware' {
		child.middleware = handlers
	}
	return child
}

fn (mut n Node) add_middleware(path string, handler Handlers) {
	mut current_node := unsafe { &n }
	if path == '/' {
		current_node.middleware << handler
		return
	}
	path_levels := get_path_level(path)
	for lvl in path_levels {
		mut c := current_node.find_node(lvl) or {
			mut child := &Node{}
			if lvl == path_levels.last() {
				child = current_node.new_node(lvl, handler, 'middleware')
			} else {
				child = current_node.new_empty_node(lvl)
			}
			current_node.add_child(child)
			current_node = child
			continue
		}
		if lvl != path_levels.last() {
			current_node = c
			continue
		}
		c.handlers << handler
	}
}

fn (mut n Node) add_route(path string, handler Handlers) {
	mut current_node := unsafe { &n }
	if path == '/' && current_node.full_path == path {
		current_node.handlers << handler
		return
	}

	path_levels := get_path_level(path)
	for lvl in path_levels {
		mut c := current_node.find_node(lvl) or {
			mut child := &Node{}
			if lvl == path_levels.last() {
				child = current_node.new_node(lvl, handler, 'handler')

			} else {
				child = current_node.new_empty_node(lvl)
			}

			current_node.add_child(child)
			current_node = child
			continue
		}
		if lvl != path_levels.last() {
			current_node = c
			continue
		}
		c.handlers << handler
	}
}

fn (mut n Node) add_child(child &Node) {
	n.children << child
}

fn (n &Node) find_node(path string) !&Node {
	for child in n.children {
		if child.path == path {
			return child
		}
	}
	return error('this is error')
}

fn get_path_level(path string) []string {
	return path.split('/').filter(it != '')
}

fn (mut router Router) get_route(path string, method Method) ?Route {
	mut path_search := path
	if !router.case_sensitive {
		path_search = path_search.to_lower()
	}
	r := router.tree[method.str()].match_node(path_search)?
	return r
}

fn (mut r Router) create_route(method Method, path string, handlers []Handler) {
	mut route_path := path
	if !r.case_sensitive {
		route_path = route_path.to_lower()
	}
	if handlers.len == 0 {
		panic_gently('Missing handler in route: ${path}')
	}
	if route_path == '' {
		route_path = '/'
	}
	if route_path[0] != '/'.bytes()[0] {
		route_path = '/' + route_path
	}

	if method != .middleware {
		if !r.methods.contains(method) {return}
		mut root := r.tree[method.str()] or {r.create_root(method.str())}
		root.add_route(route_path, handlers)
		r.endpoint_list << Endpoint{method: method,path: if r.root_path == '/' {route_path} else {r.root_path + route_path}}
	} else {
		for key in r.methods {
			mut root := r.tree[key.str()] or {r.create_root(key.str())}
			root.add_middleware(route_path, handlers)
		}
	}

}

fn (mut r Router) create_root(method string) &Node {
	root := &Node{
		path: ''
		full_path: '/'
		children: []
		handlers: []
	}
	r.tree[method] = root
	return  root
}

fn (mut r Router) merge_router(mut router Router) {
	for method, mut root in router.tree{
		mut tree_root := r.tree[method] or {r.create_root(method)}
		root.travel_in_tree(fn [mut tree_root, router, mut r, method] (node &Node) {
			if node.handlers.len > 0 {
				// println()
				path := if node.full_path == '/' {''} else { node.full_path } 
				tree_root.add_route(router.root_path + '/' + path, node.handlers)
				r.endpoint_list << Endpoint{method: method_from_str(method) or {Method.get}, path: router.root_path + '/' + path}
				return
			}
			if node.middleware.len > 0 {
				tree_root.add_middleware(node.full_path, node.middleware)
				return
			}
			return
		})
	}
}

fn (mut node Node) travel_in_tree(cb fn(&Node)) {
	cb(node)
	if node.children.len == 0{
		return
	}
	for mut child in node.children{
		child.travel_in_tree(cb)
	}
}

// start in router type
fn get_node_type(path string) NodeType {
	if path.starts_with(":") {
		return .params
	}
	if path.starts_with('*') {
		return .all
	}
	return .static_node
}