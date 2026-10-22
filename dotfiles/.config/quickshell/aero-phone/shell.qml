import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

ShellRoot {
    id: shell
    property bool shown: false
    property bool mapped: false
    readonly property string home: Quickshell.env("HOME")
    readonly property string scripts: home + "/.config/hyper-aero/scripts"
    readonly property string usagePath: home + "/.local/state/hyper-aero/phone-usage.json"

    function openPhone(p, sub) {
        core.refresh()
        phone.openSub = sub || ""
        phone.page = p
        if (shown) phone.controlsSub(sub || "")
        mapped = true
        shown = true
    }

    function closePhone() {
        shown = false
    }

    function pickScreen() {
        var list = Quickshell.screens
        var mon = Hyprland.focusedMonitor
        for (var i = 0; i < list.length; i++) {
            if (mon && list[i].name === mon.name) return list[i]
        }
        return list.length ? list[0] : null
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Item {
        id: core
        property var st: ({ mode: "day", accent: "blue", wifi: false, ssid: "", bt: false, btAvail: true, btDev: "", warm: false, kelvin: 0, dnd: false, bri: 50, bat: -1, charging: false })
        property var usage: ({})
        property int pendingBri: -1
        property var wifi: ({ radio: false, networks: [], ip: "" })
        property string wifiBusy: ""
        property bool wifiScanning: false
        property var bt: ({ avail: true, powered: false, devices: [] })
        property string btBusy: ""
        property bool btScanning: false
        readonly property string net: shell.scripts + "/phone-net.py"
        property var weather: ({ ok: false })
        property string note: ""
        property string skin: "iphone"
        readonly property string user: {
            var u = Quickshell.env("USER") || ""
            return u.length ? u.charAt(0).toUpperCase() + u.slice(1) : ""
        }
        readonly property string notePath: shell.home + "/.config/hyper-aero/desk/notes.txt"

        function weatherRefresh() {
            job([shell.scripts + "/desk-weather.sh"], null, function(code, text) {
                var d = parse(text)
                if (d && d.ok !== undefined) weather = d
            })
        }

        function noteLoad() {
            job(["cat", notePath], null, function(code, text) { note = code === 0 ? text : "" })
        }

        function noteSave(t) {
            note = t
            job(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$AERO_NOTE" > "$1"', "sh", notePath], { "AERO_NOTE": t }, null)
        }

        function job(args, env, cb) {
            var p = jobComp.createObject(shell, { command: args, environment: env || {}, cb: cb || null })
            p.running = true
        }

        function parse(text) {
            try {
                return JSON.parse(text)
            } catch (err) {
                return { ok: false, msg: "Error inesperado" }
            }
        }

        function wifiRefresh(rescan) {
            if (rescan) wifiScanning = true
            job([net, "wifi", "list"].concat(rescan ? ["--rescan"] : []), null, function(code, text) {
                var d = parse(text)
                if (d.networks) wifi = d
                if (rescan) wifiScanning = false
            })
        }

        function wifiRadio(on) {
            wifi = Object.assign({}, wifi, { radio: on })
            patch({ wifi: on })
            job([net, "wifi", "radio", on ? "on" : "off"], null, function() {
                wifiRefresh(on)
                refreshSoon.restart()
            })
        }

        function wifiConnect(ssid, pw, cb) {
            wifiBusy = ssid
            job([net, "wifi", "connect", ssid], pw ? { "AERO_WIFI_PSK": pw } : null, function(code, text) {
                wifiBusy = ""
                var r = parse(text)
                wifiRefresh(false)
                refreshSoon.restart()
                if (cb) cb(r)
            })
        }

        function wifiDisconnect(cb) {
            job([net, "wifi", "disconnect"], null, function(code, text) {
                wifiRefresh(false)
                refreshSoon.restart()
                if (cb) cb(parse(text))
            })
        }

        function wifiForget(ssid, cb) {
            job([net, "wifi", "forget", ssid], null, function(code, text) {
                wifiRefresh(false)
                refreshSoon.restart()
                if (cb) cb(parse(text))
            })
        }

        function btRefresh() {
            job([net, "bt", "list"], null, function(code, text) {
                var d = parse(text)
                if (d.devices) bt = d
            })
        }

        function btScan() {
            if (btScanning) return
            btScanning = true
            job(["bluetoothctl", "--timeout", "12", "scan", "on"], null, function() {
                btScanning = false
                btRefresh()
            })
        }

        function btPower(on) {
            bt = Object.assign({}, bt, { powered: on })
            patch({ bt: on })
            job([net, "bt", "power", on ? "on" : "off"], null, function() {
                btRefresh()
                refreshSoon.restart()
                if (on) btScan()
            })
        }

        function btConnect(mac, cb) {
            btBusy = mac
            job([net, "bt", "connect", mac], null, function(code, text) {
                btBusy = ""
                btRefresh()
                refreshSoon.restart()
                if (cb) cb(parse(text))
            })
        }

        function btDisconnect(mac, cb) {
            btBusy = mac
            job([net, "bt", "disconnect", mac], null, function(code, text) {
                btBusy = ""
                btRefresh()
                refreshSoon.restart()
                if (cb) cb(parse(text))
            })
        }

        function btForget(mac, cb) {
            job([net, "bt", "forget", mac], null, function(code, text) {
                btRefresh()
                refreshSoon.restart()
                if (cb) cb(parse(text))
            })
        }
        readonly property var sink: Pipewire.defaultAudioSink
        readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
        readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
        readonly property var apps: buildApps(DesktopEntries.applications.values)
        readonly property var player: pickPlayer(Mpris.players.values)
        readonly property var media: player
            ? ({ has: true, title: player.trackTitle, artist: player.trackArtist, art: player.trackArtUrl, playing: player.isPlaying, app: player.identity })
            : ({ has: false })

        function buildApps(list) {
            var seen = {}
            var out = []
            for (var i = 0; i < list.length; i++) {
                var e = list[i]
                if (!e || e.noDisplay || seen[e.id]) continue
                seen[e.id] = true
                out.push({
                    key: e.id,
                    name: e.name || e.id,
                    sub: e.genericName || "",
                    kw: Array.prototype.join.call(e.keywords || [], " "),
                    comment: e.comment || "",
                    sortName: String(e.name || e.id).toLowerCase(),
                    icon: Quickshell.iconPath(e.icon, "application-x-executable")
                })
            }
            return out
        }

        function pickPlayer(list) {
            var first = null
            for (var i = 0; i < list.length; i++) {
                if (!list[i]) continue
                if (list[i].isPlaying) return list[i]
                if (!first) first = list[i]
            }
            return first
        }

        function refresh() {
            if (!statusProc.running) statusProc.running = true
        }

        function patch(obj) {
            st = Object.assign({}, st, obj)
        }

        function launch(key) {
            var e = DesktopEntries.byId(key)
            if (!e) return
            if (e.runInTerminal) Quickshell.execDetached(["kitty", "-e"].concat(Array.prototype.slice.call(e.command)))
            else e.execute()
            var u = Object.assign({}, usage)
            u[key] = (u[key] || 0) + 1
            usage = u
            usageFile.setText(JSON.stringify(u))
        }

        function act(name) {
            if (name.indexOf("accent-") === 0 && name !== "accent-next") patch({ accent: name.slice(7) })
            else if (name === "wifi") patch({ wifi: !st.wifi })
            else if (name === "bt") patch({ bt: !st.bt })
            else if (name === "dnd") patch({ dnd: !st.dnd })
            else if (name === "warm") patch({ warm: !st.warm, kelvin: st.kelvin || 4200 })
            else if (name === "night") patch({ mode: st.mode === "night" ? "day" : "night" })
            else if ((name === "rec" || name === "rec-region") && st.rec) patch({ rec: false, recSince: 0 })
            Quickshell.execDetached([shell.scripts + "/phone-act.sh", name])
            refreshSoon.restart()
        }

        function setVolume(v) {
            if (!sink || !sink.audio) return
            if (v > 0 && sink.audio.muted) sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }

        function toggleMute() {
            if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
        }

        function setBrightness(v) {
            pendingBri = Math.max(1, Math.round(v * 100))
            patch({ bri: pendingBri })
            if (!briTimer.running) briTimer.start()
        }

        function setSkin(name) {
            skin = name
            skinFile.setText(name + "\n")
        }

        function mediaCmd(c) {
            if (!player) return
            if (c === "toggle" && player.canTogglePlaying) player.togglePlaying()
            else if (c === "next" && player.canGoNext) player.next()
            else if (c === "prev" && player.canGoPrevious) player.previous()
        }

        Component.onCompleted: refresh()
    }

    Component {
        id: jobComp
        Process {
            id: jp
            property var cb: null
            property bool outDone: false
            property bool exitDone: false
            property int code: 0
            property string text: ""

            function finish() {
                if (!outDone || !exitDone) return
                var f = cb
                cb = null
                if (f) f(code, text)
                jp.destroy()
            }

            stdout: StdioCollector {
                onStreamFinished: {
                    jp.text = this.text
                    jp.outDone = true
                    jp.finish()
                }
            }
            onExited: function(exitCode, exitStatus) {
                jp.code = exitCode
                jp.exitDone = true
                jp.finish()
            }
        }
    }

    Process {
        id: statusProc
        command: [shell.scripts + "/phone-status.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text)
                    if (core.pendingBri >= 0 || briTimer.running) d.bri = core.st.bri
                    core.st = d
                } catch (err) {
                }
            }
        }
    }

    Timer {
        interval: shell.mapped ? 3000 : 20000
        repeat: true
        running: true
        onTriggered: core.refresh()
    }

    Timer {
        id: refreshSoon
        interval: 900
        onTriggered: core.refresh()
    }

    Timer {
        id: briTimer
        interval: 70
        onTriggered: {
            if (core.pendingBri < 0) return
            Quickshell.execDetached([shell.scripts + "/phone-act.sh", "bri", String(core.pendingBri)])
            core.pendingBri = -1
        }
    }

    FileView {
        id: skinFile
        path: shell.home + "/.config/hyper-aero/phone-skin"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var v = text().trim()
            if (v.length) core.skin = v
        }
    }

    FileView {
        id: usageFile
        path: shell.usagePath
        printErrors: false
        onLoaded: {
            try {
                core.usage = JSON.parse(text()) || {}
            } catch (err) {
                core.usage = {}
            }
        }
    }

    PanelWindow {
        id: win
        visible: shell.mapped
        screen: shell.pickScreen()
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "aero-phone"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Phone {
            id: phone
            anchors.fill: parent
            focus: true
            backend: core
            active: shell.shown
            onRequestClose: shell.closePhone()
            onClosed: if (!shell.shown) shell.mapped = false
        }
    }

    IpcHandler {
        target: "phone"

        function toggle(): void {
            if (shell.shown) shell.closePhone()
            else shell.openPhone(0)
        }

        function open(): void {
            shell.openPhone(0)
        }

        function controls(): void {
            if (shell.shown && phone.page === 1) shell.closePhone()
            else shell.openPhone(1)
        }

        function close(): void {
            shell.closePhone()
        }

        function wifi(): void {
            shell.openPhone(1, "wifi")
        }

        function today(): void {
            if (shell.shown && phone.page === 2) shell.closePhone()
            else shell.openPhone(2)
        }

        function assistant(): void {
            today()
        }

        function bluetooth(): void {
            shell.openPhone(1, "bt")
        }
    }
}
