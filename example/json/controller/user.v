module controller

import vital

pub fn get_users(mut c vital.Context) ! {
	user := [1, 2, 3, 4, 5]
	c.log.info("info")
	c.log.warn("warn")
	c.log.error("error")
	c.log.verbose("verbose")
	c.log.debug("debug")
	c.json(user)
}