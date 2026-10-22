import QtQuick

Item {
    id: m
    property var pal
    property bool laptop: false
    property bool lit: true
    property string label: ""
    property color glow: pal ? pal.sky : "#3d9be9"
    implicitWidth: 64
    implicitHeight: 44

    Rectangle {
        id: body
        width: parent.width
        height: m.laptop ? parent.height * 0.84 : parent.height * 0.8
        radius: 4
        antialiasing: true
        color: m.pal.lcd2
        border.width: 1.5
        border.color: m.lit ? Qt.lighter(m.glow, 1.25) : m.pal.dim

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 2
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: m.lit ? Qt.lighter(m.glow, 1.35) : "#1a2233" }
                GradientStop { position: 0.55; color: m.lit ? m.glow : "#121a28" }
                GradientStop { position: 1.0; color: m.lit ? Qt.darker(m.glow, 1.5) : "#0b111c" }
            }
            Rectangle {
                width: parent.width
                height: parent.height * 0.45
                radius: 2
                color: Qt.rgba(1, 1, 1, m.lit ? 0.28 : 0.06)
            }
            Text {
                anchors.centerIn: parent
                visible: m.label.length > 0
                text: m.label
                font.family: "Exo 2"
                font.weight: Font.Black
                font.pixelSize: Math.max(10, parent.height * 0.55)
                color: m.lit ? "#ffffff" : "#4a5a78"
                style: Text.Raised
                styleColor: "#550b0d12"
            }
        }
    }

    Rectangle {
        visible: !m.laptop
        anchors.horizontalCenter: parent.horizontalCenter
        y: body.height
        width: parent.width * 0.16
        height: parent.height - body.height - 3
        color: m.pal.dim
    }
    Rectangle {
        visible: !m.laptop
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: parent.width * 0.42
        height: 3
        radius: 1.5
        color: m.pal.dim
    }
    Rectangle {
        visible: m.laptop
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: parent.width * 1.16
        height: parent.height - body.height - 1
        radius: 2
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: m.pal.btn1 }
            GradientStop { position: 1.0; color: m.pal.dim }
        }
    }
}
