import QtQuick

Card {
    id: w
    property var core
    readonly property var p: core ? core.player : null
    readonly property bool live: !!(core && core.bars.length)
    readonly property int count: Math.max(8, Math.min(48, Math.floor(body.width / 9)))
    property real phase: 0
    title: "SPECTRA"
    tag: p && p.trackTitle ? String(p.trackTitle).toUpperCase() : "IDLE"

    NumberAnimation on phase {
        running: !w.live
        from: 0
        to: Math.PI * 2
        duration: 6000
        loops: Animation.Infinite
    }

    Row {
        id: bars
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.22
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.height * 0.78
        spacing: Math.max(2, (w.body.width - w.count * 6) / w.count)

        Repeater {
            model: w.count
            delegate: Item {
                required property int index
                readonly property real v: w.live
                    ? (w.core.bars[Math.floor(index * w.core.bars.length / w.count)] || 0)
                    : 0.06 + 0.05 * Math.sin(w.phase + index * 0.45)
                width: Math.max(4, (w.body.width - bars.spacing * (w.count - 1)) / w.count)
                height: bars.height

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: Math.max(3, parent.height * parent.v)
                    radius: width / 2
                    antialiasing: true
                    Behavior on height { NumberAnimation { duration: 90 } }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: w.pal.fill0 }
                        GradientStop { position: 0.5; color: w.pal.fill1 }
                        GradientStop { position: 1.0; color: w.pal.fill2 }
                    }
                    Rectangle {
                        x: 1; y: 1
                        width: Math.max(1, parent.width * 0.4)
                        height: parent.height - 2
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, 0.45)
                    }
                }
            }
        }
    }

    Row {
        anchors.top: bars.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: bars.horizontalCenter
        spacing: bars.spacing
        opacity: 0.22
        Repeater {
            model: w.count
            delegate: Rectangle {
                required property int index
                readonly property real v: w.live
                    ? (w.core.bars[Math.floor(index * w.core.bars.length / w.count)] || 0)
                    : 0.06 + 0.05 * Math.sin(w.phase + index * 0.45)
                width: Math.max(4, (w.body.width - bars.spacing * (w.count - 1)) / w.count)
                height: Math.max(1, w.body.height * 0.2 * v)
                radius: width / 2
                color: w.pal.fill1
            }
        }
    }
}
