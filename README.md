<p align="center">
  <img src="./logo.svg" width="180px" alt="Vital Logo"/>
  <h1 align="center">Vital
  </h1>
  <p align="center">Web framework for V.</p>
</p>
<br/>

- [Example](#example)
- [Documentation](#documentation)

### Example

```v
mut app := vital.new()
app.get('/', fn(mut c vital.Context) ! {
  c.json("hello world")
})
app.listen(3000)
```

### Documentation

- ## Server

```v
mut app := vital_new(Config)
```

configuration

1. case_sensitive (bool)
1. read_timeout (time.Duration)
1. write_timeout (time.Duration)
1. methods ([]string)

```v
mut app := vital.new(case_sensitive: false, methods: ["get", "post"])
```

methods:

1. listen(port number)
   Starts the server.

1. error_handler(cb ErrorHandler)
   To Handle errors in request and send response.

```v
// ErrorHandler
fn error_handler(err vital.Exception, mut c vital.Context){}
```

1. method_not_allowed_handler(cb Handler)
   To Handle not allowed methods request.

1. static_file(path string, dir string)
   To Serve Dir in root system.

- ## Router

  To configure the endpoints of your application.

```v
app.get(path, handler_function)
app.post(path, handler_function)
app.delete(path, handler_function)
app.put(path, handler_function)
app.patch(path, handler_function)
app.head(path, handler_function)
app.connect(path, handler_function)
app.options(path, handler_function)
app.trace(path, handler_function)
```

path (string): A URL path to be matched with the requested URL. The path can include parameters like "/", ":id" or "/\*all"

handler_function (function): A function that handles the request and generates a response. It takes one argument: Context, and return error.

```v
path := '/hello'
fn handler_function(mut c vital.Context) ! {
  c.json({"hello":"world"})
}
app.get(path, handler_function)
```

path can be static like => "/user", "/posts" or "/".
or can be dynamic like => "/:id"
or catch all like => "/\*"

Also you can group routers.

```v
mut router := vital.new_router("/user")
router.get(path, handler_function)
app.use(router)
```

- ## Errors

Vital allow to return error in handler funtion

```v
fn handler_function(mut c vital.Context) ! {
  // Custom error with status code
  return c.error("Bad Request", 400)
}
```

```v
fn handler_function(mut c vital.Context) ! {
  // funtion will return error
  do_something() or {return err}
}
```

Vital have Exception for easy and fast error response

```v
fn handler_function(mut c vital.Context) ! {
  // funtion will return error
  do_something() or {return vital.bad_request_exception}
}
```

1. ### bad_request_exception
1. ### not_found_exception
1. ### forbidden_exception
1. ### unauthorized_exception
1. ### not_acceptable_exception
1. ### internal_server_error_exception
1. ### bad_gateway_exception
1. ### method_not_allowed_exception

You can create Custom Exception:

```v
exception := vital.new_exception(msg, status_code)
```

- ## Context

1. ### request
   Request return the http.Request pointer.
1. ### body
   Used in get the request body to.

```v
struct User {
  name string
}
user := c.body(User{}) or {panic("")}
```

1. ### next
   Used in middleware to executes the next handler.
1. ### param
   Method can be used to get the route parameter by key, require parameter key as string.

```v
c.param("id") // return value for parameter :id
```

1. ### add_custom_header
   Method used to add header.

```v
c.add_custom_header(key string, value string)
```

1. ### add_header
   Method used to add header with key in http.CommonHeader.

```v
c.add_header(key http.CommonHeader, value string)
```

1. ### add_custom_header_from_map
   Method used to add headers form map.

```v
c.add_custom_header_from_map(header_map map[string]string)
```

1. ### add_header_from_map
   Method used to add headers map with key in http.CommonHeader.

```v
c.add_header_from_map(header_map map[http.CommonHeader]string)
```

1. ### remove_header
   Method used to remove any number of headers.

```v
c.remove_header(key ...string)
```

1. ### status_code
   Method used add the status code that will send in response.

```v
c.status_code(code int)
```

1. ### status
   Like status_code but accept http.Status.

```v
c.status(code http.Status)
```

1. ### send_status
   Like status but will send the response too.

```v
c.send_status(code http.Status)
```

1. ### json
   Method used to send json response.

```v
c.json[T](j T)
```

1. ### text
   Method used to send text response.

```v
c.text[T](j T)
```

1. ### html
   Method used to send html file.

```v
c.html(path string)
```

1. ### redirect
   Redirects to the URL derived from the specified path.

```v
c.redirect(url string)
```

1. ### redirect
   Redirects to the URL derived from the specified path.

```v
c.redirect(url string)
```

1. ### write
   Method used to write bytes []u8 into the connection

```v
c.write(bytes []u8)
```

1. ### write_response
   Method used to write http.Response into the connection

```v
c.write_response(response http.Response)
```

1. ### set_cookie
   Method to set cookies.
   cookie options

```v
struct Cookie_options {
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
c.set_cookie(name: name, value: value)
```

1. ### file
   To stream files.

```v
struct FileOptions {
	path string [required]
	start u64
	stream bool
	chunk int = 65536
	require_range bool
	range_exception Exception
}
c.file(path: file_path)
```
