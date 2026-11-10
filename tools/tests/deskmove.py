import sys, os, json, tempfile
from lupa import LuaRuntime
SRC_ABS = os.path.abspath(sys.argv[1])
os.chdir(tempfile.mkdtemp())
os.environ["XDG_RUNTIME_DIR"] = os.getcwd()
MOCK = r'''
S = { mons = {}, cur = {x=0,y=0}, active = nil, wins = {}, timers = {}, binds = {}, sent = {}, ws = {},
      button = false, haskey = true, shadow = true, norelease = false, follow = true, grab = nil, claimed = false }
hl = { dsp = { window = {} } }
function hl.dsp.window.move(a) return { kind = "move", a = a } end
function hl.dsp.window.drag() return { kind = "drag" } end
function hl.dispatch(x) S.sent[#S.sent + 1] = x end
function hl.unbind() end
function hl.bind(k, f, o)
  o = o or {}
  if o.mouse and (o.release or o.repeating or o.locked) then error("hl.bind: mouse is exclusive") end
  S.binds[#S.binds + 1] = { k = k, f = f, o = o }
end
function hl.is_key_down(c) if c == 0 then return S.button end return false end
function hl.get_active_window() return S.active and S.wins[S.active] or nil end
function hl.get_window(sel) local a = tostring(sel):gsub("^address:", "") return S.wins[a] end
function hl.get_cursor_pos() return { x = S.cur.x, y = S.cur.y } end
local function at(x, y)
  for _, m in ipairs(S.mons) do
    if x >= m.x and x < m.x + m.width and y >= m.y and y < m.y + m.height then return m end
  end
  local best, bd = nil, 1e18
  for _, m in ipairs(S.mons) do
    local cx = math.max(m.x, math.min(x, m.x + m.width)); local cy = math.max(m.y, math.min(y, m.y + m.height))
    local dd = (cx-x)^2 + (cy-y)^2
    if dd < bd then best, bd = m, dd end
  end
  return best
end
function hl.get_monitor_at(x, y) if type(x) == "table" then return at(x.x, x.y) end return at(x, y) end
function hl.get_monitor_at_cursor() return at(S.cur.x, S.cur.y) end
function hl.get_active_monitor() return S.mons[1] end
function hl.get_active_workspace() return { id = S.ws[hl.get_monitor_at_cursor().name] } end
function hl.get_workspaces() return {} end
function hl.timer(f, o)
  local t = { f = f, o = o, dead = false }
  function t:set_enabled(v) self.dead = not v end
  function t:is_enabled() return not self.dead end
  S.timers[#S.timers + 1] = t
  return t
end
function live() local n = 0 for _, t in ipairs(S.timers) do if not t.dead and t.o.type == "repeat" then n = n + 1 end end return n end
function fire()
  local list = {}
  for _, t in ipairs(S.timers) do if not t.dead then list[#list + 1] = t end end
  for _, t in ipairs(list) do if not t.dead then t.f() if t.o.type == "oneshot" then t.dead = true end end end
end
local function call(k, rel, super)
  for _, b in ipairs(S.binds) do
    local mk = b.k == k or (b.o.ignore_mods and k:gsub("^SUPER %+ ", "") == b.k)
    if mk and (b.o.release or false) == rel then
      if type(b.f) == "function" then
        if rel and S.claimed and S.shadow and not b.o.transparent then
        elseif rel and S.norelease then
        else b.f() end
      elseif b.f.kind == "drag" and not rel then S.claimed = true; S.grab = S.active end
    end
  end
end
function press(super) S.button = true; S.claimed = false; call(super and "SUPER + mouse:272" or "mouse:272", false) end
function release(super) S.button = false; call(super and "SUPER + mouse:272" or "mouse:272", true); S.grab = nil end
function move(x, y)
  local dx, dy = x - S.cur.x, y - S.cur.y
  S.cur.x, S.cur.y = x, y
  if S.grab and S.follow then local w = S.wins[S.grab]; w.at.x = w.at.x + dx; w.at.y = w.at.y + dy end
end
'''
def mk():
    L = LuaRuntime(unpack_returned_tuples=True)
    L.execute(MOCK)
    L.execute(open(SRC_ABS).read())
    return L
def setup(L, mons, wins, active, **kw):
    L.execute("S.mons = {} S.wins = {} S.ws = {} S.sent = {}")
    for k, v in kw.items(): L.execute(f"S.{k} = {'true' if v is True else 'false' if v is False else v}")
    for m in mons:
        L.execute(f'S.mons[#S.mons+1] = {{ name="{m[0]}", x={m[1]}, y=0, width={m[2]}, height={m[3]}, scale=1, reserved={{0,0,0,0}}, active_workspace={{id={m[4]}}} }} S.ws["{m[0]}"]={m[4]}')
    for w in wins:
        L.execute(f'S.wins["{w[0]}"] = {{ address="{w[0]}", at={{x={w[1]},y={w[2]}}}, size={{x={w[3]},y={w[4]}}}, floating=false, fullscreen=0 }}')
    L.execute(f'S.active = "{active}"')
