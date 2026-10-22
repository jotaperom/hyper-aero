import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Lang.js" as L

ShellRoot {
    id: shell
    readonly property string aero: Quickshell.env("HOME") + "/.config/hyper-aero"
    readonly property string tool: aero + "/scripts/aero-displays.py"
    readonly property string run: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    property string screenName: ""
    property bool alive: true

    function pickScreen() {
        var list = Quickshell.screens
        var want = backend.st && backend.st.primary ? backend.st.primary : ""
        var mon = Hyprland.focusedMonitor
        var i
        if (mon) {
            for (i = 0; i < list.length; i++) if (list[i].name === mon.name) return list[i]
        }
        for (i = 0; i < list.length; i++) if (list[i].name === want) return list[i]
        return list.length ? list[0] : null
    }

    function screenFor(name) {
        var list = Quickshell.screens
        for (var i = 0; i < list.length; i++) if (list[i].name === name) return list[i]
        return list.length ? list[0] : null
    }

    function present(name) {
        var list = Quickshell.screens
        for (var i = 0; i < list.length; i++) if (list[i].name === name) return true
        return false
    }

    function remount() {
        if (loader.active && screenName.length && present(screenName)) return
        var s = pickScreen()
        screenName = s ? s.name : ""
        loader.active = false
        mountTimer.restart()
    }

    QtObject {
        id: backend
        property var st: ({})
        property string busy: ""
        property string error: ""
        property bool night: false
        property string accent: "blue"
        property var queued: null

        function set(args) {
            if (job.running) {
                queued = args
                return
            }
            error = ""
            busy = args[0] === "mode" ? "mode:" + args[1] : args[0]
            job.command = [shell.tool, "set"].concat(args)
            job.running = true
        }

        function take(text) {
            try {
                var d = JSON.parse(text)
                if (d && typeof d === "object" && !d.error) st = d
                else if (d && d.error) error = d.error
            } catch (err) {
            }
        }
    }

    Process {
        id: job
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line)
                    if (d.error) backend.error = d.error
                } catch (err) {
                }
            }
        }
        onExited: function(code) {
            backend.busy = ""
            if (code !== 0 && !backend.error.length) backend.error = L.t("No pude aplicar el cambio")
            stateProc.running = true
            if (backend.queued) {
                var q = backend.queued
                backend.queued = null
                backend.set(q)
            }
        }
    }

    Process {
        id: stateProc
        command: [shell.tool, "state"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (!job.running) backend.take(this.text)
                shell.remount()
            }
        }
    }

    function poll() {
        if (!job.running && !stateProc.running) stateProc.running = true
    }

    Timer {
        interval: 1500
        repeat: true
        running: shell.alive
        onTriggered: shell.poll()
    }

    FileView {
        path: shell.run + "/aero-displays.state"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            if (!job.running) backend.take(text())
            settle.restart()
        }
    }

    FileView {
        id: accentFile
        path: shell.aero + "/theme/accent"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: backend.accent = text().trim() || "blue"
    }

    FileView {
        path: shell.aero + "/theme/mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: backend.night = text().trim() === "night"
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            settle.restart()
            shell.poll()
        }
    }

    Timer {
        id: settle
        interval: 350
        onTriggered: shell.remount()
    }

    Timer {
        id: mountTimer
        interval: 60
        onTriggered: loader.active = shell.alive
    }

    Timer {
        id: quitTimer
        interval: 30
        onTriggered: Qt.quit()
    }

    function bye() {
        alive = false
        loader.active = false
        quitTimer.restart()
    }

    LazyLoader {
        id: loader
        active: false

        PanelWindow {
            id: win
            screen: shell.screenFor(shell.screenName)
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "aero-displays"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            DisplaysView {
                id: view
                anchors.fill: parent
                api: backend
                focus: true
                onClosed: shell.bye()
            }
        }
    }

    IpcHandler {
        target: "displays"

        function toggle(): void {
            shell.bye()
        }

        function show(): void {
            shell.poll()
            shell.remount()
        }

        function next(): void {
            var order = ["laptop", "duplicate", "extend", "external"]
            if (!backend.st.external) return
            var i = order.indexOf(backend.st.mode || "extend")
            backend.set(["mode", order[(i + 1) % order.length]])
        }
    }
}
