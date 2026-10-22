import QtQuick

Item {
    id: sw
    property var pal
    property bool on: false
    property bool enabledSwitch: true
    signal toggled(bool value)

    implicitWidth: 52
    implicitHeight: 30
    opacity: enabledSwitch ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        border.width: 1
        border.color: sw.on ? sw.pal.onBorder : sw.pal.tileBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: sw.on ? sw.pal.on0 : sw.pal.track }
            GradientStop { position: 0.48; color: sw.on ? sw.pal.on1 : sw.pal.track }
            GradientStop { position: 0.52; color: sw.on ? sw.pal.on2 : sw.pal.track }
            GradientStop { position: 1.0; color: sw.on ? sw.pal.on3 : sw.pal.track }
        }
    }

    Rectangle {
        id: knob
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: sw.on ? parent.width - width - 3 : 3
        antialiasing: true
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.12)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 1.0; color: "#dfe7f1" }
        }
        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        enabled: sw.enabledSwitch
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.on)
    }
}
