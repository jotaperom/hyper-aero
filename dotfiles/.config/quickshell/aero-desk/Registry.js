.pragma library

var LIST = [
    { id: "chrono", name: "CHRONO", desc: "Reloj y fecha", glyph: "\u{F0150}", file: "WChrono.qml", minW: 4, minH: 2, w: 8, h: 4 },
    { id: "pulsex", name: "PULSE-X", desc: "Reproductor", glyph: "\u{F0386}", file: "WPulse.qml", minW: 7, minH: 3, w: 10, h: 4 },
    { id: "sky", name: "SKY ARC", desc: "Sol y luna", glyph: "\u{F059A}", file: "WSky.qml", minW: 5, minH: 3, w: 8, h: 5 },
    { id: "atmos", name: "ATMOS", desc: "Clima", glyph: "\u{F0595}", file: "WAtmos.qml", minW: 4, minH: 3, w: 6, h: 5 },
    { id: "system", name: "SYSTEM", desc: "CPU, RAM, disco", glyph: "\u{F061A}", file: "WSystem.qml", minW: 4, minH: 4, w: 6, h: 4 },
    { id: "tasks", name: "TASKS", desc: "Pendientes", glyph: "\u{F0135}", file: "WTasks.qml", minW: 5, minH: 4, w: 6, h: 6 },
    { id: "calendar", name: "CALENDAR", desc: "Mes actual", glyph: "\u{F0E17}", file: "WCalendar.qml", minW: 4, minH: 4, w: 6, h: 6 },
    { id: "notes", name: "NOTES", desc: "Nota rápida", glyph: "\u{F11D7}", file: "WNotes.qml", minW: 4, minH: 3, w: 5, h: 5 },
    { id: "visual", name: "SPECTRA", desc: "Visualizador", glyph: "\u{F0EA2}", file: "WVisual.qml", minW: 4, minH: 2, w: 8, h: 3 },
    { id: "user", name: "PILOT", desc: "Tu tarjeta", glyph: "\u{F0009}", file: "WUser.qml", minW: 5, minH: 3, w: 6, h: 3 },
    { id: "launcher", name: "DOCK", desc: "Tus apps", glyph: "\u{F003B}", file: "WLauncher.qml", minW: 3, minH: 2, w: 6, h: 2 },
    { id: "lyrics", name: "LYRICS", desc: "Letra en vivo", glyph: "\u{F036C}", file: "WLyrics.qml", minW: 5, minH: 4, w: 7, h: 6 },
    { id: "gif", name: "GIF", desc: "Imagen animada", glyph: "\u{F0D78}", file: "WGif.qml", minW: 3, minH: 3, w: 5, h: 5 }
]

function find(id) {
    for (var i = 0; i < LIST.length; i++) {
        if (LIST[i].id === id) return LIST[i]
    }
    return null
}

function defaults(cols, rows) {
    var r = Math.max(rows, 12)
    var c = Math.max(cols, 24)
    return [
        { id: "chrono", c: 0, r: 0, w: 8, h: 4 },
        { id: "pulsex", c: 0, r: 4, w: 10, h: 4 },
        { id: "sky", c: 0, r: r - 5, w: 8, h: 5 },
        { id: "atmos", c: c - 6, r: r - 5, w: 6, h: 5 }
    ]
}
