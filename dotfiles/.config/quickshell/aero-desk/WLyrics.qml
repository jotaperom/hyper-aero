import QtQuick
import "Lang.js" as L

Card {
    id: w
    property var core
    readonly property var p: core ? core.lyricPlayer : null
    readonly property var info: core ? core.lyrics : null
    readonly property bool fresh: !!(p && info && core.lyricKey.length && info.key === core.lyricKey)
    readonly property string phase: !p || !core.lyricKey.length ? "idle" : (!fresh ? "loading" : info.status)
    readonly property var lines: phase === "ok" ? info.lines : []
    readonly property bool synced: phase === "ok" && info.synced
    readonly property bool playing: !!(p && p.isPlaying)
    readonly property real len: p && p.length > 0 ? p.length : 0
    readonly property real fs: Math.max(12, Math.min(22, body.height / 8.5))
    property real anchorPos: 0
    property real anchorAt: 0
    property real pos: 0
    readonly property int current: locate(lines, pos)

    title: "LYRICS"
    tag: p ? String(p.trackTitle || "").toUpperCase() : ""

    function locate(list, t) {
        if (!list || !list.length) return -1
        if (!synced) return len > 0 ? Math.min(list.length - 1, Math.floor(t / len * list.length)) : -1
        var lo = 0, hi = list.length - 1, found = -1
        var probe = t + 0.25
        while (lo <= hi) {
            var mid = (lo + hi) >> 1
            if (list[mid][0] <= probe) {
                found = mid
                lo = mid + 1
            } else {
                hi = mid - 1
            }
        }
        return found
    }

    function sync() {
        if (!p) return
        p.positionChanged()
        anchorPos = p.position
        anchorAt = Date.now()
        pos = anchorPos
    }

    function lineFrac(i) {
        if (!synced || i < 0 || i >= lines.length) return 0
        var start = lines[i][0]
        var end = i + 1 < lines.length ? lines[i + 1][0] : Math.max(start + 4, len)
        return Math.max(0, Math.min(1, (pos - start) / Math.max(0.1, end - start)))
    }

    onPlayingChanged: sync()
    onLinesChanged: {
        sync()
        strip.jump = true
        settle.restart()
    }

    Timer {
        id: settle
        interval: 60
        onTriggered: strip.jump = false
    }

    Timer {
        interval: 800
        repeat: true
        running: !!w.p && w.visible
        triggeredOnStart: true
        onTriggered: w.sync()
    }

    Timer {
        interval: 40
        repeat: true
        running: w.playing && w.lines.length > 0 && w.visible
        onTriggered: w.pos = w.anchorPos + (Date.now() - w.anchorAt) / 1000
    }

    Item {
        id: view
        anchors.fill: parent
        clip: true
        visible: w.lines.length > 0
        readonly property real focusY: height * 0.4
        readonly property var cur: w.current >= 0 && w.current < rep.count ? rep.itemAt(w.current) : null

        Rectangle {
            id: glow
            x: -6
            width: view.width + 12
            y: view.cur ? strip.y + view.cur.y - 6 : -100
            height: view.cur ? view.cur.height + 12 : 0
            radius: 12
            color: w.pal.hover
            border.width: 1
            border.color: w.pal.sep
            opacity: view.cur && w.synced ? 1 : 0
            Behavior on y { enabled: !strip.jump; NumberAnimation { duration: 520; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1] } }
            Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 260 } }

            Rectangle {
                x: 10
                y: parent.height - 4
                height: 2
                radius: 1
                width: (parent.width - 20) * w.lineFrac(w.current)
                color: w.pal.accent
                opacity: 0.8
            }
        }

        Column {
            id: strip
            property bool jump: false
            width: view.width
            spacing: Math.round(w.fs * 0.55)
            y: view.cur ? view.focusY - view.cur.y - view.cur.height / 2 : (w.synced ? view.focusY : 4)
            Behavior on y { enabled: !strip.jump; NumberAnimation { duration: 560; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1] } }

            Repeater {
                id: rep
                model: w.lines
                delegate: Text {
                    id: ln
                    required property var modelData
                    required property int index
                    readonly property bool on: index === w.current
                    readonly property real lineTop: strip.y + y
                    readonly property real edge: Math.max(0, Math.min(1, Math.min(lineTop + height, view.height - lineTop) / (w.fs * 2.2)))
                    width: strip.width
                    wrapMode: Text.WordWrap
                    text: modelData[1].length ? modelData[1] : "♪"
                    font.family: "Exo 2"
                    font.weight: on ? Font.Bold : Font.DemiBold
                    font.pixelSize: w.fs
                    lineHeight: 1.08
                    color: on ? w.pal.ink : w.pal.muted
                    transformOrigin: Item.Left
                    scale: on ? 1 : 0.9
                    opacity: edge * (on ? 1 : (index < w.current ? 0.42 : 0.62))
                    Behavior on color { ColorAnimation { duration: 380 } }
                    Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    MouseArea {
                        anchors.fill: parent
                        enabled: w.synced && !!w.p && w.p.canSeek
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            w.p.position = Math.max(0, ln.modelData[0])
                            w.anchorPos = w.p.position
                            w.anchorAt = Date.now()
                            w.pos = w.anchorPos
                        }
                    }
                }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: w.phase === "ok" && !w.synced
        text: L.t("SIN SINCRONIZAR")
        font.family: "Michroma"
        font.pixelSize: 7
        color: w.pal.dim
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 6
        visible: w.lines.length === 0

        Text {
            id: glyph
            anchors.horizontalCenter: parent.horizontalCenter
            text: w.phase === "offline" ? "\u{F0164}" : (w.phase === "instrumental" ? "\u{F0387}" : (w.phase === "none" ? "\u{F09ED}" : "\u{F036C}"))
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.min(34, w.fs * 1.8)
            color: w.pal.accent
            opacity: w.phase === "loading" ? 0.45 + 0.55 * pulse.v : 1
            QtObject {
                id: pulse
                property real v: 0
                SequentialAnimation on v {
                    running: w.phase === "loading" && w.visible
                    loops: Animation.Infinite
                    NumberAnimation { from: 0; to: 1; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1; to: 0; duration: 700; easing.type: Easing.InOutSine }
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: w.phase === "idle" ? L.t("Nada sonando")
                : w.phase === "loading" ? L.t("Buscando la letra…")
                : w.phase === "instrumental" ? L.t("Instrumental")
                : w.phase === "offline" ? L.t("Sin conexión")
                : L.t("No encontré la letra")
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: Math.max(12, w.fs * 0.85)
            color: w.pal.ink
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: text.length > 0
            text: w.phase === "idle" ? L.t("Poné algo en Spotify")
                : w.phase === "offline" ? L.t("Lo intento de nuevo en un minuto")
                : w.phase === "none" ? L.t("Esta canción no está en LRCLIB")
                : ""
            font.family: "Exo 2"
            font.pixelSize: Math.max(10, w.fs * 0.65)
            color: w.pal.muted
        }
    }
}
