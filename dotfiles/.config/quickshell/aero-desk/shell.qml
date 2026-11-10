import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "Pal.js" as Pal
import "Registry.js" as Reg

ShellRoot {
    id: shell
    readonly property string home: Quickshell.env("HOME")
    readonly property string aero: home + "/.config/hyper-aero"
    readonly property string scripts: aero + "/scripts"

    property string primaryName: ""
    property string hudScreen: ""
    readonly property var hub: core

    FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/aero-primary"
        watchChanges: true
        printErrors: false
        blockLoading: true
        onFileChanged: reload()
        onLoaded: shell.primaryName = text().trim()
    }

    FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/aero-hud.screen"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.hudScreen = text().trim()
    }

    function mainName() {
        var list = Quickshell.screens
        for (var p = 0; p < list.length; p++) {
            if (shell.primaryName.length && list[p].name === shell.primaryName) return list[p].name
        }
        return list.length ? list[0].name : ""
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Item {
        id: core
        property string mode: "day"
        property string accent: "blue"
        readonly property bool night: mode === "night"
        readonly property var pal: Pal.make(night, accent)
        property var now: new Date()
        property var sys: ({ cpu: 0, mem: 0, memUsed: 0, memTotal: 0, temp: 0, disk: 0, diskUsed: 0, diskTotal: 0, load: "0", uptime: "--:--", bat: -1, charging: false })
        property var sky: ({ ok: false })
        property var weather: ({ ok: false, place: "", icon: "", temp: "--", desc: "", hi: "--", lo: "--", hum: "--", wind: "--" })
        property var user: ({ name: "", full: "", host: "", kernel: "", face: "", pkgs: 0, uptime: "", shell: "" })
        property bool hidden: false
        property var placedMap: ({})
        property var boards: ({})
        readonly property string deskDir: shell.aero + "/desk"
        property var tasks: []
        property string notes: ""
        property var usage: ({})
        property var bars: []
        property var lyrics: ({ key: "", status: "idle", synced: false, lines: [] })
        property var settings: ({})
        property string profileName: "equilibrado"
        readonly property string weatherKind: settings["fx.weather"] === false ? "clear"
            : (typeof settings["fx.weather.demo"] === "string" && settings["fx.weather.demo"].length ? settings["fx.weather.demo"] : (weather.fx || "clear"))
        readonly property real weatherDensity: profileName === "ligero" ? 0 : (profileName === "completo" ? 1 : 0.6)
        property var gif: ({ file: "", fit: "cover", paused: false })
        readonly property var lyricPlayer: pickLyricPlayer(Mpris.players.values)
        readonly property string lyricKey: lyricPlayer && lyricPlayer.trackTitle ? (lyricPlayer.trackArtist || "") + "\u241f" + lyricPlayer.trackTitle : ""
        onLyricKeyChanged: lyricsWait.restart()
        onPlacedMapChanged: lyricsWait.restart()
        readonly property var sink: Pipewire.defaultAudioSink
        readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
        readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
        readonly property var player: pickPlayer(Mpris.players.values)
        readonly property bool playing: !!(player && player.isPlaying)
        property var pins: []
        property bool pinsSet: false
        readonly property var favorites: pinsSet ? pinnedApps(DesktopEntries.applications.values, pins) : pickFavs(DesktopEntries.applications.values, usage)

        function pinnedApps(list, keys) {
            var byId = {}
            for (var i = 0; i < list.length; i++) {
                var e = list[i]
                if (e && !byId[e.id]) byId[e.id] = { key: e.id, name: e.name || e.id, icon: Quickshell.iconPath(e.icon, "application-x-executable") }
            }
            var out = []
            for (var j = 0; j < keys.length; j++) {
                if (byId[keys[j]]) out.push(byId[keys[j]])
            }
            return out
        }

        function setPins(list) {
            var seen = {}
            var out = []
            for (var i = 0; i < list.length; i++) {
                var k = String(list[i] || "")
                if (!k.length || seen[k]) continue
                seen[k] = true
                out.push(k)
            }
            pins = out
            pinsSet = true
            pinsFile.setText(JSON.stringify({ version: 1, pins: out }, null, 2) + "\n")
        }

        function openDockPicker() {
            run([shell.scripts + "/phone.sh", "dock"])
        }

        function placed(id) {
            for (var k in placedMap) {
                if (placedMap[k].indexOf(id) >= 0) return true
            }
            return false
        }

        function setPlaced(key, list) {
            var m = Object.assign({}, placedMap)
            var ids = []
            for (var i = 0; i < list.length; i++) ids.push(list[i].id)
            if (ids.length) m[key] = ids
            else delete m[key]
            placedMap = m
        }

        function registerBoard(key, b) {
            var m = Object.assign({}, boards)
            if (b) m[key] = b
            else delete m[key]
            boards = m
        }

        function boardFor(name) {
            if (boards[name]) return boards[name]
            var main = shell.mainName()
            if (boards[main]) return boards[main]
            for (var k in boards) return boards[k]
            return null
        }

        function anyEditing() {
            for (var k in boards) {
                if (boards[k].editing) return true
            }
            return false
        }

        function setHidden(v) {
            if (hidden === v) return
            hidden = v
            stateFile.setText(JSON.stringify({ hidden: hidden }) + "\n")
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

        function isSpotify(pl) {
            var id = String((pl.identity || "") + " " + (pl.desktopEntry || "") + " " + (pl.dbusName || "")).toLowerCase()
            return id.indexOf("spotify") >= 0
        }

        function pickLyricPlayer(list) {
            var spot = null
            for (var i = 0; i < list.length; i++) {
                if (list[i] && isSpotify(list[i])) {
                    if (list[i].isPlaying) return list[i]
                    if (!spot) spot = list[i]
                }
            }
            return spot || pickPlayer(list)
        }

        function fetchLyrics() {
            if (!placed("lyrics") || !lyricKey.length) return
            if (lyrics.key === lyricKey && lyrics.status !== "offline") return
            var pl = lyricPlayer
            lyricsProc.running = false
            lyricsProc.command = [shell.scripts + "/desk-lyrics.py", pl.trackArtist || "", pl.trackTitle || "",
                                  pl.trackAlbum || "", String(pl.length > 0 ? Math.round(pl.length) : 0)]
            lyricsProc.running = true
        }

        function gifPick() {
            run([shell.scripts + "/desk-gif.sh", "pick"])
        }

        function gifSet(url) {
            run([shell.scripts + "/desk-gif.sh", "set", url])
        }

        function gifUpdate(change) {
            var next = Object.assign({}, gif, change)
            gif = next
            gifFile.setText(JSON.stringify(next) + "\n")
        }

        function pickFavs(list, use) {
            var byId = {}
            var all = []
            for (var i = 0; i < list.length; i++) {
                var e = list[i]
                if (!e || e.noDisplay || byId[e.id]) continue
                var item = { key: e.id, name: e.name || e.id, icon: Quickshell.iconPath(e.icon, "application-x-executable") }
                byId[e.id] = item
                all.push(item)
            }
            var keys = Object.keys(use || {})
            keys.sort(function(a, b) { return (use[b] || 0) - (use[a] || 0) })
            var out = []
            for (var k = 0; k < keys.length && out.length < 12; k++) {
                if (byId[keys[k]]) out.push(byId[keys[k]])
            }
            var defaults = ["kitty", "brave", "nautilus", "spotify", "vesktop", "code", "obsidian", "steam"]
            for (var d = 0; d < defaults.length && out.length < 12; d++) {
                for (var j = 0; j < all.length; j++) {
                    if (all[j].key.toLowerCase().indexOf(defaults[d]) >= 0 && out.indexOf(all[j]) < 0) {
                        out.push(all[j])
                        break
                    }
                }
            }
            return out
        }

        function launch(key) {
            var e = DesktopEntries.byId(key)
            if (!e) return
            if (e.runInTerminal) Quickshell.execDetached(["kitty", "-e"].concat(Array.prototype.slice.call(e.command)))
            else e.execute()
        }

        function media(c) {
            if (!player) return
            if (c === "toggle" && player.canTogglePlaying) player.togglePlaying()
            else if (c === "next" && player.canGoNext) player.next()
            else if (c === "prev" && player.canGoPrevious) player.previous()
        }

        function nudgeVolume(d) {
            if (!sink || !sink.audio) return
            if (sink.audio.muted) sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + d))
        }

        function run(args) {
            Quickshell.execDetached(args)
        }

        function nightToggle() {
            run([shell.scripts + "/night-deck.py", "toggle"])
        }

        function openThemes() {
            run([shell.scripts + "/carousel.sh"])
        }

        function accentNext() {
            run([shell.scripts + "/night-deck.py", "accent", "next"])
        }

        function openStudio() {
            run([shell.scripts + "/studio.sh"])
        }

        function parseTasks(text) {
            var out = []
            var lines = String(text || "").split("\n")
            for (var i = 0; i < lines.length; i++) {
                var m = /^- \[([ xX])\] (.*)$/.exec(lines[i])
                if (m) out.push({ line: i, done: m[1] !== " ", text: m[2] })
            }
            return out
        }

        function writeTasks(fn) {
            var lines = String(taskFile.text() || "").split("\n")
            fn(lines)
            var t = lines.join("\n")
            taskFile.setText(t)
            tasks = parseTasks(t)
        }

        function taskToggle(line) {
            writeTasks(function(lines) {
                var l = lines[line] || ""
                if (/^- \[ \] /.test(l)) lines[line] = l.replace(/^- \[ \] /, "- [x] ")
                else lines[line] = l.replace(/^- \[[xX]\] /, "- [ ] ")
            })
        }

        function taskAdd(text) {
            var t = String(text || "").replace(/\n/g, " ").trim()
            if (!t.length) return
            writeTasks(function(lines) {
                while (lines.length && lines[lines.length - 1] === "") lines.pop()
                lines.push("- [ ] " + t)
                lines.push("")
            })
        }

        function taskClear() {
            writeTasks(function(lines) {
                for (var i = lines.length - 1; i >= 0; i--) {
                    if (/^- \[[xX]\] /.test(lines[i])) lines.splice(i, 1)
                }
            })
        }

        function saveNotes(t) {
            notes = t
            notesSave.restart()
        }

        function sanitize(list) {
            var out = []
            var seen = {}
            for (var i = 0; i < list.length; i++) {
                var w = list[i]
                var reg = Reg.find(w.id)
                if (!reg || seen[w.id]) continue
                seen[w.id] = true
                out.push({ id: w.id, c: Math.max(0, w.c | 0), r: Math.max(0, w.r | 0),
                           w: Math.max(reg.minW, w.w | 0), h: Math.max(reg.minH, w.h | 0) })
            }
            return out
        }

        function toggleHidden() {
            setHidden(!hidden)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: core.now = new Date()
    }

    FileView {
        path: shell.aero + "/theme/mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: core.mode = text().trim() === "night" ? "night" : "day"
    }

    FileView {
        path: shell.aero + "/theme/accent"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            var a = text().trim()
            core.accent = (["blue", "red", "green", "black"].indexOf(a) >= 0 || /^c-\d{1,3}-\d{1,3}$/.test(a)) ? a : "blue"
        }
    }

    FileView {
        id: stateFile
        path: core.deskDir + "/state.json"
        printErrors: false
        onLoaded: {
            try {
                core.hidden = !!JSON.parse(text()).hidden
            } catch (err) {
            }
        }
    }

    FileView {
        id: taskFile
        path: shell.aero + "/mission-log.md"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: core.tasks = core.parseTasks(text())
    }

    FileView {
        id: notesFile
        path: shell.aero + "/desk/notes.txt"
        printErrors: false
        onLoaded: core.notes = text()
    }

    Timer {
        id: notesSave
        interval: 700
        onTriggered: notesFile.setText(core.notes)
    }

    FileView {
        path: shell.aero + "/settings.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                core.settings = JSON.parse(text()) || {}
            } catch (err) {
                core.settings = {}
            }
        }
        onLoadFailed: core.settings = {}
    }

    FileView {
        path: shell.aero + "/profile.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                core.profileName = JSON.parse(text()).name || "equilibrado"
            } catch (err) {
            }
        }
    }

    FileView {
        id: pinsFile
        path: shell.aero + "/dock.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text())
                core.pins = Array.isArray(d.pins) ? d.pins : []
                core.pinsSet = true
            } catch (err) {
                core.pins = []
                core.pinsSet = false
            }
        }
        onLoadFailed: {
            core.pins = []
            core.pinsSet = false
        }
    }

    FileView {
        path: shell.home + "/.local/state/hyper-aero/phone-usage.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                core.usage = JSON.parse(text()) || {}
            } catch (err) {
                core.usage = {}
            }
        }
    }

    Process {
        id: feed
        command: [shell.scripts + "/desk-feed.py"]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line)
                    var k = d.k
                    delete d.k
                    if (k === "sys") core.sys = d
                    else if (k === "sky") core.sky = d
                    else if (k === "user") core.user = d
                    else if (k === "weather" && (d.ok || !core.weather.ok)) core.weather = d
                } catch (err) {
                }
            }
        }
        onExited: feedRestart.restart()
    }

    Timer {
        id: feedRestart
        interval: 5000
        onTriggered: feed.running = true
    }

    Process {
        id: cava
        command: ["cava", "-p", shell.aero + "/desk/cava-desk.conf"]
        running: core.placed("visual") && core.playing && !core.hidden
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split(";")
                var out = []
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i].length) out.push(Math.min(1, parseInt(parts[i]) / 100))
                }
                core.bars = out
            }
        }
        onRunningChanged: if (!running) core.bars = []
    }

    Timer {
        id: lyricsWait
        interval: 600
        onTriggered: core.fetchLyrics()
    }

    Timer {
        interval: 60000
        repeat: true
        running: core.lyrics.status === "offline" && core.placed("lyrics")
        onTriggered: core.fetchLyrics()
    }

    Process {
        id: lyricsProc
        stdout: SplitParser {
            onRead: function(line) {
                try {
                    var d = JSON.parse(line)
                    if (d.key === core.lyricKey) core.lyrics = d
                } catch (err) {
                }
            }
        }
    }

    FileView {
        id: gifFile
        path: shell.aero + "/desk/gif.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                var d = JSON.parse(text())
                core.gif = { file: d.file || "", fit: d.fit === "contain" ? "contain" : "cover", paused: !!d.paused }
            } catch (err) {
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: scope
            required property var modelData
            readonly property string name: modelData.name

            Board {
                id: board
                core: shell.hub
                screenName: scope.name
                primary: shell.mainName() === scope.name
                Component.onCompleted: shell.hub.registerBoard(scope.name, board)
                Component.onDestruction: shell.hub.registerBoard(scope.name, null)
            }

            PanelWindow {
                id: weatherWin
                property bool busy: false
                screen: scope.modelData
                color: "transparent"
                visible: !busy && shell.hub.weatherKind !== "clear" && shell.hub.weatherDensity > 0
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Ignore
                mask: Region {}
                WlrLayershell.namespace: "aerofx-weather"
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                WeatherFx {
                    anchors.fill: parent
                    visible: weatherWin.visible
                    kind: shell.hub.weatherKind
                    heavy: !!(shell.hub.weather && shell.hub.weather.heavy) || shell.hub.settings["fx.weather.heavy"] === true
                    night: shell.hub.night
                    density: shell.hub.weatherDensity
                }

                Process {
                    id: busyProc
                    command: ["sh", "-c", "hyprctl -j monitors; echo @@; hyprctl -j workspaces"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            try {
                                var parts = text.split("@@")
                                var mons = JSON.parse(parts[0])
                                var wss = JSON.parse(parts[1])
                                var id = null
                                var extra = false
                                for (var i = 0; i < mons.length; i++) {
                                    if (mons[i].name !== scope.name) continue
                                    id = mons[i].activeWorkspace ? mons[i].activeWorkspace.id : null
                                    var sp = mons[i].specialWorkspace
                                    extra = !!(sp && sp.id && String(sp.name || "").indexOf("aero-min") < 0)
                                }
                                var n = 0
                                for (var j = 0; j < wss.length; j++) {
                                    if (wss[j].id === id) n = wss[j].windows
                                }
                                weatherWin.busy = extra || n > 0
                            } catch (err) {
                            }
                        }
                    }
                }

                Timer {
                    id: busyKick
                    interval: 200
                    running: true
                    onTriggered: if (!busyProc.running) busyProc.running = true
                }

                Connections {
                    target: Hyprland
                    function onRawEvent(ev) {
                        var n = ev.name
                        if (n === "openwindow" || n === "closewindow" || n === "movewindowv2" || n === "workspacev2" || n === "focusedmonv2" || n === "activespecialv2" || n === "changefloatingmode" || n === "moveworkspacev2") busyKick.restart()
                    }
                }
            }

            PanelWindow {
                id: deskWin
                screen: scope.modelData
                color: "transparent"
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Normal
                WlrLayershell.namespace: "aero-desk"
                WlrLayershell.layer: WlrLayer.Bottom
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

                Desk {
                    id: desk
                    anchors.fill: parent
                    core: shell.hub
                    board: board
                    onHud: (shell.hudScreen.length ? shell.hudScreen : shell.mainName()) === scope.name
                    onEditRequested: board.openEdit()
                }
            }

            PanelWindow {
                id: editWin
                visible: board.editing
                screen: scope.modelData
                color: "transparent"
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                exclusionMode: ExclusionMode.Normal
                WlrLayershell.namespace: "aero-desk-edit"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

                Editor {
                    id: editor
                    anchors.fill: parent
                    core: shell.hub
                    board: board
                    cols: desk.cols
                    rows: desk.rows
                    cell: desk.cell
                    ox: desk.ox
                    oy: desk.oy
                    focus: true
                }
            }
        }
    }

    IpcHandler {
        target: "desk"

        function toggle(): void {
            if (core.anyEditing()) return
            core.toggleHidden()
        }

        function show(): void {
            core.setHidden(false)
        }

        function hide(): void {
            core.setHidden(true)
        }

        function edit(): void {
            if (core.anyEditing()) {
                done()
                return
            }
            var mon = Hyprland.focusedMonitor
            var b = core.boardFor(mon ? mon.name : "")
            if (b) b.openEdit()
        }

        function done(): void {
            for (var k in core.boards) {
                if (core.boards[k].editing) core.boards[k].doneRequested()
            }
        }
    }
}
