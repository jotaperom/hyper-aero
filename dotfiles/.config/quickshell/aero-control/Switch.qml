import QtQuick

Item {
    id: sw
    property var pal
    property bool on: false
    signal toggled(bool value)

    implicitWidth: 50
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        border.width: 1
        border.color: sw.on ? sw.pal.select : sw.pal.btnBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: sw.on ? sw.pal.fill0 : sw.pal.track }
            GradientStop { position: 0.5; color: sw.on ? sw.pal.fill1 : sw.pal.track }
            GradientStop { position: 1.0; color: sw.on ? sw.pal.fill2 : sw.pal.track }
        }
    }

    Rectangle {
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: sw.on ? parent.width - width - 3 : 3
        antialiasing: true
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.15)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#dfe7f1" }
        }
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.on)
    }
}
