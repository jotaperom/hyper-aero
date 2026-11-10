local F = {}

F.run = (os and os.getenv and os.getenv("XDG_RUNTIME_DIR")) or "/tmp"
F.home = (os and os.getenv and os.getenv("HOME")) or ""
F.scripts = F.home .. "/.config/hyper-aero/scripts"
F.settings_file = F.home .. "/.config/hyper-aero/settings.json"
F.click_file = F.run .. "/aero-click"
F.peek_file = F.run .. "/aero-peek"
F.min_file = F.run .. "/aero-min"
F.special = "special:aero-min"
F.seq = 0
F.last = { x = -1, y = -1, n = -1 }
F.ticks = 0
F.peeking = false
F.hidden = {}

local function try(f, ...)
    local ok, r = pcall(f, ...)
    if ok then return r end
    return nil
end

local function run(d)
    if d then try(hl.dispatch, d) end
end

local function vx(v)
    if type(v) == "table" then return v.x or v[1] or 0 end
    return 0
end

local function vy(v)
    if type(v) == "table" then return v.y or v[2] or 0 end
    return 0
end

local function write_file(path, text)
    if not io or not io.open then return end
    local f = io.open(path .. ".tmp", "w")
    if not f then return end
    f:write(text)
    f:close()
    if os and os.rename then os.rename(path .. ".tmp", path) end
end

local function read_file(path)
    if not io or not io.open then return "" end
    local f = io.open(path, "r")
    if not f then return "" end
    local t = f:read("*a") or ""
    f:close()
    return t
end

function F.enabled(key)
    local s = read_file(F.settings_file)
    local pat = '"' .. key:gsub("%.", "%%.") .. '"%s*:%s*false'
    return not s:find(pat)
end

