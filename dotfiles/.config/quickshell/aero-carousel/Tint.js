.pragma library

var PARAMS = {
    red: { hue: 350, spread: 0.85, sat: 1.0 },
    green: { hue: 162, spread: 0.8, sat: 0.72 },
    black: { mono: true, glow: 188 }
}

var SWATCH = {
    blue: ["#8cc6f5", "#3d9be9", "#1446c2", "#1e6fd9"],
    red: ["#f6a3b7", "#e8406a", "#a51119", "#dd1f41"],
    green: ["#8fdcbf", "#2ea977", "#1a5e48", "#268063"],
    black: ["#e4e6ea", "#9a9ea6", "#3c3f45", "#6b6f77"]
}

function parseCustom(acc) {
    var m = /^c-(\d{1,3})-(\d{1,3})$/.exec(String(acc || ""))
    if (!m) return null
    var hue = Math.max(0, Math.min(359, parseInt(m[1], 10)))
    var sat = Math.max(0, Math.min(140, parseInt(m[2], 10))) / 100
    if (sat < 0.12) return { mono: true, glow: hue }
    return { hue: hue, spread: 0.85, sat: sat }
}

function params(acc) {
    return PARAMS[acc] || parseCustom(acc)
}

function isCustom(acc) {
    return parseCustom(acc) !== null
}

function nearestPreset(acc) {
    if (PARAMS[acc] || acc === "blue") return acc
    var p = parseCustom(acc)
    if (!p) return "blue"
    if (p.mono) return "black"
    var h = p.hue
    if (h >= 300 || h < 35) return "red"
    if (h >= 80 && h < 185) return "green"
    return "blue"
}

function swatch(acc) {
    if (SWATCH[acc]) return SWATCH[acc]
    var out = []
    for (var i = 0; i < SWATCH.blue.length; i++) out.push(color(SWATCH.blue[i], acc))
    return out
}

function rgbToHls(r, g, b) {
    var mx = Math.max(r, g, b), mn = Math.min(r, g, b)
    var l = (mx + mn) / 2
    if (mx === mn) return [0, l, 0]
    var d = mx - mn
    var s = l <= 0.5 ? d / (mx + mn) : d / (2 - mx - mn)
    var h
    if (mx === r) h = ((g - b) / d) % 6
    else if (mx === g) h = (b - r) / d + 2
    else h = (r - g) / d + 4
    h = h / 6
    if (h < 0) h += 1
    return [h, l, s]
}

function hue2(m1, m2, h) {
    h = ((h % 1) + 1) % 1
    if (h < 1 / 6) return m1 + (m2 - m1) * h * 6
    if (h < 0.5) return m2
    if (h < 2 / 3) return m1 + (m2 - m1) * (2 / 3 - h) * 6
    return m1
}

function hlsToRgb(h, l, s) {
    if (s === 0) return [l, l, l]
    var m2 = l <= 0.5 ? l * (1 + s) : l + s - l * s
    var m1 = 2 * l - m2
    return [hue2(m1, m2, h + 1 / 3), hue2(m1, m2, h), hue2(m1, m2, h - 1 / 3)]
}

function lum(r, g, b) {
    function ch(c) { return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)
}

function tintRgb(r, g, b, acc) {
    var p = params(acc)
    if (!p) return [r, g, b]
    var hls = rgbToHls(r / 255, g / 255, b / 255)
    var deg = hls[0] * 360, l = hls[1], s = hls[2]
    if (s < 0.035 || deg < 180 || deg > 246) return [r, g, b]
    if (p.mono) {
        if (s > 0.88 && l > 0.55) { deg = p.glow; s = s * 0.85 }
        else s = s * 0.07
    } else {
        deg = ((p.hue + (deg - 215) * p.spread) % 360 + 360) % 360
        s = s * p.sat
        if (l > 0.88 || l < 0.12) s *= 0.6
    }
    s = Math.min(1, Math.max(0, s))
    var target = lum(r / 255, g / 255, b / 255)
    var lo = 0, hi = 1
    for (var i = 0; i < 22; i++) {
        var mid = (lo + hi) / 2
        var c = hlsToRgb(deg / 360, mid, s)
        if (lum(c[0], c[1], c[2]) < target) lo = mid
        else hi = mid
    }
    var o = hlsToRgb(deg / 360, (lo + hi) / 2, s)
    return [Math.round(o[0] * 255), Math.round(o[1] * 255), Math.round(o[2] * 255)]
}

function hx(n) {
    var t = Math.max(0, Math.min(255, n)).toString(16)
    return t.length < 2 ? "0" + t : t
}

function color(v, acc) {
    if (!acc || acc === "blue" || typeof v !== "string" || v.charAt(0) !== "#") return v
    var h = v.slice(1), a = ""
    if (h.length === 8) { a = h.slice(0, 2); h = h.slice(2) }
    if (h.length !== 6) return v
    var c = tintRgb(parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16), acc)
    return "#" + a + hx(c[0]) + hx(c[1]) + hx(c[2])
}

function palette(pal, acc) {
    if (!acc || acc === "blue") return pal
    var out = {}
    for (var k in pal) out[k] = color(pal[k], acc)
    return out
}