def go(L, x, y, n=1):
    L.execute(f"move({x},{y})")
    for _ in range(n): L.execute("fire()")
def sent(L): return [dict(x.a) for x in L.eval("S.sent").values() if x.a]
def state(): return json.load(open("aero-snap.json"))
ok = True
def check(name, cond, extra=""):
    global ok
    print(("PASS " if cond else "FAIL ") + name, extra); ok &= bool(cond)
def drag_to_edge(L, super=True):
    go(L, 400, 400); L.execute(f"press({'true' if super else 'false'})")
    for x in range(420, 1919, 80): go(L, x, 400)
    go(L, 1919, 400, 30)
one = [("eDP-1", 0, 1920, 1080, 1)]
A = [("A", 100, 100, 800, 600), ("B", 1000, 100, 800, 600)]

L = mk(); setup(L, one, A, "A"); drag_to_edge(L)
check("0.57: flip ready", state().get("flip", {}).get("p") == 1)
L.execute("release(true)"); L.execute("fire()"); L.execute("fire()"); s = sent(L)
check("0.57: shadowed release still drops", s and s[-1].get("workspace") == "2" and s[-1].get("window") == "address:A", s)

L = mk(); setup(L, one, A, "A", norelease=True); drag_to_edge(L)
L.execute("S.button = false S.grab = nil"); [L.execute("fire()") for _ in range(4)]; s = sent(L)
check("release lost: button probe drops", s and s[-1].get("workspace") == "2", s)

L = mk(); setup(L, one, A, "A", norelease=True, haskey=False); L.execute("hl.is_key_down = nil"); drag_to_edge(L)
L.execute("S.button = false S.grab = nil"); go(L, 1800, 400, 2); go(L, 1700, 420, 3); s = sent(L)
check("release lost, no probe: slip drops", s and s[-1].get("workspace") == "2", s)

L = mk(); setup(L, one, A, "A"); drag_to_edge(L); go(L, 1919, 400, 200); s = sent(L)
check("holding at edge never drops early", s == [] and state().get("active") is True, s)

L = mk(); setup(L, one, A, "B"); go(L, 400, 400); L.execute("press(true)"); L.execute('S.active = "A" S.grab = "A"')
for x in range(420, 1919, 80): go(L, x, 400)
go(L, 1919, 400, 30); L.execute('S.active = "B"'); L.execute("release(true)"); L.execute("fire()"); L.execute("fire()"); s = sent(L)
check("focus changes mid-drag: still moves A", s and s[-1].get("window") == "address:A", s)

L = mk(); setup(L, [("eDP-1", 0, 1920, 1080, 1), ("HDMI-A-1", 1920, 1920, 1080, 4)], A, "A")
go(L, 400, 400); L.execute("press(true)"); go(L, 1915, 400, 30)
check("inner edge no flip", not state().get("flip"))
go(L, 3839, 400, 30); L.execute("release(true)"); L.execute("fire()"); L.execute("fire()"); s = sent(L)
check("outer edge of 2nd monitor -> ws 5", s and s[-1].get("workspace") == "5", s)

L = mk(); setup(L, one, A, "A"); go(L, 400, 400); L.execute("press(true)"); go(L, 500, 300, 2)
t3 = [t for t in state()["tiles"] if t["id"] == 3][0]; go(L, t3["x"] + 10, t3["y"] + 10, 2)
L.execute("release(true)"); L.execute("fire()"); L.execute("fire()"); s = sent(L)
check("tile drop", s and s[-1].get("workspace") == "3" and s[-1].get("follow") is False, s)

L = mk(); setup(L, one, A, "A"); go(L, 400, 400); L.execute("press(false)"); go(L, 404, 401, 3); L.execute("release(false)"); [L.execute("fire()") for _ in range(3)]
check("plain click does nothing", sent(L) == [] and state().get("active") is False)
L.execute("S.sent = {}"); go(L, 400, 400); L.execute("press(true)"); go(L, 600, 400, 3); L.execute("release(true)"); [L.execute("fire()") for _ in range(3)]
check("drag in the middle does nothing", sent(L) == [] and state().get("active") is False)
L = mk(); setup(L, one, A, "A")
for i in range(150):
    sup = i % 3 != 0
    go(L, 400, 400); L.execute(f"press({'true' if sup else 'false'})"); go(L, 700, 450, 3); go(L, 900, 500, 3); L.execute(f"release({'true' if sup else 'false'})"); L.execute("fire()")
check("150 drags: no leaked timers", L.eval("live()") <= 1, L.eval("live()"))
L.execute("S.sent = {}"); drag_to_edge(L); st = state(); check("after 150 drags flip still fills normally", st.get("flip", {}).get("p") == 1, st.get("flip"))
L.execute("release(true)"); L.execute("fire()"); L.execute("fire()"); s2 = sent(L); check("after 150 drags still moves", s2 and s2[-1].get("workspace") == "2", s2)
print("ALL OK" if ok else "SOME FAILED")
sys.exit(0 if ok else 1)
