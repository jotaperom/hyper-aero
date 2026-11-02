local W = {}

W.run = (os and os.getenv and os.getenv("XDG_RUNTIME_DIR")) or "/tmp"
W.state_file = W.run .. "/aero-snap.json"
W.edge = 6
W.gap = 10
W.tick_ms = 25
W.dwell_ticks = 28
W.grace_ticks = 6
W.settle_ms = 60
W.up_ticks = 2
W.slip_px = 36
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

local function button_down()
    if not hl.is_key_down then return nil end
    local ok, v = pcall(hl.is_key_down, 0)
    if not ok then return nil end
    return v and true or false
end

local function target(d)
    if d and d.addr and d.addr ~= "" then return "address:" .. d.addr end
    return nil
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

function W.workspace_id(mon)
    if mon then
        local mw = mon.active_workspace or mon.activeWorkspace
        if type(mw) == "table" and mw.id and mw.id > 0 then return mw.id end
    end
    local ws = try(hl.get_active_workspace)
    if ws and ws.id and ws.id > 0 then return ws.id end
    return 1
end

function W.neighbor(a, side, y)
    local x = side == "left" and a.x - 2 or a.x + a.w + 2
    local m = try(hl.get_monitor_at, x, y)
    if not m then m = try(hl.get_monitor_at, { x = x, y = y }) end
    if not m then return false end
    local b = W.area(m)
    if b.name == "" or b.name == a.name then return false end
    return x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h
end

function W.tiles(a, cur)
    local count = 5
    for _, ws in ipairs(try(hl.get_workspaces) or {}) do
        if ws.id and ws.id > count and ws.id <= 9 then count = ws.id end
    end
    cur = cur or W.workspace_id()
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
    local reach = W.edge
    if d.zone == "left" or d.zone == "right" then reach = W.edge * 4 end
    if c.x <= a.x + reach and not W.neighbor(a, "left", c.y) then return "left" end
    if c.x >= a.x + a.w - reach and not W.neighbor(a, "right", c.y) then return "right" end
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

local function halt(t)
    if not t then return end
    try(function() t:set_enabled(false) end)
end

function W.ensure_timer()
    if not W.timer then
        W.timer = try(hl.timer, function() try(W.tick) end, { timeout = W.tick_ms, type = "repeat" })
    end
    return W.timer
end

function W.start_timer()
    local t = W.ensure_timer()
    if t then try(function() t:set_enabled(true) end) end
end

function W.stop_timer()
    halt(W.timer)
end

local function adopt(d, win)
    d.addr = win.address
    d.floating = win.floating and true or false
    d.x, d.y, d.w, d.h = vx(win.at), vy(win.at), vx(win.size), vy(win.size)
end

function W.press(super)
    if not super and W.drag and W.drag.super and not W.drag.moving then return end
    W.stop_timer()
    W.drag = nil
    local win = try(hl.get_active_window)
    if win and win.fullscreen and win.fullscreen > 0 then return end
    local c = try(hl.get_cursor_pos)
    if not c then return end
    W.drag = { super = super and true or false, cx = c.x, cy = c.y, lx = c.x, ly = c.y,
               probe = button_down() == true, up = 0, followed = false, slip = 0,
               moving = false, zone = nil, dwell = 0, away = 0, ticks = 0, flip = nil, tiles = {} }
    if win then adopt(W.drag, win) end
    W.start_timer()
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
    if d.probe then
        if button_down() == false then d.up = d.up + 1 else d.up = 0 end
        if d.up >= W.up_ticks then return W.release() end
    end
    local win
    if d.moving and d.addr then win = try(hl.get_window, target(d)) end
    win = win or try(hl.get_active_window)
    if not win then return end
    if win.address ~= d.addr then
        if d.moving then return end
        if win.fullscreen and win.fullscreen > 0 then return end
        adopt(d, win)
        if not d.super then return end
    end
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
    local wx, wy = vx(win.at), vy(win.at)
    if d.wx then
        local wmove = math.abs(wx - d.wx) + math.abs(wy - d.wy)
        local cmove = math.abs(c.x - d.lx) + math.abs(c.y - d.ly)
        if wmove > 2 then
            d.followed = true
            d.slip = 0
        elseif d.super and d.followed and not d.probe and cmove > 0 then
            d.slip = d.slip + cmove
            if d.slip > W.slip_px then return W.release() end
        end
    end
    d.wx, d.wy, d.lx, d.ly = wx, wy, c.x, c.y
    local mon = try(hl.get_monitor_at_cursor) or try(hl.get_active_monitor)
    if not mon then return end
    local area = W.area(mon)
    if d.area and d.area.name ~= area.name then
        d.zone = nil
        d.dwell = 0
        d.away = 0
    end
    d.area = area
    local cur = W.workspace_id(mon)
    d.tiles = W.tiles(d.area, cur)
    local z = W.zone(c, d.area, d)
    if z == nil and (d.zone == "left" or d.zone == "right") and d.away < W.grace_ticks then
        d.away = d.away + 1
        z = d.zone
    elseif z ~= nil then
        d.away = 0
    end
    if z == "left" or z == "right" then
        if d.zone == z then d.dwell = d.dwell + 1 else d.dwell = 0 end
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
    if not (d.flip and d.flip.ready) and not (d.zone and d.zone:sub(1, 3) == "ws:") then return end
    local done = false
    local t
    t = try(hl.timer, function()
        halt(t)
        if done then return end
        done = true
        try(W.drop, d)
    end, { timeout = W.settle_ms, type = "oneshot" })
    if not t then W.drop(d) end
end

function W.drop(d)
    local a = d.area
    local sel = target(d)
    local win = sel and try(hl.get_window, sel) or try(hl.get_active_window)
    if not win then return end
    if d.addr and win.address ~= d.addr then return end
    if d.flip and d.flip.ready then
        if win.floating then
            local x = clamp(vx(win.at), a.wx + W.gap, a.wx + a.ww - vx(win.size) - W.gap)
            local y = clamp(vy(win.at), a.wy + W.gap, a.wy + a.wh - vy(win.size) - W.gap)
            run(try(hl.dsp.window.move, { x = math.floor(x), y = math.floor(y), window = sel }))
        end
        run(try(hl.dsp.window.move, { workspace = tostring(d.flip.ws), follow = true, window = sel }))
        return
    end
    local z = d.zone
    if z and z:sub(1, 3) == "ws:" then
        if win.floating then run(try(hl.dsp.window.move, { x = d.x, y = d.y, window = sel })) end
        run(try(hl.dsp.window.move, { workspace = z:sub(4), follow = false, window = sel }))
    end
end

function W.shift_desk(dir)
    local target = clamp(W.workspace_id() + dir, 1, 10)
    run(try(hl.dsp.window.move, { workspace = tostring(target), follow = true }))
end

function W.init()
    try(hl.unbind, "SUPER + mouse:272")
    try(hl.bind, "mouse:272", function() try(W.press, false) end, { non_consuming = true, transparent = true, ignore_mods = true })
    try(hl.bind, "mouse:272", function() try(W.release) end, { release = true, non_consuming = true, transparent = true, ignore_mods = true })
    try(hl.bind, "SUPER + mouse:272", function() try(W.press, true) end, { non_consuming = true, transparent = true })
    try(function() hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true }) end)
    try(hl.bind, "SUPER + CTRL + SHIFT + left", function() try(W.shift_desk, -1) end)
    try(hl.bind, "SUPER + CTRL + SHIFT + right", function() try(W.shift_desk, 1) end)
    W.ensure_timer()
    W.stop_timer()
    W.publish(nil)
end

aero_deskmove = W
W.init()
return W
