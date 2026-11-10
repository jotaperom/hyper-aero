import QtQuick

Item {
    id: rp
    property var pal

    function spawn(x, y) {
        drop.createObject(rp, { cx: x, cy: y })
    }

    Component {
        id: drop
        Item {
            id: d
            property real cx: 0
            property real cy: 0
            property real t: 0
            x: cx - 70
            y: cy - 70
            width: 140
            height: 140

            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    readonly property real k: Math.max(0, Math.min(1, d.t * 1.25 - index * 0.16))
                    anchors.centerIn: parent
                    width: 10 + k * (110 - index * 18)
                    height: width
                    radius: width / 2
                    color: index === 0 ? Qt.rgba(1, 1, 1, 0.16 * (1 - k)) : "transparent"
                    border.width: 3 - index * 0.7
                    border.color: Qt.rgba(rp.pal ? rp.pal.accent.r : 0.08, rp.pal ? rp.pal.accent.g : 0.27, rp.pal ? rp.pal.accent.b : 0.76, 0.95 * (1 - k) * (k > 0 ? 1 : 0))
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.8 * (1 - parent.k) * (parent.k > 0 ? 1 : 0))
                    }
                }
            }

            NumberAnimation on t {
                from: 0
                to: 1
                duration: 720
                easing.type: Easing.OutCubic
                running: true
                onFinished: d.destroy()
            }
        }
    }
}
