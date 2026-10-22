local W = {}

W.run = (os and os.getenv and os.getenv("XDG_RUNTIME_DIR")) or "/tmp"
W.state_file = W.run .. "/aero-snap.json"
W.edge = 6
W.gap = 10
W.tick_ms = 25
W.dwell_ticks = 28
W.max_ticks = 2400
W.tile_w = 66
W.tile_h = 44
W.tile_gap = 8
W.drag = nil
W.timer = nil
W.last_json = ""

local function vx(v)
    if type(v) == "table" then return v.x or v[1] or 0 end
    return 0
end

local function vy(v)
    if type(v) == "table" then return v.y or v[2] or 0 end
    return 0
end

local function clamp(v, lo, hi)
    if hi < lo then return lo end
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function try(f, ...)
    local ok, r = pcall(f, ...)
    if ok then return r end
    return nil
end

local function run(d)
    if d then try(hl.dispatch, d) end
end

local function write_file(path, text)
    if not io or not io.open then return end
    local f = io.open(path .. ".tmp", "w")
    if not f then return end
    f:write(text)
    f:close()
    if os and os.rename then os.rename(path .. ".tmp", path) end
end

local function inside(px, py, r)
    return px >= r.x and px <= r.x + r.w and py >= r.y and py <= r.y + r.h
end

function W.area(mon)
    local s = mon.scale or 1
    if s <= 0 then s = 1 end
    local x = mon.x or vx(mon.position)
    local y = mon.y or vy(mon.position)
    local w = (mon.width or vx(mon.size)) / s
    local h = (mon.height or vy(mon.size)) / s
    if mon.transform and mon.transform % 2 == 1 then w, h = h, w end
    local l, t, r, b = 0, 0, 0, 0
    local res = mon.reserved
    if type(res) == "table" then
        if res.top or res.left or res.right or res.bottom then
            l, t, r, b = res.left or 0, res.top or 0, res.right or 0, res.bottom or 0
        else
            l, t, r, b = res[1] or 0, res[2] or 0, res[3] or 0, res[4] or 0
        end
    end
    return { name = mon.name or "", x = x, y = y, w = w, h = h, wx = x + l, wy = y + t, ww = w - l - r, wh = h - t - b }
end

function W.workspace_id()
    local ws = try(hl.get_active_workspace)
    if ws and ws.id and ws.id > 0 then return ws.id end
    return 1
end

