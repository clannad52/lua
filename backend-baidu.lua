-- 文件名：test-simple.lua
-- 最简单的HTTP CONNECT代理脚本

local backend = require 'backend'

function wa_lua_on_flags_cb(ctx)
    return backend.SUPPORT.DIRECT_WRITE
end

function wa_lua_on_handshake_cb(ctx)
    local host = backend.get_address_host(ctx)
    local port = backend.get_address_port(ctx)
    
    local request = 'CONNECT ' .. host .. ':' .. port .. ' HTTP/1.1\r\n' ..
                   'Host: ' .. host .. ':' .. port .. '\r\n' ..
                   'Proxy-Connection: Keep-Alive\r\n' ..
                   'User-Agent: ShadowRocket/1.0\r\n' ..
                   '\r\n'
    
    backend.write(ctx, request)
    return false
end

function wa_lua_on_read_cb(ctx, buf)
    if buf and string.find(buf, "HTTP/1.1 200") then
        return backend.RESULT.HANDSHAKE, nil
    end
    return backend.RESULT.DIRECT, buf
end

function wa_lua_on_write_cb(ctx, buf)
    return backend.RESULT.DIRECT, buf
end

function wa_lua_on_close_cb(ctx)
    backend.free(ctx)
    return backend.RESULT.SUCCESS
end

backend.debug("test-simple.lua loaded successfully")