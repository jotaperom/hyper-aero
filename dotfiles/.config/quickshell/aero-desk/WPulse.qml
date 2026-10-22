import QtQuick

Item {
    id: w
    property var core
    property var pal
    readonly property var p: core ? core.player : null
    readonly property bool playing: !!(p && p.isPlaying)
    readonly property real len: p && p.length > 0 ? p.length : 0
    property real pos: 0
    readonly property real baseW: 440
    readonly property real baseH: 168
    readonly property real k: Math.min(width / baseW, height / baseH)

    function clock(s) {
        s = Math.max(0, Math.floor(s))
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    Timer {
        interval: 1000
        repeat: true
        running: !!w.p
        triggeredOnStart: true
        onTriggered: {
            if (w.p) {
                w.p.positionChanged()
                w.pos = w.p.position
            }
        }
    }

    Item {
        width: w.baseW
        height: w.baseH
        anchors.centerIn: parent
        scale: w.k

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: 62
            antialiasing: true
            color: w.pal.shellRing
        }

        Rectangle {
            id: shell
            anchors.fill: parent
            radius: 60
            antialiasing: true
            border.width: 3
            border.color: w.pal.shellRim
            gradient: Gradient {
                GradientStop { position: 0.0; color: w.pal.shell0 }
                GradientStop { position: 0.22; color: w.pal.shell1 }
                GradientStop { position: 0.55; color: w.pal.shell2 }
                GradientStop { position: 0.82; color: w.pal.shell3 }
                GradientStop { position: 1.0; color: w.pal.shell4 }
            }
            Rectangle {
                x: 8; y: 3
                width: parent.width - 16
                height: parent.height * 0.36
                radius: 54
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, w.core && w.core.night ? 0.3 : 0.6) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }

        Column {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            OrbButton { pal: w.pal; gloss: w.core && w.core.night ? 0.45 : 1; size: 34; glyph: "\u{F04AE}"; anchors.horizontalCenter: parent.horizontalCenter; onClicked: w.core.media("prev") }
            OrbButton { pal: w.pal; gloss: w.core && w.core.night ? 0.45 : 1; size: 46; glyph: w.playing ? "\u{F03E4}" : "\u{F040A}"; live: w.playing; anchors.horizontalCenter: parent.horizontalCenter; onClicked: w.core.media("toggle") }
            OrbButton { pal: w.pal; gloss: w.core && w.core.night ? 0.45 : 1; size: 34; glyph: "\u{F04AD}"; anchors.horizontalCenter: parent.horizontalCenter; onClicked: w.core.media("next") }
        }

        Rectangle {
            id: lcd
            x: 76
            y: 16
            width: 290
            height: 104
            radius: 26
            antialiasing: true
            clip: true
            border.width: 2
            border.color: w.pal.lcdRim
            gradient: Gradient {
                GradientStop { position: 0.0; color: w.pal.lcd0 }
                GradientStop { position: 0.45; color: w.pal.lcd1 }
                GradientStop { position: 1.0; color: w.pal.lcd2 }
            }

            Repeater {
                model: 34
                delegate: Rectangle {
                    required property int index
                    y: index * 3
                    width: lcd.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.05)
                }
            }
            Rectangle {
                width: parent.width
                height: parent.height * 0.32
                radius: 26
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.18) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            Item {
                x: 16
                y: 9
                width: parent.width - 32
                height: parent.height - 18

                Text {
                    text: "◢ " + (w.p ? String(w.p.identity || "PLAYER").toUpperCase() : "NO PLAYER")
                    font.family: "DotGothic16"
                    font.pixelSize: 10
                    color: w.pal.lcdText
                    style: Text.Outline
                    styleColor: "#3378c8ff"
                }
                Text {
                    anchors.right: parent.right
                    text: "VOL " + (w.core ? (w.core.muted ? "MUTE" : Math.round(w.core.volume * 100)) : 0)
                    font.family: "DotGothic16"
                    font.pixelSize: 10
                    color: w.pal.lcdText
                }

                Row {
                    y: 14
                    spacing: 10
                    Text {
                        text: (w.playing ? "▶ " : (w.p ? "|| " : "■ ")) + w.clock(w.pos)
                        font.family: "DotGothic16"
                        font.pixelSize: 24
                        color: w.pal.lcdText
                        style: Text.Outline
                        styleColor: "#4078c8ff"
                    }
                }

                Row {
                    anchors.right: parent.right
                    y: 22
                    height: 16
                    spacing: 2
                    Repeater {
                        model: 22
                        delegate: Rectangle {
                            required property int index
                            readonly property real v: w.core && w.core.bars.length ? (w.core.bars[Math.floor(index * w.core.bars.length / 22)] || 0) : (w.playing ? 0.25 + 0.2 * Math.abs(Math.sin(w.pos * 1.7 + index)) : 0.08)
                            anchors.bottom: parent.bottom
                            width: 3
                            height: Math.max(2, 16 * v)
                            color: "#9fd6ff"
                            Behavior on height { NumberAnimation { duration: 120 } }
                        }
                    }
                }

                Text {
                    y: 46
                    text: "TOTAL " + w.clock(w.len) + "  ·  STEREO  ·  " + (w.playing ? "PLAY" : (w.p ? "PAUSE" : "STANDBY"))
                    font.family: "DotGothic16"
                    font.pixelSize: 10
                    color: Qt.rgba(0.81, 0.92, 1, 0.55)
                }

                Item {
                    y: 62
                    width: parent.width
                    height: 20
                    clip: true
                    Text {
                        id: marq
                        readonly property string full: w.p ? ((w.p.trackArtist ? w.p.trackArtist + " - " : "") + (w.p.trackTitle || "")).toUpperCase() : "NO DISC"
                        text: full
                        font.family: "DotGothic16"
                        font.pixelSize: 14
                        color: w.pal.lcdText
                        style: Text.Outline
                        styleColor: "#3378c8ff"
                        property real shift: 0
                        x: implicitWidth > parent.width ? -shift : 0
                        NumberAnimation on shift {
                            running: marq.implicitWidth > marq.parent.width
                            from: -20
                            to: marq.implicitWidth - marq.parent.width + 20
                            duration: Math.max(3000, (marq.implicitWidth - marq.parent.width) * 45)
                            loops: Animation.Infinite
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
        }

        Item {
            id: seek
            x: 80
            y: 132
            width: 282
            height: 16
            readonly property real v: w.len > 0 ? Math.min(1, w.pos / w.len) : 0

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 6
                radius: 3
                color: "#4d0b0d12"
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * seek.v
                height: 6
                radius: 3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#cfeaff" }
                    GradientStop { position: 1.0; color: "#ffffff" }
                }
            }
            Rectangle {
                x: parent.width * seek.v - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 16; height: 16; radius: 8
                border.width: 2
                border.color: "#990b308c"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#ffffff" }
                    GradientStop { position: 0.5; color: "#e3eef9" }
                    GradientStop { position: 1.0; color: "#cfe2f6" }
                }
            }
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                function jump(mx) {
                    if (!w.p || !w.p.canSeek || w.len <= 0) return
                    var t = Math.max(0, Math.min(1, (mx - 6) / seek.width)) * w.len
                    w.p.position = t
                    w.pos = t
                }
                onPressed: function(m) { jump(m.x) }
                onPositionChanged: function(m) { if (pressed) jump(m.x) }
            }
        }

        Column {
            x: parent.width - 58
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            OrbButton { pal: w.pal; gloss: w.core && w.core.night ? 0.45 : 1; size: 30; glyph: "+"; glyphSize: 16; anchors.horizontalCenter: parent.horizontalCenter; onClicked: w.core.nudgeVolume(0.05) }
            OrbButton { pal: w.pal; gloss: w.core && w.core.night ? 0.45 : 1; size: 30; glyph: "−"; glyphSize: 16; anchors.horizontalCenter: parent.horizontalCenter; onClicked: w.core.nudgeVolume(-0.05) }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 8; height: 8; radius: 4
                color: w.playing ? "#4cff7a" : (w.p ? "#ffc04d" : "#590b0d12")
                Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: parent.color; opacity: w.p ? 0.3 : 0 }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "PULSE-X"
                font.family: "Michroma"
                font.pixelSize: 6
                color: Qt.rgba(1, 1, 1, 0.85)
            }
        }
    }
}
