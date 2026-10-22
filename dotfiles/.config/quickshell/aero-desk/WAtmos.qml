import QtQuick

Card {
    id: w
    property var core
    readonly property var wx: core ? core.weather : ({ ok: false })
    readonly property bool roomy: body.height >= 96
    readonly property bool wide: body.width >= 300
    readonly property real big: Math.max(22, Math.min(54, body.height * (roomy ? 0.3 : 0.62), body.width * 0.16))
    title: "ATMOS"
    tag: wx.ok ? wx.place : "NO SIGNAL"

    Row {
        id: top
        y: w.roomy ? 4 : Math.max(0, (parent.height - height) / 2)
        spacing: 12
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: w.big * 1.25
            horizontalAlignment: Text.AlignHCenter
            text: w.wx.ok ? w.wx.icon : "—"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: w.big * 1.15
            color: w.pal.accent
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Row {
                Text {
                    id: tmp
                    text: w.wx.temp
                    font.family: "Michroma"
                    font.pixelSize: w.big * 0.8
                    color: w.pal.ink
                }
                Text {
                    text: "°C"
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: 12
                    color: w.pal.muted
                }
            }
            Text {
                width: Math.max(60, w.body.width - w.big * 1.25 - 12)
                elide: Text.ElideRight
                text: w.wx.ok ? w.wx.desc : "Weather unavailable"
                font.family: "Exo 2"
                font.weight: Font.Bold
                font.pixelSize: 12
                color: w.pal.muted
            }
        }
    }

    Item {
        visible: w.roomy
        anchors.bottom: parent.bottom
        width: parent.width
        height: w.wide ? 30 : 54

        DashLine {
            width: parent.width
            color: w.pal.sep
        }

        Grid {
            y: 9
            width: parent.width
            columns: w.wide ? 4 : 3
            rowSpacing: 6
            columnSpacing: 0
            Repeater {
                model: [["HI", w.wx.hi + "°"], ["LO", w.wx.lo + "°"], ["HUM", w.wx.hum + "%"], ["WIND", w.wx.wind]]
                delegate: Row {
                    required property var modelData
                    width: w.body.width / (w.wide ? 4 : 3)
                    spacing: 6
                    Text {
                        text: modelData[0]
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 9
                        color: w.pal.muted
                        anchors.baseline: val.baseline
                    }
                    Text {
                        id: val
                        text: modelData[1]
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 12
                        color: w.pal.ink
                    }
                }
            }
        }
    }
}
