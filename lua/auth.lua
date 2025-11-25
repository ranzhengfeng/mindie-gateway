-- auth.lua
-- OpenResty (lua-resty-redis) 验证 API Key，并把连接归还到连接池
-- 此脚本用于验证 API Key 的有效性，若验证通过则允许请求继续处理。
local redis = require "resty.redis"

-- 日志记录函数
local function log_err(...)
    ngx.log(ngx.ERR, ...)
end

-- 允许 OPTIONS 预检直接通过（如果客户端使用 CORS）
if ngx.req.get_method() == "OPTIONS" then
    return
end

-- 获取 Authorization header
local auth_header = ngx.req.get_headers()["Authorization"]
if not auth_header then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say('{"error":"Missing Authorization Header"}')
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- 提取 Bearer token
local token = auth_header:match("Bearer%s+(.+)")
if not token or token == "" then
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say('{"error":"Invalid Authorization Format"}')
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- 连接 Redis
local red = redis:new()
red:set_timeout(2000)  -- 2s

-- 连接 Redis 服务器
local ok, err = red:connect("mindie-redis", 6379)
if not ok then
    log_err("redis connect error: ", err)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say('{"error":"Internal error"}')
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- 认证 Redis（如果需要）
local res, err = red:auth("Corem@2025!")
-- 认证失败处理
if not res then
    ngx.log(ngx.ERR, "redis auth error: ", err)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say('{"error":"Internal error"}')
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end


-- 检查 Key：键名格式 apikey:{token}
local key = "apikey:" .. token
local exists, err = red:get(key)
if not exists then
    log_err("redis get err: ", err)
end

if exists == ngx.null then
    -- Key 不存在
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.say('{"error":"Invalid API Key"}')

    -- 归还连接
    local ok, _ = red:set_keepalive(10000, 100)  -- keepalive 10s, 100 connections
    if not ok then
        red:close()
    end

    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- 通过验证：你可以把一些限流/租户信息从 Redis 读出，并注入 header 传给后端
-- 例如：ngx.req.set_header("X-User-Id", user_id_from_redis)

-- 归还连接到连接池
local ok, _ = red:set_keepalive(10000, 100)
if not ok then
    red:close()
end

-- allow request to continue (proxy_pass)
return
