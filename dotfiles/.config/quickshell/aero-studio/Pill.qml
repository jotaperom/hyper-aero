import QtQuick

Item {
    id: b
    property var pal
    property string text: ""
    property string glyph: ""
    property bool primary: false
    property bool on: false
    property bool enabled2: true
    signal clicked()
    implicitWidth: row.implicitWidth + 28
    implicitHeight: 34
    opacity: enabled2 ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 2
        radius: height / 2
        color: "#330b0d12"
    }
    Rectangle {
        width: parent.width
        height: parent.height - 1
        y: area.pressed ? 1 : 0
        radius: height / 2
        antialiasing: true
        border.width: b.on ? 2 : 1
        border.color: b.primary || b.on ? b.pal.select : b.pal.btnBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: b.primary ? b.pal.fill0 : b.pal.btn0 }
            GradientStop { position: 0.48; color: b.primary ? b.pal.fill1 : b.pal.btn1 }
            GradientStop { position: 0.52; color: b.primary ? b.pal.fill2 : b.pal.btn2 }
            GradientStop { position: 1.0; color: b.primary ? b.pal.fill1 : b.pal.btn3 }
        }
        Rectangle {
            x: 10; y: 2
            width: parent.width - 20
            height: parent.height * 0.42
            radius: height / 2
            color: Qt.rgba(1, 1, 1, (area.containsMouse ? 0.55 : 0.4) * (b.primary ? 0.8 : 1))
        }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 7
            Text {
                visible: b.glyph.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: b.glyph
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: b.primary ? "#ffffff" : b.pal.btnText
            }
            Text {
                visible: b.text.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: b.text
                font.family: "Exo 2"
                font.weight: Font.Bold
                font.pixelSize: 13
                color: b.primary ? "#ffffff" : b.pal.btnText
            }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: b.enabled2
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
