import QtQuick
import Quickshell
import Quickshell.Io
import "Lang.js" as L
import "Pal.js" as Pal

ShellRoot {
    id: shell
    readonly property string home: Quickshell.env("HOME")
    readonly property string aero: home + "/.config/hyper-aero"
    property string mode: Quickshell.env("AERO_CONTROL_MODE") === "welcome" ? "welcome" : "panel"
    property string accent: "blue"
    property bool night: false
    readonly property var pal: Pal.make(night, accent)

    QtObject {
        id: api
        readonly property string scripts: shell.aero + "/scripts"
        property var st: ({})
        property string toast: ""
        property var pendingDetect: null

        function path(cmd) {
            return cmd.indexOf("/") === 0 ? cmd : scripts + "/" + cmd
        }

        function exec(args, refresh) {
            var a = args.slice()
            a[0] = path(a[0])
            Quickshell.execDetached(a)
            if (refresh) again.restart()
        }

        function raw(args) {
            Quickshell.execDetached(args)
        }

        function setting(key, val) {
            var s = Object.assign({}, st.settings || {})
            s[key] = val
            st = Object.assign({}, st, { settings: s })
            exec(["aero-control.py", "set", key, val ? "true" : "false"], true)
        }

        function refresh() {
            if (!stateProc.running) stateProc.running = true
        }

        function detect(cb) {
            pendingDetect = cb
            say(L.t("Buscando tu ubicación…"))
            detectProc.running = true
        }

        function say(msg) {
            toast = msg
            toastTimer.restart()
        }

        function welcome() {
            shell.mode = "welcome"
            win.visible = true
        }
    }

    Timer {
        id: again
        interval: 900
        onTriggered: api.refresh()
    }

    Timer {
        id: toastTimer
        interval: 3200
        onTriggered: api.toast = ""
    }

    Timer {
        interval: 6000
        repeat: true
        running: win.visible
        onTriggered: api.refresh()
    }

    Process {
        id: stateProc
        running: true
        command: [api.scripts + "/aero-control.py", "state"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    api.st = JSON.parse(text)
                } catch (err) {
                }
            }
        }
    }

    Process {
        id: detectProc
        command: [api.scripts + "/aero-control.py", "detect"]
        stdout: StdioCollector {
            onStreamFinished: {
                var d = {}
                try {
                    d = JSON.parse(text)
                } catch (err) {
                }
                if (d.ok && api.pendingDetect) {
                    api.pendingDetect(d)
                    api.say(L.f("Encontré: %1", d.city || (d.lat + ", " + d.lon)))
                } else {
                    api.say(L.t("No pude detectarla; escribila a mano."))
                }
                api.pendingDetect = null
            }
        }
    }

    FileView {
        path: shell.aero + "/theme/accent"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.accent = text().trim() || "blue"
    }

    FileView {
        path: shell.aero + "/theme/mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.night = text().trim() === "night"
    }

    FloatingWindow {
        id: win
        title: shell.mode === "welcome" ? L.t("Bienvenido a HYPER·AERO") : L.t("Panel de control")
        implicitWidth: 1060
        implicitHeight: 700
        color: shell.night ? "#0b1530" : "#eaf3fc"
        visible: true
        onVisibleChanged: if (!visible) Qt.quit()

        ControlView {
            anchors.fill: parent
            visible: shell.mode === "panel"
            pal: shell.pal
            api: api
        }

        Welcome {
            anchors.fill: parent
            visible: shell.mode === "welcome"
            pal: shell.pal
            api: api
            onFinished: {
                api.exec(["aero-control.py", "welcome"], false)
                win.visible = false
            }
        }
    }

    IpcHandler {
        target: "control"

        function show(): void {
            shell.mode = "panel"
            win.visible = true
            api.refresh()
        }

        function welcome(): void {
            api.welcome()
        }
    }
}
