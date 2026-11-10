import QtQuick

Item {
    id: po
    property bool active: false
    property var wins: []
    property real ox: 0
    property real oy: 0
    property var pal

    opacity: active ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: 220 } }

    Repeater {
        model: po.wins
        delegate: Rectangle {
            required property var modelData
            x: modelData.x - po.ox
            y: modelData.y - po.oy
            width: modelData.w
            height: modelData.h
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1.5
            border.color: Qt.rgba(1, 1, 1, 0.7)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 8
                color: "transparent"
                border.width: 1
                border.color: po.pal ? Qt.rgba(po.pal.glow.r, po.pal.glow.g, po.pal.glow.b, 0.6) : "#663d9be9"
            }
            Rectangle {
                x: 2
                y: 2
                width: parent.width - 4
                height: Math.min(60, parent.height * 0.18)
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
        }
    }
}
