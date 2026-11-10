import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "Pal.js" as Pal

ShellRoot {
    id: shell
    readonly property string home: Quickshell.env("HOME")
    readonly property string aero: home + "/.config/hyper-aero"
    readonly property string scripts: aero + "/scripts"
    readonly property string run: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    property var settings: ({})
    property var profile: ({})
    property string accent: "blue"
    property bool night: false
    readonly property var pal: Pal.make(night, accent)
    readonly property bool lite: profile.name === "ligero"
    readonly property int fps: Math.max(0, profile.fx_fps === undefined ? (lite ? 0 : 24) : profile.fx_fps)
    readonly property bool glowOn: settings["fx.glow"] !== false && fps > 0
    readonly property bool rippleOn: settings["fx.ripple"] !== false
    readonly property bool cornerOn: settings["fx.peek"] !== false
    readonly property bool playing: anyPlaying(Mpris.players.values)
    readonly property bool listening: glowOn && playing
    property var bars: []
    property real level: 0
    property var win: null
    property bool moving: false
    property int cur: 0
    property bool saver: false
    readonly property bool glowShown: listening && level > 0.015 && !!win && !peeking && !fullscreen && !saver
    property int rounding: 10
    property int border: 2
    property bool peeking: false
    property bool fullscreen: false
    property var peekWins: []
    property var clickSeq: -1
    signal ripple(real x, real y)

    function anyPlaying(list) {
        for (var i = 0; i < list.length; i++) {
            if (list[i] && list[i].isPlaying) return true
        }
        return false
    }

    function readJson(text, fallback) {
        try {
            return JSON.parse(text) || fallback
        } catch (err) {
            return fallback
        }
    }

    function hypr(code) {
        Quickshell.execDetached(["hyprctl", "eval", code])
    }

    FileView {
        path: shell.aero + "/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.settings = shell.readJson(text(), {})
        onLoadFailed: shell.settings = {}
    }

    FileView {
        path: shell.aero + "/profile.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.profile = shell.readJson(text(), {})
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

    FileView {
        path: shell.run + "/aero-click"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var p = text().trim().split(/\s+/)
            if (p.length < 3) return
            if (shell.clickSeq !== -1 && p[2] !== shell.clickSeq && shell.rippleOn) shell.ripple(Number(p[0]), Number(p[1]))
            shell.clickSeq = p[2]
        }
    }

    FileView {
        path: shell.run + "/aero-peek"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            shell.peeking = text().trim() === "1"
            if (shell.peeking && !clientsProc.running) clientsProc.running = true
        }
    }

    Component.onCompleted: fsCheck.restart()

    FileView {
        id: saverFlag
        path: shell.run + "/aero-saver.on"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.saver = true
        onLoadFailed: shell.saver = false
    }

    Timer {
        id: saverRecheck
        interval: 700
        onTriggered: saverFlag.reload()
    }

    QtObject {
        id: slotA
        property var rect: null
        property string addr: ""
    }

    QtObject {
        id: slotB
        property var rect: null
        property string addr: ""
    }

    function place(w) {
        if (!w) {
            shell.win = null
            return
        }
        var c = shell.cur === 0 ? slotA : slotB
        if (c.addr === w.addr) {
            var p = c.rect
            if (p && Math.abs(p.x - w.x) + Math.abs(p.y - w.y) + Math.abs(p.w - w.w) + Math.abs(p.h - w.h) > 1) {
                shell.moving = true
                moveHold.restart()
            }
            if (!p || p.x !== w.x || p.y !== w.y || p.w !== w.w || p.h !== w.h) c.rect = w
        } else {
            var o = shell.cur === 0 ? slotB : slotA
            o.rect = w
            o.addr = w.addr
            shell.cur = 1 - shell.cur
        }
        shell.win = w
    }

    Timer {
        id: moveHold
        interval: 1200
        onTriggered: shell.moving = false
    }

    Timer {
        id: winKick
        interval: 40
        onTriggered: if (!winProc.running) winProc.running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            var n = ev.name
            if (n === "openlayer" || n === "closelayer") {
                saverFlag.reload()
                saverRecheck.restart()
            }
            if (n === "fullscreen") shell.fullscreen = String(ev.data).trim() === "1"
            else if (n === "activewindowv2" || n === "workspacev2" || n === "closewindow" || n === "focusedmonv2") fsCheck.restart()
            if (shell.listening && (n === "activewindowv2" || n === "movewindowv2" || n === "workspacev2" || n === "focusedmonv2" || n === "openwindow" || n === "closewindow" || n === "changefloatingmode" || n === "fullscreen")) winKick.restart()
        }
    }

    Timer {
        id: fsCheck
        interval: 120
        onTriggered: if (!fsProc.running) fsProc.running = true
    }

    Process {
        id: fsProc
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: {
                var d = shell.readJson(text, null)
                shell.fullscreen = !!(d && d.fullscreen > 0)
            }
        }
    }

    Process {
        id: optProc
        running: true
        command: ["sh", "-c", "hyprctl -j getoption decoration:rounding; hyprctl -j getoption general:border_size"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.split(/\n(?=\{)/)
                for (var i = 0; i < parts.length; i++) {
                    var d = shell.readJson(parts[i], null)
                    if (!d) continue
                    var v = d.int !== undefined ? d.int : d.value
                    if (String(d.option || "").indexOf("rounding") >= 0 && v !== undefined) shell.rounding = v
                    if (String(d.option || "").indexOf("border") >= 0 && v !== undefined) shell.border = v
                }
            }
        }
    }

    Process {
        id: cava
        running: shell.listening
        command: ["sh", "-c", "sed \"s/^framerate = .*/framerate = " + Math.max(10, shell.fps) + "/\" \"$1\" > \"$2\" && exec cava -p \"$2\"", "sh", shell.aero + "/cava-fx.conf", shell.run + "/aero-cava-fx.conf"]
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(";")
                var out = []
                var sum = 0
                for (var i = 0; i < parts.length; i++) {
                    if (!parts[i].length) continue
                    var v = Math.min(1, Number(parts[i]) / 100)
                    out.push(v)
                    sum += v
                }
                shell.bars = out
                var lv = out.length ? sum / out.length : 0
                shell.level = shell.level * 0.6 + lv * 0.4
            }
        }
        onRunningChanged: if (!running) {
            shell.bars = []
            shell.level = 0
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: shell.listening && !cava.running
        onTriggered: cava.running = true
    }

    Process {
        id: winProc
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: {
                var d = shell.readJson(text, null)
                if (!d || !d.address || !d.at || !d.size || d.fullscreen > 0 || (d.workspace && d.workspace.id < 0)) {
                    shell.place(null)
                    return
                }
                shell.place({ x: d.at[0], y: d.at[1], w: d.size[0], h: d.size[1], addr: d.address })
            }
        }
    }

    Timer {
        interval: shell.moving ? 50 : 450
        repeat: true
        running: shell.listening
        triggeredOnStart: true
        onTriggered: if (!winProc.running) winProc.running = true
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                var list = shell.readJson(text, [])
                var mons = Hyprland.monitors.values
                var vis = {}
                for (var i = 0; i < mons.length; i++) {
                    if (mons[i] && mons[i].activeWorkspace) vis[mons[i].activeWorkspace.id] = true
                }
                shell.peekWins = list.filter(function(c) {
                    return c.mapped && !c.hidden && c.workspace && vis[c.workspace.id]
                }).map(function(c) {
                    return { x: c.at[0], y: c.at[1], w: c.size[0], h: c.size[1], title: c.title || c.class || "" }
                })
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property var modelData

            PanelWindow {
                id: layer
                screen: scope.modelData
                visible: (shell.rippleOn || shell.peeking) && !shell.fullscreen && !shell.saver
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "aerofx"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                mask: Region {}
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                readonly property real sx: scope.modelData.x
                readonly property real sy: scope.modelData.y

                Ripples {
                    id: ripples
                    anchors.fill: parent
                    pal: shell.pal
                }

                PeekOutlines {
                    anchors.fill: parent
                    active: shell.peeking
                    wins: shell.peekWins
                    ox: layer.sx
                    oy: layer.sy
                    pal: shell.pal
                }

                Connections {
                    target: shell
                    function onRipple(x, y) {
                        var lx = x - layer.sx
                        var ly = y - layer.sy
                        if (lx >= 0 && ly >= 0 && lx < layer.width && ly < layer.height) ripples.spawn(lx, ly)
                    }
                }
            }

            Glow {
                screen: scope.modelData
                rect: slotA.rect
                on: shell.glowShown && shell.cur === 0
                bars: shell.bars
                level: shell.level
                radius: shell.rounding + shell.border
                border: shell.border
                pal: shell.pal
                fps: shell.fps
            }

            Glow {
                screen: scope.modelData
                rect: slotB.rect
                on: shell.glowShown && shell.cur === 1
                bars: shell.bars
                level: shell.level
                radius: shell.rounding + shell.border
                border: shell.border
                pal: shell.pal
                fps: shell.fps
            }

            PanelWindow {
                id: corner
                screen: scope.modelData
                visible: shell.cornerOn && !shell.fullscreen && !shell.saver
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "aerofx-corner"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                implicitWidth: 4
                implicitHeight: 4
                anchors {
                    bottom: true
                    right: true
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: hoverWait.restart()
                    onExited: {
                        hoverWait.stop()
                        shell.hypr("aero_fx.peek(false)")
                    }
                    onClicked: {
                        hoverWait.stop()
                        shell.hypr("aero_fx.peek(false)")
                        shell.hypr("aero_fx.show_desktop()")
                    }
                }

                Timer {
                    id: hoverWait
                    interval: 420
                    onTriggered: shell.hypr("aero_fx.peek(true)")
                }
            }
        }
    }

    Radial {
        id: radialWin
        pal: shell.pal
        night: shell.night
        scripts: shell.scripts
        playing: shell.playing
    }

    Flip {
        id: flipWin
        pal: shell.pal
        night: shell.night
        run: shell.run
    }

    IpcHandler {
        target: "fx"

        function radial(): void {
            if (radialWin.open) radialWin.close()
            else radialWin.show()
        }

        function flip(): void {
            if (flipWin.open) flipWin.next()
            else flipWin.show()
        }

        function ripple(x: real, y: real): void {
            shell.ripple(x, y)
        }

        function reload(): void {
            optProc.running = true
        }
    }
}
