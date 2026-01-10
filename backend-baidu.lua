-- 文件名：2.lua
-- 这是一个最小化的测试脚本

local backend = require 'backend'

function wa_lua_on_flags_cb(ctx)
    print("[DEBUG] wa_lua_on_flags_cb called")
    return backend.SUPPORT.DIRECT_WRITE
end

function wa_lua_on_handshake_cb(ctx)
    print("[DEBUG] wa_lua_on_handshake_cb called")
    
    -- 获取目标主机和端口
    local host = backend.get_address_host(ctx)
    local port = backend.get_address_port(ctx)
    
    -- 发送CONNECT请求
    local request = 'CONNECT ' .. host .. ':' .. port .. ' HTTP/1.1\r\n' ..
                   'Host: ' .. host .. ':' .. port .. '\r\n' ..
                   'Proxy-Connection: Keep-Alive\r\n' ..
                   'User-Agent: ShadowRocket/1.0\r\n' ..
                   '\r\n'
    
    backend.write(ctx, request)
    return false
end

function wa_lua_on_read_cb(ctx, buf)
    print("[DEBUG] wa_lua_on_read_cb called, buffer length: " .. #buf)
    
    -- 如果是握手响应
    if buf and string.find(buf, "HTTP/1.1 200") then
        print("[DEBUG] Handshake successful")
        return backend.RESULT.HANDSHAKE, nil
    end
    
    return backend.RESULT.DIRECT, buf
end

function wa_lua_on_write_cb(ctx, buf)
    print("[DEBUG] wa_lua_on_write_cb called, buffer length: " .. #buf)
    return backend.RESULT.DIRECT, buf
end

function wa_lua_on_close_cb(ctx)
    print("[DEBUG] wa_lua_on_close_cb called")
    backend.free(ctx)
    return backend.RESULT.SUCCESS
end

print("[INFO] Lua script '2.lua' loaded successfully")