import QtQuick

Item {
    id: tb
    property var pal
    property string glyph: ""
    property string text: ""
    property bool primary: false
    signal clicked()
    width: 132
    height: primary ? 40 : 28

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        border.width: 1
        border.color: tb.primary ? "#ccffffff" : tb.pal.btnBorder
        scale: area.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 100 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: tb.primary ? tb.pal.fill0 : tb.pal.btn0 }
            GradientStop { position: 0.48; color: tb.primary ? tb.pal.fill1 : tb.pal.btn1 }
            GradientStop { position: 0.52; color: tb.primary ? tb.pal.fill2 : tb.pal.btn2 }
            GradientStop { position: 1.0; color: tb.primary ? tb.pal.fill1 : tb.pal.btn3 }
        }
        Rectangle {
            x: 6; y: 2
            width: parent.width - 12
            height: parent.height * 0.42
            radius: height / 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.7 : 0.5) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
        Row {
            anchors.centerIn: parent
            spacing: 7
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tb.glyph
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: tb.primary ? 16 : 13
                color: tb.primary ? "#ffffff" : tb.pal.btnText
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tb.text
                font.family: "Michroma"
                font.pixelSize: tb.primary ? 10 : 8
                color: tb.primary ? "#ffffff" : tb.pal.btnText
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tb.clicked()
    }
}
