import QtQuick
import Quickshell
import Quickshell.Io
import "Lang.js" as L

ShellRoot {
    id: shell
    readonly property string aero: Quickshell.env("HOME") + "/.config/hyper-aero"
    readonly property string tool: aero + "/scripts/aero-studio.py"

    QtObject {
        id: api
        property string accent: "blue"
        property string mode: "day"
        property string wallpaper: "auto"
        property var walls: []
        property var themes: []
        property string autoDay: ""
        property string autoNight: ""
        property var autos: ({})
        property string pendingApply: ""
        property string lastRendered: ""
        property string busy: ""
        property real progress: 0
        property string previewDay: ""
        property string previewNight: ""
        property var suggest: []
        property string image: ""
        property string toast: ""
        property bool previewing: false
        property string eta: ""
        property string renderName: ""
        property real renderStart: 0
        property string lastErr: ""
        property var pendingPreview: null

        function run(kind, args) {
            if (job.running) return
            busy = kind
            progress = 0
            eta = ""
            lastErr = ""
            if (kind === "render") {
                renderStart = Date.now()
                var parts = String(image).split("/").pop().replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ").trim()
                renderName = parts.length ? parts.charAt(0).toUpperCase() + parts.slice(1, 28) : L.t("Fondo")
            }
            job.command = [shell.tool].concat(args)
            job.running = true
        }

        function startPreview() {
            if (!pendingPreview) return
            previewing = true
            previewProc.command = [shell.tool, "preview", JSON.stringify(pendingPreview)]
            pendingPreview = null
            previewProc.running = true
        }

        function quiet(args) {
            Quickshell.execDetached([shell.tool].concat(args))
            refreshSoon.restart()
        }

        function say(t) {
            toast = t
            toastTimer.restart()
        }

        function apply(acc, wall) { run("apply", ["apply", acc, wall]) }
        function pickImage() { run("pick", ["pick"]) }
        function preview(spec) {
            pendingPreview = spec
            if (!previewProc.running) startPreview()
        }
        function render(spec) {
            pendingApply = ""
            lastRendered = ""
            run("render", ["render", JSON.stringify(spec)])
        }
        function renderApply(spec, acc) {
            if (job.running) return
            lastRendered = ""
            run("render", ["render", JSON.stringify(spec)])
            pendingApply = acc
        }
        function palette(path) {
            if (paletteProc.running || !path) return
            paletteProc.command = [shell.tool, "palette", path]
            paletteProc.running = true
        }
        function saveTheme(name, acc, wall) { quiet(["save", name, acc, wall]); say(L.f("Tema «%1» guardado", name)) }
        function deleteTheme(id) { quiet(["deltheme", id]) }
        function deleteWall(id) { quiet(["delwall", id]) }
        function close() { Qt.quit() }

        function take(d) {
            if (d.progress !== undefined) {
                progress = d.progress
                if (busy === "render" && d.progress > 0.03 && d.progress < 1) {
                    var left = (Date.now() - renderStart) / 1000 * (1 - d.progress) / d.progress
                    eta = left > 90 ? L.f("faltan ~%1 min", Math.round(left / 60)) : L.f("faltan ~%1 s", Math.max(5, Math.round(left / 5) * 5))
                } else if (d.progress >= 1) {
                    eta = ""
                }
            }
            if (d.image) {
                image = d.image
                previewDay = ""
                previewNight = ""
                palette(d.image)
            }
            if (d.previewDay) {
                previewDay = d.previewDay
                previewNight = d.previewNight
            }
            if (d.suggest) suggest = d.suggest
            if (d.rendered) {
                lastRendered = d.rendered
                view.useDraft = false
                view.wall = d.rendered
            }
            if (d.toast) say(d.toast)
        }
    }

    Process {
        id: job
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    api.take(JSON.parse(line))
                } catch (err) {
                }
            }
        }
        stderr: SplitParser {
            onRead: function(line) {
                if (String(line).trim().length) api.lastErr = String(line).trim()
            }
        }
        onExited: function(code) {
            var was = api.busy
            api.busy = ""
            api.eta = ""
            if (code !== 0 && was === "render") api.say(L.t("No pude generar el fondo") + (api.lastErr ? ": " + api.lastErr.slice(0, 90) : ""))
            if (was === "render" && api.pendingApply.length) {
                var acc = api.pendingApply
                api.pendingApply = ""
                if (code === 0 && api.lastRendered.length) {
                    var made = api.lastRendered
                    applyLater.acc = acc
                    applyLater.wall = made
                    applyLater.restart()
                    return
                }
            }
            if (was === "pick" && api.image.length) return
            refresh.running = true
        }
    }

    Process {
        id: previewProc
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    api.take(JSON.parse(line))
                } catch (err) {
                }
            }
        }
        onExited: {
            api.previewing = false
            if (api.pendingPreview) api.startPreview()
        }
    }

    Process {
        id: paletteProc
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    api.take(JSON.parse(line))
                } catch (err) {
                }
            }
        }
    }

    Process {
        id: refresh
        command: [shell.tool, "state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text)
                    var first = api.walls.length === 0 && api.autoDay === ""
                    api.accent = d.accent
                    api.mode = d.mode
                    api.wallpaper = d.wallpaper
                    api.walls = d.walls
                    api.themes = d.themes
                    api.autoDay = d.autoDay
                    api.autoNight = d.autoNight
                    api.autos = d.autos || {}
                    if (first) {
                        view.work = d.accent
                        view.wall = d.wallpaper
                        view.nightView = d.mode === "night"
                        if (!api.suggest.length && d.autoDay) api.palette(d.wallpaper === "auto" ? d.autoDay : view.selWall ? view.selWall.day : d.autoDay)
                    }
                } catch (err) {
                }
            }
        }
    }

    Timer {
        id: applyLater
        property string acc: ""
        property string wall: ""
        interval: 150
        onTriggered: api.apply(acc, wall)
    }

    Timer {
        id: refreshSoon
        interval: 400
        onTriggered: refresh.running = true
    }

    Timer {
        id: toastTimer
        interval: 2600
        onTriggered: api.toast = ""
    }

    FileView {
        path: shell.aero + "/theme/accent"
        watchChanges: true
        printErrors: false
        onFileChanged: refreshSoon.restart()
    }

    FloatingWindow {
        id: win
        title: L.t("Estudio de temas")
        implicitWidth: 1320
        implicitHeight: 820
        color: "#0b1530"
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()

        StudioView {
            id: view
            anchors.fill: parent
            api: api
        }
    }

    IpcHandler {
        target: "studio"

        function show(): void {
            win.visible = true
        }
    }
}
