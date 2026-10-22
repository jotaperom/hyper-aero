import QtQuick

Card {
    id: w
    property var core
    readonly property var now: core ? core.now : new Date()
    readonly property int off: -now.getTimezoneOffset()
    readonly property bool showDate: body.height >= 62
    readonly property bool showFoot: body.height >= 104
    readonly property real timeSize: Math.max(18, Math.min(body.width / 3.9, (body.height - (showDate ? 24 : 0) - (showFoot ? 30 : 0)) / 1.42, 132))
    title: "CHRONO"
    tag: "LOCAL · UTC" + (off >= 0 ? "+" : "−") + Math.abs(off / 60)

    Column {
        width: parent.width
        y: Math.max(0, (parent.height - (w.showFoot ? 30 : 0) - height) / 2)
        spacing: 2

        Row {
            spacing: w.timeSize * 0.12
            Text {
                id: hm
                text: Qt.formatTime(w.now, "HH:mm")
                font.family: "Michroma"
                font.pixelSize: w.timeSize
                color: w.pal.ink
                style: w.core && w.core.night ? Text.Outline : Text.Normal
                styleColor: "#226fd3ff"
            }
            Text {
                anchors.baseline: hm.baseline
                text: Qt.formatTime(w.now, "ss")
                font.family: "Michroma"
                font.pixelSize: Math.max(10, w.timeSize * 0.29)
                color: w.pal.accent
            }
        }

        Text {
            visible: w.showDate
            width: parent.width
            elide: Text.ElideRight
            text: Qt.locale("C").toString(w.now, "dddd  ·  d MMMM yyyy")
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: Math.max(11, Math.min(16, w.timeSize * 0.27))
            color: w.pal.muted
        }
    }

    Item {
        visible: w.showFoot
        anchors.bottom: parent.bottom
        width: parent.width
        height: 22

        DashLine {
            width: parent.width
            color: w.pal.sep
        }
        Row {
            y: 8
            spacing: 18
            Repeater {
                model: [
                    "DAY " + w.doy(w.now),
                    "WEEK " + w.week(w.now),
                    "T+ " + (w.core ? w.core.sys.uptime : "")
                ]
                delegate: Text {
                    required property string modelData
                    text: modelData
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: 9
                    color: w.pal.muted
                }
            }
        }
    }

    function doy(d) {
        var start = new Date(d.getFullYear(), 0, 0)
        return String(Math.floor((d - start + (start.getTimezoneOffset() - d.getTimezoneOffset()) * 60000) / 86400000)).padStart(3, "0")
    }

    function week(d) {
        var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        var day = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - day)
        var y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return String(Math.ceil(((t - y0) / 86400000 + 1) / 7)).padStart(2, "0")
    }
}
