module controller

import vital

pub fn get_users(mut c vital.Context) ! {
	user := [1, 2, 3, 4, 5]
	c.json(user)
}