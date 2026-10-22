import QtQuick

Item {
    id: bar
    property var pal
    property real value: 0
    property color tone: "transparent"
    implicitHeight: 10

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        color: bar.pal.track
        border.width: 1
        border.color: bar.pal.sep
    }

    Rectangle {
        width: Math.max(height, (bar.width - 2) * Math.max(0, Math.min(1, bar.value)))
        height: bar.height - 2
        x: 1
        y: 1
        radius: height / 2
        antialiasing: true
        visible: bar.value > 0.005
        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: bar.tone.a > 0 ? Qt.lighter(bar.tone, 1.35) : bar.pal.fill0 }
            GradientStop { position: 0.5; color: bar.tone.a > 0 ? bar.tone : bar.pal.fill1 }
            GradientStop { position: 1.0; color: bar.tone.a > 0 ? Qt.darker(bar.tone, 1.25) : bar.pal.fill2 }
        }
        Rectangle {
            x: 2; y: 1
            width: parent.width - 4
            height: parent.height * 0.42
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.55)
        }
    }
}
