import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Lang.js" as L

Scope {
    id: rd
    property var pal
    property bool night: false
    property string scripts: ""
    property bool playing: false
    property bool open: false
    property bool mapped: false
    property var target: null
    property point at: Qt.point(0, 0)
    property int hot: -1
    property real reveal: open ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: rd.open ? 320 : 180; easing.type: rd.open ? Easing.OutBack : Easing.InCubic } }
    readonly property var items: [
        { id: "apps", glyph: "\u{F003B}", label: L.t("Apps") },
        { id: "shot", glyph: "\u{F0100}", label: L.t("Captura") },
        { id: "play", glyph: rd.playing ? "\u{F03E4}" : "\u{F040A}", label: rd.playing ? L.t("Pausar") : L.t("Reproducir") },
        { id: "next", glyph: "\u{F04AD}", label: L.t("Siguiente") },
        { id: "bt", glyph: "\u{F00AF}", label: "Bluetooth" },
        { id: "audio", glyph: "\u{F057E}", label: L.t("Audio") },
        { id: "themes", glyph: "\u{F03D8}", label: L.t("Temas") },
        { id: "settings", glyph: "\u{F0493}", label: L.t("Ajustes") }
    ]
    readonly property real ring: 112
    readonly property real orb: 58

    function pickScreen() {
        var list = Quickshell.screens
        var mon = Hyprland.focusedMonitor
        for (var i = 0; i < list.length; i++) {
            if (mon && list[i].name === mon.name) return list[i]
        }
        return list.length ? list[0] : null
    }

    function show() {
        cursorProc.running = true
    }

    function close() {
        open = false
        hot = -1
        hide.restart()
    }

    function fire(i) {
        if (i < 0 || i >= items.length) return
        var id = items[i].id
        close()
        var S = scripts
        var cmd = null
        if (id === "apps") cmd = [S + "/phone.sh", "open"]
        else if (id === "shot") cmd = ["sh", "-c", "sleep 0.35; exec \"$1\" region", "sh", S + "/screenshot.sh"]
        else if (id === "play") cmd = ["playerctl", "play-pause"]
        else if (id === "next") cmd = ["playerctl", "next"]
        else if (id === "bt") cmd = [S + "/phone.sh", "bluetooth"]
        else if (id === "audio") cmd = [S + "/phone.sh", "audio"]
        else if (id === "themes") cmd = [S + "/carousel.sh"]
        else if (id === "settings") cmd = [S + "/control.sh"]
        if (cmd) Quickshell.execDetached(cmd)
    }

    function pick(x, y) {
        var dx = x - at.x
        var dy = y - at.y
        var d = Math.sqrt(dx * dx + dy * dy)
        if (d < 46) return -1
        var a = Math.atan2(dy, dx) + Math.PI / 2
        if (a < 0) a += Math.PI * 2
        var n = items.length
        return Math.floor((a + Math.PI / n) / (Math.PI * 2 / n)) % n
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "-j", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                var c = { x: 0, y: 0 }
                try {
                    c = JSON.parse(text)
                } catch (err) {
                }
                var s = rd.pickScreen()
                rd.target = s
                var lx = s ? c.x - s.x : c.x
                var ly = s ? c.y - s.y : c.y
                var w = s ? s.width : 1920
                var h = s ? s.height : 1080
                var m = rd.ring + rd.orb
                rd.at = Qt.point(Math.max(m, Math.min(w - m, lx)), Math.max(m, Math.min(h - m, ly)))
                hide.stop()
                rd.mapped = true
                rd.open = true
            }
        }
    }

    Timer {
        id: hide
        interval: 220
        onTriggered: if (!rd.open) rd.mapped = false
    }

    PanelWindow {
        id: win
        visible: rd.mapped
        screen: rd.target
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "aero-radial"
        WlrLayershell.keyboardFocus: rd.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0.02, 0.08, 0.18 * rd.reveal)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPositionChanged: function(m) { rd.hot = rd.pick(m.x, m.y) }
            onClicked: function(m) {
                if (m.button !== Qt.LeftButton) {
                    rd.close()
                    return
                }
                var i = rd.pick(m.x, m.y)
                if (i < 0) rd.close()
                else rd.fire(i)
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: function(e) {
                var n = rd.items.length
                if (e.key === Qt.Key_Escape) rd.close()
                else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab) rd.hot = (rd.hot + 1 + n) % n
                else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) rd.hot = (rd.hot - 1 + n) % n
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) rd.fire(rd.hot)
                else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_8) rd.fire(e.key - Qt.Key_1)
                e.accepted = true
            }
        }

        Item {
            id: dial
            x: rd.at.x - width / 2
            y: rd.at.y - height / 2
            width: (rd.ring + rd.orb) * 2
            height: width
            scale: 0.55 + 0.45 * rd.reveal
            opacity: Math.min(1, rd.reveal * 1.4)

            Rectangle {
                anchors.centerIn: parent
                width: rd.ring * 2 + rd.orb + 14
                height: width
                radius: width / 2
                color: rd.night ? Qt.rgba(0.04, 0.08, 0.16, 0.55) : Qt.rgba(1, 1, 1, 0.32)
                border.width: 1
                border.color: rd.night ? Qt.rgba(0.43, 0.83, 1, 0.45) : Qt.rgba(1, 1, 1, 0.85)
                Rectangle {
                    anchors.centerIn: parent
                    width: rd.ring * 2 - rd.orb - 10
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: rd.night ? Qt.rgba(0.43, 0.83, 1, 0.25) : Qt.rgba(1, 1, 1, 0.6)
                }
                Rectangle {
                    x: parent.width * 0.12
                    y: 3
                    width: parent.width * 0.76
                    height: parent.height * 0.42
                    radius: height / 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, rd.night ? 0.16 : 0.5) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
            }

            Canvas {
                id: wedge
                anchors.fill: parent
                property int idx: rd.hot
                onIdxChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d")
                    c.reset()
                    if (idx < 0) return
                    var n = rd.items.length
                    var mid = idx * Math.PI * 2 / n - Math.PI / 2
                    var span = Math.PI / n
                    var cx = width / 2
                    var cy = height / 2
                    var r1 = rd.ring - rd.orb / 2 - 4
                    var r2 = rd.ring + rd.orb / 2 + 6
                    var col = rd.pal ? rd.pal.glow : "#3d9be9"
                    c.beginPath()
                    c.arc(cx, cy, r2, mid - span, mid + span, false)
                    c.arc(cx, cy, r1, mid + span, mid - span, true)
                    c.closePath()
                    var g = c.createRadialGradient(cx, cy, r1, cx, cy, r2)
                    g.addColorStop(0, Qt.rgba(col.r, col.g, col.b, 0.05))
                    g.addColorStop(1, Qt.rgba(col.r, col.g, col.b, 0.38))
                    c.fillStyle = g
                    c.fill()
                }
            }

            Repeater {
                model: rd.items
                delegate: Item {
                    id: slot
                    required property var modelData
                    required property int index
                    readonly property real ang: index * Math.PI * 2 / rd.items.length - Math.PI / 2
                    readonly property bool lit: rd.hot === index
                    readonly property real pop: Math.max(0, Math.min(1, rd.reveal * 1.6 - index * 0.07))
                    width: rd.orb
                    height: rd.orb
                    x: dial.width / 2 + Math.cos(ang) * rd.ring * (0.6 + 0.4 * pop) - width / 2
                    y: dial.height / 2 + Math.sin(ang) * rd.ring * (0.6 + 0.4 * pop) - height / 2
                    scale: (lit ? 1.16 : 1) * (0.5 + 0.5 * pop)
                    opacity: pop
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 16
                        height: width
                        radius: width / 2
                        color: rd.pal ? Qt.rgba(rd.pal.glow.r, rd.pal.glow.g, rd.pal.glow.b, slot.lit ? 0.35 : 0) : "transparent"
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        border.width: 1
                        border.color: slot.lit ? "#ffffff" : (rd.night ? Qt.rgba(0.43, 0.83, 1, 0.6) : Qt.rgba(0.05, 0.19, 0.55, 0.45))
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: slot.lit ? (rd.pal ? Qt.lighter(rd.pal.glow, 1.3) : "#8cc6f5") : (rd.night ? "#38558a" : "#ffffff") }
                            GradientStop { position: 0.5; color: slot.lit ? (rd.pal ? rd.pal.glow : "#3d9be9") : (rd.night ? "#263d6c" : "#e6f0fb") }
                            GradientStop { position: 1.0; color: slot.lit ? (rd.pal ? rd.pal.accent : "#1446c2") : (rd.night ? "#1b2e5a" : "#c4dcf4") }
                        }
                        Rectangle {
                            x: parent.width * 0.16
                            y: 3
                            width: parent.width * 0.68
                            height: parent.height * 0.44
                            radius: height / 2
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, rd.night && !slot.lit ? 0.3 : 0.8) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: slot.modelData.glyph
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            color: slot.lit ? "#ffffff" : (rd.night ? "#6fd3ff" : "#1446c2")
                            style: Text.Raised
                            styleColor: Qt.rgba(0, 0, 0, slot.lit ? 0.25 : 0.08)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -16
                        visible: slot.lit
                        text: String(slot.index + 1)
                        font.family: "Michroma"
                        font.pixelSize: 8
                        color: rd.night ? "#cfeaff" : "#0b2f8a"
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 84
                height: 84
                radius: 42
                border.width: 1
                border.color: rd.night ? Qt.rgba(0.43, 0.83, 1, 0.55) : "#ffffff"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: rd.night ? "#2f6fb8" : "#7fbdf3" }
                    GradientStop { position: 0.55; color: rd.night ? "#163f8a" : "#3d9be9" }
                    GradientStop { position: 1.0; color: rd.night ? "#0a1f4e" : "#1446c2" }
                }
                Rectangle {
                    x: 12
                    y: 3
                    width: parent.width - 24
                    height: parent.height * 0.42
                    radius: height / 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.55) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 10
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: rd.hot >= 0 ? rd.items[rd.hot].label : "◢"
                    font.family: rd.hot >= 0 ? "Exo 2" : "Michroma"
                    font.weight: Font.Bold
                    font.pixelSize: rd.hot >= 0 ? 12 : 18
                    color: "#ffffff"
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.3)
                }
            }
        }
    }
}
