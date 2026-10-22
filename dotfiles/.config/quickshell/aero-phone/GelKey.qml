import QtQuick

Item {
    id: key
    property var pal
    property real light: 0
    property bool night: false
    property string digit: ""
    property string glyph: ""
    property string sub: ""
    property color tone: "transparent"
    property real round: height / 2.4
    readonly property bool down: area.pressed
    readonly property color lit: pal ? pal.keyLit : "#1e6fd9"
    signal tapped()

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        radius: key.round
        antialiasing: true
        color: key.pal.keyEdge
        opacity: 0.55
    }

    Rectangle {
        id: cap
        width: parent.width
        height: parent.height - 2
        y: key.down ? 1.5 : 0
        radius: key.round
        antialiasing: true
        border.width: 1
        border.color: key.pal.keyRim
        gradient: Gradient {
            GradientStop { position: 0.0; color: key.down ? key.pal.key2 : key.pal.key0 }
            GradientStop { position: 0.46; color: key.pal.key1 }
            GradientStop { position: 0.54; color: key.pal.key2 }
            GradientStop { position: 1.0; color: key.down ? key.pal.key2 : key.pal.key3 }
        }

        Rectangle {
            x: 3; y: 1.5
            width: parent.width - 6
            height: parent.height * 0.45
            radius: key.round - 2
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, key.night ? 0.22 : 0.85) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.7
            height: parent.height * 0.62
            radius: height / 2
            color: key.pal.keyLit
            opacity: key.night ? key.light * 0.16 : 0
        }

        Row {
            anchors.centerIn: parent
            spacing: 7
            visible: key.digit.length > 0

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: key.digit
                font.family: "Exo 2"
                font.weight: Font.Black
                font.pixelSize: 20
                color: Qt.tint(key.pal.keyText, Qt.rgba(key.lit.r, key.lit.g, key.lit.b, key.light * (key.night ? 0.95 : 0.55)))
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Text {
                    text: key.glyph
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Qt.tint(key.pal.keySub, Qt.rgba(key.lit.r, key.lit.g, key.lit.b, key.light * 0.7))
                }
                Text {
                    text: key.sub
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 8
                    font.letterSpacing: 0.4
                    color: key.pal.keySub
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: key.digit.length === 0
            text: key.glyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: key.tone.a > 0 ? key.tone : Qt.tint(key.pal.keySub, Qt.rgba(key.lit.r, key.lit.g, key.lit.b, key.light * 0.8))
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: key.tapped()
    }
}
