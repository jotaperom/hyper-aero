import QtQuick

Item {
    id: s
    property var pal
    property real value: 0.5
    property list<GradientStop> stops
    property color knob: "#ffffff"
    signal moved(real v)
    signal released()
    implicitHeight: 26

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 14
        radius: 7
        antialiasing: true
        border.width: 1
        border.color: s.pal.sep
        gradient: Gradient {
            orientation: Gradient.Horizontal
            stops: s.stops
        }
        Rectangle {
            x: 2; y: 1
            width: parent.width - 4
            height: 5
            radius: 2.5
            color: Qt.rgba(1, 1, 1, 0.35)
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(s.width - width, s.value * s.width - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        antialiasing: true
        color: s.knob
        border.width: 3
        border.color: "#ffffff"
        scale: area.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: "#590b0d12"
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        function at(mx) { return Math.max(0, Math.min(1, (mx - 6) / s.width)) }
        onPressed: function(m) { s.moved(at(m.x)) }
        onPositionChanged: function(m) { if (pressed) s.moved(at(m.x)) }
        onReleased: s.released()
    }
}
