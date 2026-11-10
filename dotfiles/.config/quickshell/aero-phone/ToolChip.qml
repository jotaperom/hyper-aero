import QtQuick

Item {
    id: tc
    property var pal
    property string glyph: ""
    property string label: ""
    signal clicked()

    implicitHeight: 44

    Rectangle {
        anchors.fill: parent
        radius: 16
        antialiasing: true
        border.width: 1
        border.color: area.containsMouse ? tc.pal.glow : tc.pal.tileBorder
        scale: area.pressed ? 0.96 : 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: tc.pal.tile0 }
            GradientStop { position: 0.48; color: tc.pal.tile1 }
            GradientStop { position: 0.52; color: tc.pal.tile2 }
            GradientStop { position: 1.0; color: tc.pal.tile3 }
        }
        Rectangle {
            x: 1; y: 1
            width: parent.width - 2
            height: parent.height * 0.46
            radius: 15
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, tc.pal.glossTop) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tc.glyph
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: tc.pal.accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tc.label
                font.family: "Exo 2"
                font.weight: Font.Bold
                font.pixelSize: 11
                color: tc.pal.text
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tc.clicked()
    }
}
