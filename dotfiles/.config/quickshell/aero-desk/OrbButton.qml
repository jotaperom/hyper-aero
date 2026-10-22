import QtQuick

Item {
    id: ob
    property var pal
    property string glyph: ""
    property real size: 34
    property bool live: false
    property real glyphSize: size * 0.42
    property real gloss: 1
    signal clicked()
    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        radius: width / 2
        color: "#400b0d12"
    }

    Rectangle {
        width: parent.width
        height: parent.height - 1
        radius: width / 2
        antialiasing: true
        border.width: ob.live ? 3 : 2
        border.color: ob.live ? "#2fbf5a" : ob.pal.btnBorder
        y: area.pressed ? 1 : 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: ob.pal.btn0 }
            GradientStop { position: 0.46; color: ob.pal.btn1 }
            GradientStop { position: 0.54; color: ob.pal.btn2 }
            GradientStop { position: 1.0; color: ob.pal.btn3 }
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: width / 2
            color: "transparent"
            border.width: 3
            border.color: "#554cdc78"
            visible: ob.live
        }
        Rectangle {
            x: parent.width * 0.22
            y: 3
            width: parent.width * 0.56
            height: parent.height * 0.3
            radius: height / 2
            color: Qt.rgba(1, 1, 1, (area.containsMouse ? 0.5 : 0.34) * ob.gloss)
        }
        Text {
            anchors.centerIn: parent
            text: ob.glyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: ob.glyphSize
            font.weight: Font.Bold
            color: ob.pal.btnText
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ob.clicked()
    }
}
