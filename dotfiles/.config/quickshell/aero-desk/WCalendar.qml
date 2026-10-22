import QtQuick

Card {
    id: w
    property var core
    readonly property var now: core ? core.now : new Date()
    property int shift: 0
    readonly property var view: new Date(now.getFullYear(), now.getMonth() + shift, 1)
    readonly property int lead: (view.getDay() + 6) % 7
    readonly property int days: new Date(view.getFullYear(), view.getMonth() + 1, 0).getDate()
    readonly property int prevDays: new Date(view.getFullYear(), view.getMonth(), 0).getDate()
    readonly property real cw: body.width / 7
    readonly property real ch: Math.max(14, (body.height - nav.height - 18) / 6)
    title: "CALENDAR"
    tag: "WEEK " + week(now)

    function week(d) {
        var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        var day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        var y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return String(Math.ceil(((t - y0) / 86400000 + 1) / 7)).padStart(2, "0")
    }

    Timer {
        interval: 60000
        running: w.shift !== 0
        onTriggered: w.shift = 0
    }

    Item {
        id: nav
        width: parent.width
        height: 22

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale("C").toString(w.view, "MMMM yyyy").toUpperCase()
            font.family: "Michroma"
            font.pixelSize: Math.max(9, Math.min(13, w.cw * 0.26))
            color: w.pal.ink
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Repeater {
                model: [["\u{F0141}", -1], ["\u{F0143}", 0], ["\u{F0142}", 1]]
                delegate: Rectangle {
                    required property var modelData
                    width: 22; height: 22; radius: 11
                    visible: modelData[1] !== 0 || w.shift !== 0
                    color: navArea.containsMouse ? w.pal.hover : "transparent"
                    border.width: 1
                    border.color: w.pal.sep
                    Text {
                        anchors.centerIn: parent
                        text: modelData[1] === 0 ? "•" : modelData[0]
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: w.pal.accent
                    }
                    MouseArea {
                        id: navArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: w.shift = modelData[1] === 0 ? 0 : w.shift + modelData[1]
                    }
                }
            }
        }
    }

    Row {
        id: head
        y: nav.height + 4
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            delegate: Text {
                required property string modelData
                required property int index
                width: w.cw
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
                font.pixelSize: 9
                color: index >= 5 ? w.pal.accent : w.pal.muted
            }
        }
    }

    Grid {
        y: head.y + 16
        columns: 7
        Repeater {
            model: 42
            delegate: Item {
                required property int index
                readonly property int n: index - w.lead + 1
                readonly property bool inMonth: n >= 1 && n <= w.days
                readonly property int label: inMonth ? n : (n < 1 ? w.prevDays + n : n - w.days)
                readonly property bool today: inMonth && w.shift === 0 && n === w.now.getDate()
                width: w.cw
                height: w.ch
                visible: index < 35 || w.lead + w.days > 35

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height) - 2
                    height: width
                    radius: width / 2
                    visible: parent.today
                    antialiasing: true
                    border.width: 1
                    border.color: "#ccffffff"
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: w.pal.fill0 }
                        GradientStop { position: 0.5; color: w.pal.fill1 }
                        GradientStop { position: 1.0; color: w.pal.fill2 }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: parent.label
                    font.family: "Exo 2"
                    font.weight: parent.today ? Font.Black : Font.DemiBold
                    font.pixelSize: Math.max(9, Math.min(15, w.ch * 0.46))
                    color: parent.today ? "#ffffff" : (parent.inMonth ? w.pal.ink : w.pal.dim)
                }
            }
        }
    }
}