function F.save()
    local out = {}
    for ws, list in pairs(F.hidden) do
        for _, addr in ipairs(list) do out[#out + 1] = ws .. " " .. addr end
    end
    write_file(F.min_file, table.concat(out, "\n") .. "\n")
end

function F.load()
    F.hidden = {}
    for line in read_file(F.min_file):gmatch("[^\n]+") do
        local ws, addr = line:match("^(%S+)%s+(%S+)$")
        if ws and addr then
            F.hidden[ws] = F.hidden[ws] or {}
            table.insert(F.hidden[ws], addr)
        end
    end
end

local function ws_id(w)
    if type(w) ~= "table" then return nil end
    local ws = w.workspace
    if type(ws) == "table" then return ws.id end
    return ws
end

local function sel(w)
    return "address:" .. w.address
end

function F.click(c)
    F.seq = F.seq + 1
    if c.x == F.last.x and c.y == F.last.y and F.seq - F.last.n <= 1 then return end
    F.last = { x = c.x, y = c.y, n = F.seq }
    write_file(F.click_file, string.format("%d %d %d\n", math.floor(c.x), math.floor(c.y), F.seq))
end

local function truthy(v)
    return v == true or v == 1 or v == "1" or v == "true"
end

function F.peek(on)
    on = on and true or false
    if on == F.peeking then return end
    if on and not F.enabled("fx.peek") then return end
    F.peeking = on
    if on then
        F.saved = {
            a = tonumber(try(hl.get_config, "decoration.active_opacity")) or 1.0,
            i = tonumber(try(hl.get_config, "decoration.inactive_opacity")) or 0.9,
            blur = try(hl.get_config, "decoration.blur.enabled"),
            shadow = try(hl.get_config, "decoration.shadow.enabled"),
            glow = try(hl.get_config, "decoration.glow.enabled"),
        }
        try(hl.config, { decoration = { active_opacity = 0.03, inactive_opacity = 0.03 } })
        if F.saved.blur ~= nil then try(hl.config, { decoration = { blur = { enabled = false } } }) end
        if F.saved.shadow ~= nil then try(hl.config, { decoration = { shadow = { enabled = false } } }) end
        if F.saved.glow ~= nil then try(hl.config, { decoration = { glow = { enabled = false } } }) end
    else
        local s = F.saved or { a = 1.0, i = 0.9 }
        if s.blur ~= nil then try(hl.config, { decoration = { blur = { enabled = truthy(s.blur) } } }) end
        if s.shadow ~= nil then try(hl.config, { decoration = { shadow = { enabled = truthy(s.shadow) } } }) end
        if s.glow ~= nil then try(hl.config, { decoration = { glow = { enabled = truthy(s.glow) } } }) end
        try(hl.config, { decoration = { active_opacity = s.a, inactive_opacity = s.i } })
    end
    write_file(F.peek_file, on and "1\n" or "0\n")
end

local function visible_ws()
    local out = {}
    local mons = try(hl.get_monitors) or {}
    for _, m in ipairs(mons) do
        local aw = m.active_workspace or m.activeWorkspace
        if type(aw) == "table" and aw.id then out[aw.id] = true end
    end
    if next(out) == nil then
        local w = try(hl.get_active_workspace)
        if w and w.id then out[w.id] = true end
    end
    return out
end

local function current_ws()
    local w = try(hl.get_active_workspace)
    return w and w.id or nil
end

function F.minimize(except, ws)
    local wins = try(hl.get_windows) or {}
    local moved = {}
    for _, w in ipairs(wins) do
        local id = ws_id(w)
        if id == ws and w.address ~= except and w.mapped ~= false then
            run(try(hl.dsp.window.move, { workspace = F.special, follow = false, window = sel(w) }))
            moved[#moved + 1] = w.address
        end
    end
    if #moved > 0 then
        F.hidden[tostring(ws)] = moved
        F.save()
    end
    return #moved
end

function F.restore(ws)
    local list = F.hidden[tostring(ws)]
    if not list then return 0 end
    F.hidden[tostring(ws)] = nil
    F.save()
    for _, addr in ipairs(list) do
        if try(hl.get_window, "address:" .. addr) then
            run(try(hl.dsp.window.move, { workspace = tostring(ws), follow = false, window = "address:" .. addr }))
        end
    end
    return #list
end

function F.show_desktop()
    local ws = current_ws()
    if not ws then return end
    if F.hidden[tostring(ws)] then
        F.restore(ws)
    else
        F.minimize(nil, ws)
    end
end

function F.shake(addr)
    if not F.enabled("fx.shake") then return end
    local w = try(hl.get_window, "address:" .. addr)
    local ws = w and ws_id(w) or current_ws()
    if not ws then return end
    if F.hidden[tostring(ws)] then
        F.restore(ws)
    else
        F.minimize(addr, ws)
    end
end

function F.on_drag(d, c, addr)
    if not d.fx then d.fx = { lx = c.x, dir = 0, travel = 0, marks = {}, done = false } end
    local s = d.fx
    if s.done then return end
    local dx = c.x - s.lx
    s.lx = c.x
    if math.abs(dx) < 2 then return end
    local dir = dx > 0 and 1 or -1
    if dir == s.dir then
        s.travel = s.travel + math.abs(dx)
        return
    end
    if s.dir ~= 0 and s.travel >= 28 then
        s.marks[#s.marks + 1] = d.ticks or 0
    end
    s.dir = dir
    s.travel = math.abs(dx)
    local now = d.ticks or 0
    local recent = 0
    for _, t in ipairs(s.marks) do
        if now - t <= 32 then recent = recent + 1 end
    end
    if recent >= 4 and addr then
        s.done = true
        F.shake(addr)
    end
end

function F.init()
    local fx = F.scripts .. "/fx.sh"
    try(hl.bind, "SUPER + comma", function() F.peek(true) end, { transparent = true })
    try(hl.bind, "SUPER + comma", function() F.peek(false) end, { release = true, transparent = true })
    try(function() hl.bind("SUPER + Z", hl.dsp.exec_cmd(fx .. " radial")) end)
    try(function() hl.bind("SUPER + mouse:274", hl.dsp.exec_cmd(fx .. " radial")) end)
    try(function() hl.bind("SUPER + ALT + Tab", hl.dsp.exec_cmd(fx .. " flip")) end)
    try(function() hl.bind("SUPER + SHIFT + Tab", hl.dsp.exec_cmd(fx .. " flip")) end)
    write_file(F.peek_file, "0\n")
    F.load()
end

aero_fx = F
F.init()

return F
