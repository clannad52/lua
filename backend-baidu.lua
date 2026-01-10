-- 文件名：backend-baidu-fixed.lua
-- 这是一个经过修正的HTTP CONNECT代理脚本

-- 第一步：确保backend模块加载成功
local backend = nil
local ok, err = pcall(function()
    backend = require 'backend'
end)

if not backend then
    -- 如果无法加载backend，尝试直接使用全局函数
    -- 注意：Shadowrocket可能不依赖backend模块
    print("[ERROR] Cannot load backend module")
    return
end

-- 定义必要的常量
local DIRECT_WRITE = 1  -- 对应 backend.SUPPORT.DIRECT_WRITE
local SUCCESS = 0       -- 对应 backend.RESULT.SUCCESS
local HANDSHAKE = 1     -- 对应 backend.RESULT.HANDSHAKE
local DIRECT = 0        -- 对应 backend.RESULT.DIRECT

-- 定义全局函数（必须在全局作用域）
function wa_lua_on_flags_cb(ctx)
    print("[DEBUG] wa_lua_on_flags_cb called")
    return DIRECT_WRITE
end

function wa_lua_on_handshake_cb(ctx)
    print("[DEBUG] wa_lua_on_handshake_cb called")
    
    -- 获取目标地址
    local host = "unknown"
    local port = 0
    
    if backend and backend.get_address_host then
        host = backend.get_address_host(ctx)
        port = backend.get_address_port(ctx)
    else
        -- 备选方案：直接返回true，表示握手已完成
        return true
    end
    
    print("[DEBUG] Connecting to " .. host .. ":" .. port)
    
    -- 构建HTTP CONNECT请求
    local request = string.format(
        "CONNECT %s:%d HTTP/1.1\r\n" ..
        "Host: %s:%d\r\n" ..
        "Proxy-Connection: Keep-Alive\r\n" ..
        "User-Agent: baiduboxapp\r\n" ..
        "X-T5-Auth: YTY0Nzlk\r\n" ..
        "\r\n",
        host, port, host, port
    )
    
    -- 发送请求
    if backend and backend.write then
        backend.write(ctx, request)
    else
        -- 备选方案：直接写入数据
        return true
    end
    
    return false  -- 等待服务器响应
end

function wa_lua_on_read_cb(ctx, buf)
    if not buf then
        return DIRECT, nil
    end
    
    print("[DEBUG] wa_lua_on_read_cb, length: " .. #buf)
    
    -- 检查是否是握手响应
    if string.find(buf, "HTTP/1.[01] 200") then
        print("[DEBUG] Proxy handshake successful")
        return HANDSHAKE, nil
    end
    
    -- 检查是否是错误响应
    if string.find(buf, "HTTP/1.[01] [^2]") then
        print("[ERROR] Proxy handshake failed: " .. string.sub(buf, 1, 100))
        return SUCCESS, nil  -- 关闭连接
    end
    
    return DIRECT, buf
end

function wa_lua_on_write_cb(ctx, buf)
    if not buf then
        return DIRECT, nil
    end
    
    print("[DEBUG] wa_lua_on_write_cb, length: " .. #buf)
    return DIRECT, buf
end

function wa_lua_on_close_cb(ctx)
    print("[DEBUG] wa_lua_on_close_cb called")
    
    if backend and backend.free then
        backend.free(ctx)
    end
    
    return SUCCESS
end

-- 可选：初始化函数
function wa_lua_on_init_cb()
    print("[INFO] Lua script initialized: backend-baidu-fixed.lua")
    return SUCCESS
end

print("[INFO] Lua script loaded successfully")