import QtQuick

Item {
    id: v
    property var st: ({ active: false })
    property string accent: "blue"
    property bool night: false
    readonly property bool on: !!st.active
    readonly property var r: st.rect || null
    readonly property var flip: st.flip || null
    readonly property var custom: /^c-(\d{1,3})-(\d{1,3})$/.exec(accent)
    readonly property color tint: custom ? Qt.hsla(parseInt(custom[1]) / 360, Math.min(1, 0.82 * parseInt(custom[2]) / 100), 0.57, 1) : accent === "red" ? "#e0384f" : accent === "green" ? "#2fbf8a" : accent === "black" ? "#7c8698" : "#3d9be9"
    readonly property color glow: custom ? Qt.hsla(parseInt(custom[1]) / 360, Math.min(1, 0.85 * parseInt(custom[2]) / 100), 0.72, 1) : accent === "red" ? "#ff8d98" : accent === "green" ? "#7ff0c4" : accent === "black" ? "#c9d3de" : "#6fd3ff"
    property real lastX: width / 2
    property real lastY: height / 2

    Rectangle {
        id: preview
        readonly property bool shown: v.on && !!v.r && !v.flip
        x: v.r ? v.r[0] : v.lastX
        y: v.r ? v.r[1] : v.lastY
        width: v.r ? v.r[2] : 0
        height: v.r ? v.r[3] : 0
        radius: 16
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.92
        color: Qt.rgba(v.tint.r, v.tint.g, v.tint.b, v.night ? 0.22 : 0.18)
        border.width: 2
        border.color: Qt.rgba(v.glow.r, v.glow.g, v.glow.b, 0.95)
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        onXChanged: if (v.r) v.lastX = x + width / 2
        onYChanged: if (v.r) v.lastY = y + height / 2

        Rectangle {
            x: 2; y: 2
            width: parent.width - 4
            height: Math.min(parent.height * 0.4, 140)
            radius: 14
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, v.night ? 0.16 : 0.32) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: 12
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.35)
        }
    }

    Item {
        id: flipBox
        readonly property bool shown: v.on && !!v.flip
        readonly property bool toLeft: v.flip ? v.flip.dir === "left" : true
        width: 220
        height: 150
        x: toLeft ? 24 : v.width - width - 24
        y: (v.height - height) / 2
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(v.tint.r, v.tint.g, v.tint.b, v.night ? 0.3 : 0.24)
            border.width: 2
            border.color: Qt.rgba(v.glow.r, v.glow.g, v.glow.b, 0.95)
            Rectangle {
                x: 2; y: 2
                width: parent.width - 4
                height: parent.height * 0.45
                radius: 22
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.3) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 18
            text: flipBox.toLeft ? "\u{F0141}" : "\u{F0142}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 40
            color: "#ffffff"
            style: Text.Raised
            styleColor: "#660a2a66"
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 72
            text: "ESCRITORIO " + (v.flip ? (v.flip.ws < 10 ? "0" : "") + v.flip.ws : "")
            font.family: "Michroma"
            font.pixelSize: 13
            font.letterSpacing: 1
            color: "#ffffff"
            style: Text.Raised
            styleColor: "#660a2a66"
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 108
            width: 160
            height: 8
            radius: 4
            color: Qt.rgba(1, 1, 1, 0.25)
            Rectangle {
                width: parent.width * (v.flip ? v.flip.p : 0)
                height: parent.height
                radius: 4
                color: "#ffffff"
                Behavior on width { NumberAnimation { duration: 60 } }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 124
            text: v.flip && v.flip.p >= 1 ? "Soltá para moverla" : "Mantené para cambiar"
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 11
            color: Qt.rgba(1, 1, 1, 0.9)
        }
    }

    Item {
        id: strip
        readonly property var tiles: v.st.tiles || []
        opacity: v.on && tiles.length ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 180 } }
        transform: Translate {
            y: v.on ? 0 : -12
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }

        Repeater {
            model: strip.tiles
            delegate: Item {
                id: tile
                required property var modelData
                x: modelData.x
                y: modelData.y
                width: modelData.w
                height: modelData.h
                scale: modelData.on ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    border.width: tile.modelData.on ? 2 : 1
                    border.color: tile.modelData.on ? "#ffffff" : Qt.rgba(1, 1, 1, 0.7)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: tile.modelData.on ? Qt.lighter(v.tint, 1.35) : Qt.rgba(1, 1, 1, v.night ? 0.22 : 0.75) }
                        GradientStop { position: 0.5; color: tile.modelData.on ? v.tint : Qt.rgba(v.tint.r, v.tint.g, v.tint.b, v.night ? 0.35 : 0.3) }
                        GradientStop { position: 1.0; color: tile.modelData.on ? Qt.darker(v.tint, 1.25) : Qt.rgba(v.tint.r, v.tint.g, v.tint.b, v.night ? 0.5 : 0.45) }
                    }
                    Rectangle {
                        x: 2; y: 2
                        width: parent.width - 4
                        height: parent.height * 0.45
                        radius: 12
                        color: Qt.rgba(1, 1, 1, 0.3)
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: (tile.modelData.id < 10 ? "0" : "") + tile.modelData.id
                    font.family: "Michroma"
                    font.pixelSize: 14
                    color: tile.modelData.on || v.night ? "#ffffff" : "#0b2a66"
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 5
                    width: 14
                    height: 3
                    radius: 1.5
                    visible: tile.modelData.cur
                    color: tile.modelData.on || v.night ? "#ffffff" : v.tint
                }
            }
        }
        Text {
            readonly property var last: strip.tiles.length ? strip.tiles[strip.tiles.length - 1] : null
            x: last ? last.x + last.w + 14 : 0
            y: last ? last.y + (last.h - height) / 2 : 0
            text: "Soltá sobre un escritorio para moverla"
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: "#ffffff"
            style: Text.Outline
            styleColor: "#990a2a66"
        }
    }
}
