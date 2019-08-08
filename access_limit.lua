local forwardedIP = ngx.var.http_x_forwarded_for
local accessIP = ngx.var.remote_addr
local realIP
if forwardedIP ~= nil then
    realIP = forwardedIP
else
    realIP = accessIP
end
local uri = string.gsub(ngx.var.request_uri, "?.*", "")
local domain = ngx.var.server_name

local config = ngx.shared.config
local useRedis = config:get("redis")
local cache
if  useRedis then
        
    local redis = require "resty.redis"
    local red = redis:new()
    red:set_timeout(500) --500 millseconds
    local config = ngx.shared.redis_config
    local ok, err = red:connect(config:get("host"), config:get("port"))

    if not ok then
        ngx.log(ngx.ERR, err)
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    cache = red
else
    cache = {} 
    function cache:incr(key) 
        return ngx.shared.cache:incr(key, 1)
    end
    function cache:expire(key, ttl)
        return ngx.shared.cache:expire(key, ttl)
    end
end

local lc = ngx.shared.limit_config

local sc = lc:get("access_limit")
local su = lc:get("seconds_unit")
local key = ngx.md5(realIP)
if  sc then
    local counter,err = cache:incr(key)
    if err ~= nil then
        ngx.exit(ngx.HTT_FORBIDDEN)
    end
    if counter == 1 then
        cache:expire(key, su)
    elseif counter > sc then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

local urlLimit = lc:get(domain .. uri)

if urlLimit then
    local counter, err = cache:incr(key)
    if err ~= nil then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
    if counter == 1 then
        cache:expire(key, su)
    elseif counter >  urlLimit then 
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end

