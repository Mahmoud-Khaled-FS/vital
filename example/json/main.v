module main

import vital
import router

struct User {
	name string
}

fn main() {
	mut app := vital.new()
	app.use(router.user_router())
	// app.static_file("/file", './static')
	// app.static(os.resource_abs_path('.'), '/')
	// app.use(fn(mut c vital.Context) ! {
	// 	println('Middleware...')
	// 	c.next()
	// })
	// app.get('/', fn(mut c vital.Context) ! {
	// 	c.json('welcome!')
	// })
	// app.get('/video2', fn(mut c vital.Context) ! {
	// 	c.file(path: 'D:\\Moivies\\[EgyBest].Casablanca.1942.BluRay.480p.x264.mp4'0)
	// 	// c.json('welcome!')
	// })
	// app.post('/Login', fn(mut c vital.Context) ! {
	// 	// u := User{}
	// 	user :=c.body(User{}) or {panic("")}
	// 	// println(typeof(c.request.data))
	// 	// user := json.decode(User, c.request.data)!
	// 	println(user)
	// 	c.json("ok we will see")
	// })
	// app.delete('/user', fn(mut c vital.Context) ! {})
	// app.put('/post', fn(mut c vital.Context) ! {})
	// app.patch('/edit', fn(mut c vital.Context) ! {})
	app.listen(3000)
}