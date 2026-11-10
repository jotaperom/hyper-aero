import QtQuick
import Quickshell

Scope {
    id: g
    property var screen
    property var rect: null
    property bool on: false
    property var bars: []
    property real level: 0
    property real radius: 10
    property int border: 2
    property var pal
    property int fps: 24
    readonly property real sx: screen ? screen.x : 0
    readonly property real sy: screen ? screen.y : 0
    readonly property real sw: screen ? screen.width : 0
    readonly property real sh: screen ? screen.height : 0
    readonly property bool here: !!rect && rect.x + rect.w / 2 >= sx && rect.x + rect.w / 2 < sx + sw && rect.y + rect.h / 2 >= sy && rect.y + rect.h / 2 < sy + sh
    readonly property bool want: on && here && rect.w > 40 && rect.h > 40
    property real fade: 0
    readonly property bool live: want || fade > 0.01
    readonly property color c1: pal ? pal.glow : "#3d9be9"
    readonly property color warm: "#ff6f9c"
    readonly property color core: Qt.rgba(c1.r * 0.35 + 0.65, c1.g * 0.35 + 0.65, c1.b * 0.35 + 0.65, 1)
    readonly property real lv: Math.min(1, level * 1.6)
    readonly property real heat: 0.25 + 0.75 * lv
    readonly property int bandT: 50
    readonly property int bandB: 72
    readonly property real ox: rect ? rect.x - sx - border : 0
    readonly property real oy: rect ? rect.y - sy - border : 0
    readonly property real ow: rect ? rect.w + border * 2 : 0
    readonly property real oh: rect ? rect.h + border * 2 : 0
    readonly property real rad: Math.max(2, Math.min(radius, ow / 2, oh / 2))
    readonly property bool split: (oy + oh - rad - bandB) - (oy + rad + bandT) < 12
    readonly property real yTop: split ? oy + oh * 0.5 : oy + rad + bandT
    readonly property real yBot: split ? oy + oh * 0.5 : oy + oh - rad - bandB
    readonly property rect boxTop: clamp(ox - bandT, oy - bandT, ox + ow + bandT, yTop)
    readonly property rect boxBottom: clamp(ox - bandB, yBot, ox + ow + bandB, oy + oh + bandB)
    readonly property rect boxLeft: clamp(ox - bandT, yTop, ox + bandT, yBot)
    readonly property rect boxRight: clamp(ox + ow - bandT, yTop, ox + ow + bandT, yBot)
    property var sm: []
    property real t: 0
    property var segTop: [Qt.point(0, 0)]
    property var segBottom: [Qt.point(0, 0)]
    property var segLeft: [Qt.point(0, 0)]
    property var segRight: [Qt.point(0, 0)]
    property var ribbon: [Qt.point(0, 0)]
    property var haze: [Qt.point(0, 0)]

    onWantChanged: {
        fadeAnim.to = want ? 1 : 0
        fadeAnim.duration = want ? 260 : 340
        fadeAnim.restart()
        if (want) build()
    }

    NumberAnimation {
        id: fadeAnim
        target: g
        property: "fade"
        easing.type: Easing.InOutQuad
    }

    Timer {
        interval: Math.round(1000 / Math.max(10, g.fps))
        repeat: true
        running: g.live
        onTriggered: g.tick()
    }

    function clamp(x0, y0, x1, y1) {
        var a = Math.max(0, Math.floor(x0))
        var b = Math.max(0, Math.floor(y0))
        var c = Math.min(sw, Math.ceil(x1))
        var d = Math.min(sh, Math.ceil(y1))
        return Qt.rect(a, b, Math.max(0, c - a), Math.max(0, d - b))
    }

    function band(f) {
        var n = sm.length
        if (!n) return 0
        var p = Math.max(0, Math.min(n - 1, f * (n - 1)))
        var i = Math.floor(p)
        var k = p - i
        return sm[i] * (1 - k) + sm[Math.min(n - 1, i + 1)] * k
    }

    function soft(f) {
        return band(Math.max(0, f - 0.1)) * 0.25 + band(f) * 0.5 + band(Math.min(1, f + 0.1)) * 0.25
    }

    function wave(f, speed, phase) {
        f = Math.sqrt(f * f + 0.0036) - 0.06
        var cyc = Math.max(2, ow / 2 / 96)
        return Math.sin(6.2832 * f * cyc - t * speed + phase) * 0.9 + Math.sin(6.2832 * f * cyc * 0.5 + t * speed * 0.4 + phase) * 0.1
    }

    function tick() {
        var b = bars || []
        var s = sm.length === b.length ? sm.slice() : b.map(function() { return 0 })
        for (var i = 0; i < b.length; i++) s[i] += (b[i] - s[i]) * (b[i] > s[i] ? 0.28 : 0.1)
        sm = s
        t += 1 / Math.max(10, fps)
        build()
    }

    function amp() {
        return 3 + 9 * lv
    }

    function side(y, ph) {
        var u = (y - oy) / oh
        return Math.sin(Math.PI * u) * amp() * 0.1 * band(0.55) * Math.sin(6.2832 * u * Math.max(2, oh / 140) - t * 4 + ph)
    }

    function vrun(out, xb, sgn, ya, yb, ph) {
        var n = Math.max(1, Math.ceil(Math.abs(yb - ya) / 24))
        for (var i = 0; i <= n; i++) {
            var y = ya + (yb - ya) * i / n
            out.push(Qt.point(xb + sgn * side(y, ph), y))
        }
    }

    function arc(out, cx, cy, a0) {
        for (var i = 0; i <= 5; i++) {
            var a = a0 + i * Math.PI / 10
            out.push(Qt.point(cx + rad * Math.cos(a), cy + rad * Math.sin(a)))
        }
    }

    function build() {
        if (!rect || ow < 40 || oh < 40) return
        var A = amp()
        var top = []
        var bot = []
        var line = []
        var lft = []
        var rgt = []
        var x, u, f, e, d

        vrun(top, ox, -1, yTop + 8, oy + rad, 1.3)
        arc(top, ox + rad, oy + rad, Math.PI)
        for (x = ox + rad; x <= ox + ow - rad; x += 8) {
            u = (x - ox) / ow
            f = Math.abs(u - 0.5) * 2
            e = Math.pow(Math.sin(Math.PI * u), 1.3)
            d = e * A * 0.3 * soft(1 - f) * wave(f, 3, 1.7)
            top.push(Qt.point(x, oy - d))
        }
        arc(top, ox + ow - rad, oy + rad, -Math.PI / 2)
        vrun(top, ox + ow, 1, oy + rad, yTop + 8, 0)

        vrun(bot, ox + ow, 1, yBot - 8, oy + oh - rad, 0)
        arc(bot, ox + ow - rad, oy + oh - rad, 0)
        for (x = ox + ow - rad; x >= ox + rad; x -= 4) {
            u = (x - ox) / ow
            f = Math.abs(u - 0.5) * 2
            e = Math.pow(Math.sin(Math.PI * u), 1.6)
            d = e * A * (0.1 + 0.8 * soft(f)) * wave(f, 4.5, 0)
            var p = Qt.point(x, oy + oh + d)
            bot.push(p)
            line.push(p)
        }
        arc(bot, ox + rad, oy + oh - rad, Math.PI / 2)
        vrun(bot, ox, -1, oy + oh - rad, yBot - 8, 1.3)

        if (!split) {
            vrun(rgt, ox + ow, 1, yTop - 8, yBot + 8, 0)
            vrun(lft, ox, -1, yBot + 8, yTop - 8, 1.3)
            segLeft = lft
            segRight = rgt
        }
        segTop = top
        segBottom = bot
        ribbon = strip(line, 1.6 + 1.6 * lv)
        haze = strip(line, 4 + 5 * lv)
    }

    function strip(line, w) {
        var up = []
        var dn = []
        var n = line.length
        if (n < 2) return [Qt.point(0, 0)]
        for (var i = 0; i < n; i++) {
            var p0 = line[Math.max(0, i - 1)]
            var p1 = line[Math.min(n - 1, i + 1)]
            var dx = p1.x - p0.x
            var dy = p1.y - p0.y
            var l = Math.sqrt(dx * dx + dy * dy) || 1
            up.push(Qt.point(line[i].x - dy / l * w, line[i].y + dx / l * w))
            dn.push(Qt.point(line[i].x + dy / l * w, line[i].y - dx / l * w))
        }
        return up.concat(dn.reverse()).concat([up[0]])
    }

    GlowStrip { glow: g; box: g.boxTop; pts: g.segTop }
    GlowStrip { glow: g; box: g.boxBottom; pts: g.segBottom; warmth: true }
    GlowStrip { glow: g; box: g.boxLeft; pts: g.segLeft; on: !g.split }
    GlowStrip { glow: g; box: g.boxRight; pts: g.segRight; on: !g.split }
}
