-- 文件名：2.lua
-- Shadowrocket Lua代理脚本

local backend = require 'backend'

-- 必须导出的函数列表
-- 注意：所有函数名必须与Shadowrocket调用的完全一致

-- 1. 标志回调函数 - 告诉Shadowrocket我们支持的功能
function wa_lua_on_flags_cb(ctx)
    backend.log(backend.LOG_DEBUG, "[LUA] wa_lua_on_flags_cb called")
    -- 返回支持的标志：支持直接写入
    return backend.SUPPORT.DIRECT_WRITE
end

-- 2. 握手回调函数 - 建立代理连接
function wa_lua_on_handshake_cb(ctx)
    backend.log(backend.LOG_DEBUG, "[LUA] wa_lua_on_handshake_cb called")
    
    -- 获取目标地址
    local host = backend.get_address_host(ctx)
    local port = backend.get_address_port(ctx)
    
    backend.log(backend.LOG_INFO, "[LUA] Connecting to " .. host .. ":" .. port)
    
    -- 构建HTTP CONNECT请求
    local request = string.format(
        "CONNECT %s:%d HTTP/1.1\r\n" ..
        "Host: %s:%d\r\n" ..
        "Proxy-Connection: Keep-Alive\r\n" ..
        "User-Agent: ShadowRocket/Lua-Proxy\r\n" ..
        "\r\n",
        host, port, host, port
    )
    
    -- 发送请求
    backend.write(ctx, request)
    
    -- 返回false表示需要等待服务器响应
    return false
end

-- 3. 读取回调函数 - 处理从代理服务器接收的数据
function wa_lua_on_read_cb(ctx, buf)
    if buf == nil then
        backend.log(backend.LOG_DEBUG, "[LUA] wa_lua_on_read_cb called with nil buffer")
        return backend.RESULT.DIRECT, nil
    end
    
    backend.log(backend.LOG_DEBUG, "[LUA] wa_lua_on_read_cb called, length: " .. #buf)
    
    -- 检查是否是握手响应（HTTP 200 Connection established）
    if string.find(buf, "HTTP/1.%d+ 200") then
        backend.log(backend.LOG_INFO, "[LUA] Proxy handshake successful")
        -- 握手成功，开始传输数据
        return backend.RESULT.HANDSHAKE, nil
    end
    
    -- 如果收到其他HTTP响应，可能是错误
    if string.find(buf, "HTTP/1.%d+ [^2]") then
        backend.log(backend.LOG_ERROR, "[LUA] Proxy handshake failed: " .. buf)
        return backend.RESULT.ERROR, nil
    end
    
    -- 正常数据传输
    return backend.RESULT.DIRECT, buf
end

-- 4. 写入回调函数 - 处理要发送到代理服务器的数据
function wa_lua_on_write_cb(ctx, buf)
    if buf == nil then
        backend.log(backend.LOG_DEBUG, "[LUA] wa_lua_on_write_cb called with nil buffer")
        return backend.RESULT.DIRECT, nil
    end
    
    backend.log(backend.LOG_DEBUG, "[LUA] wa_lua_on_write_cb called, length: " .. #buf)
    
    -- 直接转发数据
    return backend.RESULT.DIRECT, buf
end

-- 5. 关闭回调函数 - 清理资源
function wa_lua_on_close_cb(ctx)
    backend.log(backend.LOG_DEBUG, "[LUA] wa_lua_on_close_cb called")
    backend.free(ctx)
    return backend.RESULT.SUCCESS
end

-- 可选：初始化函数（如果支持）
function wa_lua_on_init_cb()
    backend.log(backend.LOG_INFO, "[LUA] Script initialized: 2.lua")
    return backend.RESULT.SUCCESS
end

backend.log(backend.LOG_INFO, "[LUA] Script '2.lua' loaded successfully")