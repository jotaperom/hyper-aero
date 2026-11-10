.pragma library
.import "Tint.js" as Tint

var DAY = {
    card0: "#e0ffffff", card1: "#bdf5f8fb", card2: "#a3e3eef9", card3: "#b8eaf1f8",
    cardBorder: "#b80b0d12", sheen: "#f2ffffff", shadow: "#260b1a3a",
    ink: "#0b0d12", muted: "#5a6270", dim: "#9aa3ae", sep: "#735a6270",
    accent: "#1446c2", blue: "#1e6fd9", sky: "#3d9be9", glow: "#3d9be9",
    ok: "#0f7b5a", warn: "#a8650a", bad: "#c4283b",
    track: "#330b0d12", fill0: "#8cc6f5", fill1: "#3d9be9", fill2: "#1446c2",
    field: "#b3ffffff", fieldBorder: "#590b0d12", hover: "#243d9be9",
    btn0: "#ffffff", btn1: "#eef5fd", btn2: "#cfe2f6", btn3: "#f2f8fe", btnBorder: "#8c0b308c", btnText: "#1446c2",
    shell0: "#7fbdf3", shell1: "#3d9be9", shell2: "#1e6fd9", shell3: "#1446c2", shell4: "#0d3aa6",
    shellRim: "#f2ffffff", shellRing: "#f2c6d0db",
    lcd0: "#0b2f8a", lcd1: "#1446c2", lcd2: "#0a2a7a", lcdRim: "#f2d6e6f8", lcdText: "#cfeaff",
    grid: "#401446c2", gridDot: "#8c1446c2", scrim: "#1f0b2a66", select: "#3d9be9", ghost: "#403d9be9",
    tray0: "#f2ffffff", tray1: "#e6eef5fc", tray2: "#d9dfeaf6", tray3: "#eaf1f8ff", trayBorder: "#b80b0d12"
}

var NIGHT = {
    card0: "#db20345c", card1: "#c7121e38", card2: "#b80a1224", card3: "#c70e182e",
    cardBorder: "#596fd3ff", sheen: "#47a0dcff", shadow: "#66000000",
    ink: "#e6eefb", muted: "#8b97ab", dim: "#4a5a78", sep: "#406fd3ff",
    accent: "#6fd3ff", blue: "#3d9be9", sky: "#6fd3ff", glow: "#6fd3ff",
    ok: "#3ddc97", warn: "#f0b44c", bad: "#ff5d6c",
    track: "#66000000", fill0: "#6fd3ff", fill1: "#3d9be9", fill2: "#1e6fd9",
    field: "#99070c18", fieldBorder: "#596fd3ff", hover: "#293d9be9",
    btn0: "#38558a", btn1: "#263d6c", btn2: "#1b2e5a", btn3: "#233a66", btnBorder: "#666fd3ff", btnText: "#6fd3ff",
    shell0: "#2f6fb8", shell1: "#1e55a8", shell2: "#163f8a", shell3: "#0f2c6a", shell4: "#0a1f4e",
    shellRim: "#8c96c8f5", shellRing: "#f22a3a5c",
    lcd0: "#06163f", lcd1: "#0b2a6e", lcd2: "#051236", lcdRim: "#736fd3ff", lcdText: "#cfeaff",
    grid: "#336fd3ff", gridDot: "#806fd3ff", scrim: "#33020610", select: "#6fd3ff", ghost: "#336fd3ff",
    tray0: "#f2263c68", tray1: "#e6152442", tray2: "#e00c1530", tray3: "#e6142240", trayBorder: "#806fd3ff"
}

function make(night, accent) {
    return Tint.palette(night ? NIGHT : DAY, accent || "blue")
}
