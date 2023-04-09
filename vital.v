module vital

import time

pub const version = '0.0.1'

[params]
pub struct App_Config {
	case_sensitive bool
	read_timeout time.Duration
	write_timeout time.Duration
	methods []string
}

pub fn new(config App_Config) &App {
	return &App{
		case_sensitive: config.case_sensitive
		read_timeout: config.read_timeout
		write_timeout: config.write_timeout
		methods: method_from_array(config.methods)
	}
}