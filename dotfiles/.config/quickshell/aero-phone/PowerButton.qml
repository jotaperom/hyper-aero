import QtQuick

Item {
    id: btn
    property var pal
    property string glyph: ""
    property string label: ""
    property bool confirm: false
    property bool armed: false
    signal triggered()

    implicitWidth: 64
    implicitHeight: 70

    Timer {
        id: disarm
        interval: 2600
        onTriggered: btn.armed = false
    }

    Rectangle {
        id: orb
        width: 48; height: 48; radius: 24
        anchors.horizontalCenter: parent.horizontalCenter
        antialiasing: true
        border.width: 1
        border.color: btn.armed ? "#ffd0d6" : (area.containsMouse ? btn.pal.glow : btn.pal.tileBorder)
        gradient: Gradient {
            GradientStop { position: 0.0; color: btn.armed ? "#ff9aa6" : btn.pal.tile0 }
            GradientStop { position: 0.48; color: btn.armed ? "#e5484d" : btn.pal.tile1 }
            GradientStop { position: 0.52; color: btn.armed ? "#a8182b" : btn.pal.tile2 }
            GradientStop { position: 1.0; color: btn.armed ? "#c4283b" : btn.pal.tile3 }
        }
        Rectangle {
            x: 4; y: 2
            width: parent.width - 8
            height: parent.height * 0.45
            radius: height / 2
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, btn.armed ? 0.5 : btn.pal.glossTop) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
        Text {
            anchors.centerIn: parent
            text: btn.glyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: btn.armed ? "#ffffff" : (area.containsMouse ? btn.pal.glow : btn.pal.accent)
        }
        scale: area.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
    }

    Text {
        anchors.top: orb.bottom
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        text: btn.armed ? "¿Seguro?" : btn.label
        font.family: "Exo 2"
        font.weight: Font.DemiBold
        font.pixelSize: 10
        color: btn.armed ? "#ff5d6c" : btn.pal.muted
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (btn.confirm && !btn.armed) {
                btn.armed = true
                disarm.restart()
                return
            }
            btn.armed = false
            btn.triggered()
        }
    }
}
