import sys, os, tempfile
from lupa import LuaRuntime
SRC_ABS = os.path.abspath(sys.argv[1])
os.chdir(tempfile.mkdtemp())
os.environ["XDG_RUNTIME_DIR"] = os.getcwd(); os.environ["HOME"] = os.getcwd()
os.makedirs(".config/hyper-aero", exist_ok=True)
L = LuaRuntime(unpack_returned_tuples=True)
L.execute(r'''
S = { binds = {}, sent = {}, cfg = { ["decoration.active_opacity"] = 1.0, ["decoration.inactive_opacity"] = 0.95 }, wins = {} }
hl = { dsp = { window = {} } }
function hl.dsp.window.move(a) return a end
function hl.dsp.exec_cmd(c) return { cmd = c } end
function hl.dispatch(x) S.sent[#S.sent+1] = x; if x.window and x.workspace then local a = x.window:gsub("address:",""); for _, w in ipairs(S.wins) do if w.address == a then w.workspace = { id = tonumber(x.workspace) or x.workspace } end end end end
function hl.bind(k, f, o) S.binds[#S.binds+1] = { k = k, f = f, o = o or {} } end
function hl.get_config(k) return S.cfg[k] end
function hl.config(t) S.lastcfg = t end
function hl.get_windows() return S.wins end
function hl.get_window(sel) local a = sel:gsub("address:","") for _, w in ipairs(S.wins) do if w.address == a then return w end end end
function hl.get_active_workspace() return { id = 1 } end
function hl.get_monitors() return { { active_workspace = { id = 1 } } } end
for i, a in ipairs({"A","B","C","D"}) do S.wins[i] = { address = a, workspace = { id = (a == "D") and 2 or 1 }, mapped = true } end
''')
L.execute(open(SRC_ABS).read())
ok = True
def chk(n, c, e=""):
    global ok; print(("PASS " if c else "FAIL ") + n, e); ok &= bool(c)
L.execute("aero_fx.click({x=100,y=200})"); chk("click file", open("aero-click").read().startswith("100 200"))
L.execute("aero_fx.click({x=100,y=200})"); n1 = open("aero-click").read().split()[2]
chk("dedupe double click", n1 == "1", n1)
L.execute("aero_fx.peek(true)"); chk("peek on", L.eval("S.lastcfg.decoration.active_opacity") == 0.03 and open("aero-peek").read().strip() == "1")
L.execute("aero_fx.peek(false)"); chk("peek restores saved", L.eval("S.lastcfg.decoration.inactive_opacity") == 0.95)
L.execute("d = { ticks = 0 }")
x = 500
for t, dx in enumerate([0, 40, 40, -40, -40, 40, 40, -40, -40, 40, 40, -40, -40]):
    x += dx; L.execute(f"d.ticks = {t}; aero_fx.on_drag(d, {{x={x}, y=300}}, 'A')")
mv = [dict(v) for v in L.eval("S.sent").values()]
chk("shake minimizes others on ws", sorted(m["window"] for m in mv) == ["address:B", "address:C"] and all(m["workspace"] == "special:aero-min" for m in mv), mv)
L.execute("S.sent = {}; d2 = { ticks = 100 }")
for t, dx in enumerate([0, 40, 40, -40, -40, 40, 40, -40, -40, 40, 40, -40, -40]):
    x += dx; L.execute(f"d2.ticks = {100+t}; aero_fx.on_drag(d2, {{x={x}, y=300}}, 'A')")
mv = [dict(v) for v in L.eval("S.sent").values()]
chk("shake again restores", sorted(m["window"] for m in mv) == ["address:B", "address:C"] and all(m["workspace"] == "1" for m in mv), mv)
L.execute("S.sent = {}; d3 = { ticks = 200 }")
for t, dx in enumerate([0, 30, 30, 30, -10, 30, 30, 30, 30]):
    x += dx; L.execute(f"d3.ticks = {200+t}; aero_fx.on_drag(d3, {{x={x}, y=300}}, 'A')")
chk("normal drag no shake", len(L.eval("S.sent")) == 0)
open(".config/hyper-aero/settings.json", "w").write('{\n  "fx.shake": false\n}\n')
L.execute("S.sent = {}; d4 = { ticks = 300 }")
for t, dx in enumerate([0, 40, 40, -40, -40, 40, 40, -40, -40, 40, 40, -40, -40]):
    x += dx; L.execute(f"d4.ticks = {300+t}; aero_fx.on_drag(d4, {{x={x}, y=300}}, 'A')")
chk("shake disabled by setting", len(L.eval("S.sent")) == 0)
L.execute("aero_fx.show_desktop()"); mv = [dict(v) for v in L.eval("S.sent").values()]
chk("show desktop hides all on ws", len(mv) == 3, len(mv))
L.execute("S.sent = {}; aero_fx.show_desktop()"); chk("show desktop restores", len(L.eval("S.sent")) == 3)
binds = [b.k for b in L.eval("S.binds").values()]
chk("binds registered", "SUPER + comma" in binds and "SUPER + Z" in binds, binds)
print("ALL OK" if ok else "SOME FAILED")
sys.exit(0 if ok else 1)