function W.tiles(a)
    local count = 5
    for _, ws in ipairs(try(hl.get_workspaces) or {}) do
        if ws.id and ws.id > count and ws.id <= 9 then count = ws.id end
    end
    local cur = W.workspace_id()
    if cur > count and cur <= 9 then count = cur end
    local out = {}
    for i = 1, count do
        out[#out + 1] = { id = i, x = a.wx + 14 + (i - 1) * (W.tile_w + W.tile_gap), y = a.wy + 10, w = W.tile_w, h = W.tile_h, cur = i == cur }
    end
    return out
end

function W.zone(c, a, d)
    for _, t in ipairs(d.tiles) do
        if inside(c.x, c.y, t) then return "ws:" .. t.id end
    end
    if c.x <= a.x + W.edge then return "left" end
    if c.x >= a.x + a.w - W.edge then return "right" end
    return nil
end

local function json_str(s)
    return '"' .. tostring(s):gsub('[%c"\\]', function(ch)
        if ch == '"' then return '\\"' end
        if ch == "\\" then return "\\\\" end
        return string.format("\\u%04x", ch:byte())
    end) .. '"'
end

local function num(n)
    return string.format("%.1f", n or 0)
end

function W.publish(d)
    local parts = { '{"active":' .. (d and "true" or "false") }
    if d then
        local a = d.area
        parts[#parts + 1] = '"mon":' .. json_str(a.name)
        parts[#parts + 1] = '"zone":' .. json_str(d.zone or "")
        if d.flip then
            parts[#parts + 1] = '"flip":{"dir":' .. json_str(d.flip.dir) .. ',"ws":' .. d.flip.ws .. ',"p":' .. string.format("%.2f", d.flip.p) .. "}"
        end
        local tl = {}
        for _, t in ipairs(d.tiles) do
            tl[#tl + 1] = '{"id":' .. t.id .. ',"x":' .. num(t.x - a.x) .. ',"y":' .. num(t.y - a.y) .. ',"w":' .. num(t.w) .. ',"h":' .. num(t.h)
                .. ',"cur":' .. (t.cur and "true" or "false") .. ',"on":' .. ((d.zone == "ws:" .. t.id) and "true" or "false") .. "}"
        end
        parts[#parts + 1] = '"tiles":[' .. table.concat(tl, ",") .. "]"
    end
    local text = table.concat(parts, ",") .. "}\n"
    if text ~= W.last_json then
        W.last_json = text
        write_file(W.state_file, text)
    end
end

function W.stop_timer()
    if W.timer then
        try(function() W.timer:cancel() end)
        W.timer = nil
    end
end

function W.press(super)
    W.stop_timer()
    W.drag = nil
    local win = try(hl.get_active_window)
    if not win or (win.fullscreen and win.fullscreen > 0) then return end
    local c = try(hl.get_cursor_pos)
    if not c then return end
    W.drag = { addr = win.address, super = super and true or false, floating = win.floating and true or false, x = vx(win.at), y = vy(win.at), w = vx(win.size), h = vy(win.size), cx = c.x, cy = c.y,
               moving = false, zone = nil, dwell = 0, ticks = 0, flip = nil, tiles = {} }
    W.timer = try(hl.timer, function() try(W.tick) end, { timeout = W.tick_ms, type = "repeat" })
end

function W.tick()
    local d = W.drag
    if not d then return W.stop_timer() end
    d.ticks = d.ticks + 1
    if d.ticks > W.max_ticks then
        W.drag = nil
        W.publish(nil)
        return W.stop_timer()
    end
    local win = try(hl.get_active_window)
    if not win or win.address ~= d.addr then return end
    local c = try(hl.get_cursor_pos)
    if not c then return end
    if not d.moving then
        local wx, wy, ww, wh = vx(win.at), vy(win.at), vx(win.size), vy(win.size)
        local far = math.abs(c.x - d.cx) + math.abs(c.y - d.cy) > 14
        local moved = math.abs(wx - d.x) + math.abs(wy - d.y) > 6
        local resized = math.abs(ww - d.w) + math.abs(wh - d.h) > 4
        local within = c.x > wx + 14 and c.x < wx + ww - 14 and c.y > wy + 14 and c.y < wy + wh - 14
        if d.super then
            if not far then return end
        elseif not (far and (moved or resized) and within) then
            return
        end
        if not d.super and d.floating and resized then
            W.drag = nil
            return W.stop_timer()
        end
        d.moving = true
    end
    local mon = try(hl.get_monitor_at_cursor) or try(hl.get_active_monitor)
    if not mon then return end
    d.area = W.area(mon)
    d.tiles = W.tiles(d.area)
    local z = W.zone(c, d.area, d)
    if z == "left" or z == "right" then
        if d.zone == z then d.dwell = d.dwell + 1 else d.dwell = 0 end
        local cur = W.workspace_id()
        local target = z == "left" and cur - 1 or cur + 1
        if target >= 1 and target <= 10 and d.dwell > W.dwell_ticks * 0.35 then
            local p = clamp((d.dwell - W.dwell_ticks * 0.35) / (W.dwell_ticks * 0.65), 0, 1)
            d.flip = { dir = z, ws = target, p = p, ready = p >= 1 }
        else
            d.flip = nil
        end
    else
        d.dwell = 0
        d.flip = nil
    end
    d.zone = z
    W.publish(d)
end

function W.release()
    W.stop_timer()
    local d = W.drag
    W.drag = nil
    W.publish(nil)
    if not d or not d.moving or not d.area then return end
    local a = d.area
    local win = try(hl.get_active_window)
    if d.flip and d.flip.ready then
        if win and win.floating then
            local x = clamp(vx(win.at), a.wx + W.gap, a.wx + a.ww - vx(win.size) - W.gap)
            local y = clamp(vy(win.at), a.wy + W.gap, a.wy + a.wh - vy(win.size) - W.gap)
            run(try(hl.dsp.window.move, { x = math.floor(x), y = math.floor(y) }))
        end
        run(try(hl.dsp.window.move, { workspace = tostring(d.flip.ws), follow = true }))
        return
    end
    local z = d.zone
    if z and z:sub(1, 3) == "ws:" then
        if win and win.floating then run(try(hl.dsp.window.move, { x = d.x, y = d.y })) end
        run(try(hl.dsp.window.move, { workspace = z:sub(4), follow = false }))
    end
end

function W.shift_desk(dir)
    local target = clamp(W.workspace_id() + dir, 1, 10)
    run(try(hl.dsp.window.move, { workspace = tostring(target), follow = true }))
end

function W.init()
    try(hl.unbind, "SUPER + mouse:272")
    try(hl.bind, "mouse:272", function() try(W.press, false) end, { mouse = true, non_consuming = true, ignore_mods = true })
    try(hl.bind, "mouse:272", function() try(W.release) end, { mouse = true, release = true, non_consuming = true, ignore_mods = true })
    try(hl.bind, "SUPER + mouse:272", function() try(W.press, true) end, { mouse = true, non_consuming = true })
    try(function() hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true }) end)
    try(hl.bind, "SUPER + CTRL + SHIFT + left", function() try(W.shift_desk, -1) end)
    try(hl.bind, "SUPER + CTRL + SHIFT + right", function() try(W.shift_desk, 1) end)
    W.publish(nil)
end

aero_deskmove = W
W.init()
return W
