import QtQuick

Card {
    id: w
    property var core
    readonly property var s: core ? core.sys : ({})
    readonly property bool twoCols: body.width >= 330
    readonly property var rows: [
        { k: "CPU", g: "\u{F0EE0}", v: (s.cpu || 0) / 100, t: (s.cpu || 0) + "%", warn: (s.cpu || 0) > 85 },
        { k: "RAM", g: "\u{F035B}", v: (s.mem || 0) / 100, t: (s.memUsed || 0) + " / " + (s.memTotal || 0) + "G", warn: (s.mem || 0) > 88 },
        { k: "TEMP", g: "\u{F050F}", v: Math.min(1, (s.temp || 0) / 100), t: (s.temp || 0) + "°C", warn: (s.temp || 0) > 85 },
        { k: "DISK", g: "\u{F02CA}", v: (s.disk || 0) / 100, t: (s.diskUsed || 0) + " / " + (s.diskTotal || 0) + "G", warn: (s.disk || 0) > 90 }
    ]
    readonly property int perCol: twoCols ? 2 : 4
    readonly property real rowH: Math.max(30, Math.min(48, body.height / perCol))
    title: "SYSTEM"
    tag: "LOAD " + (s.load || "0")

    Grid {
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        columns: w.twoCols ? 2 : 1
        columnSpacing: 18
        rowSpacing: 0

        Repeater {
            model: w.rows
            delegate: Item {
                required property var modelData
                width: w.twoCols ? (w.body.width - 18) / 2 : w.body.width
                height: w.rowH

                Text {
                    id: ic
                    y: parent.height - 24
                    text: modelData.g
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: modelData.warn ? w.pal.bad : w.pal.accent
                }
                Text {
                    anchors.left: ic.right
                    anchors.leftMargin: 8
                    y: parent.height - 27
                    text: modelData.k
                    font.family: "Michroma"
                    font.pixelSize: 8
                    color: w.pal.muted
                }
                Text {
                    anchors.right: parent.right
                    y: parent.height - 29
                    text: modelData.t
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: 11
                    color: modelData.warn ? w.pal.bad : w.pal.ink
                }
                GelBar {
                    anchors.left: ic.right
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    y: parent.height - 11
                    height: 8
                    pal: w.pal
                    value: modelData.v
                    tone: modelData.warn ? w.pal.bad : "transparent"
                }
            }
        }
    }
}
