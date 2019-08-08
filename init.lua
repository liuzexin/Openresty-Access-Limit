local redis = require "resty.redis"
ngx.shared.config:set("redis", true)
ngx.shared.redis_config:set("host",  '127.0.0.1')--must
ngx.shared.redis_config:set("port", 6379) --must
ngx.shared.limit_config:set("seconds_unit",  1)--must
ngx.shared.limit_config:set("access_limit", 100)
ngx.shared.limit_config:set("test.com/test", 2)

