local forwardedIP = ngx.var.http_x_forwarded_for
local accessIP = ngx.var.remote_addr
local realIP
if forwardedIP ~= nil then
    realIP = forwardedIP
else
    realIP = accessIP
end

local redis = require "resty.redis"
local red = redis:new()
red:set_timeout(500) --500 millseconds
local config = ngx.shared.redis_config
local ok, err = red:connect(config:get("host"), config:get("port"))

if not ok then
    ngx.log(ngx.ERR, err)
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

local lc = ngx.shared.limit_config

local sc = lc:get("seconds")
if  sc then
    local uri = string.gsub(ngx.var.request_uri, "?.*", "")
    local access_key = ngx.md5(realIP .. uri)
    local counter = red:incr(access_key)
    if counter == 1 then
        red:expire(access_key, 1)
    elseif counter > sc then
        ngx.exit(ngx.HTTP_FORBIDDEN)
    end
end


