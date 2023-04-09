module router

import vital
import controller

pub fn user_router() vital.Router {
	users := ['user1', 'user2']
	mut router := vital.new_router('/user')
	router.get('/', controller.get_users)
	return router
}