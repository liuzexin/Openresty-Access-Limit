local redis = require "resty.redis"
ngx.shared.redis_config:set("host",  '127.0.0.1')
ngx.shared.redis_config:set("port", 6379)
ngx.shared.limit_config:set("seconds", 100)

