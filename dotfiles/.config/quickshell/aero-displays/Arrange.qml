import QtQuick

Item {
    id: a
    property var pal
    property real ew: 1920
    property real eh: 1080
    property real lw: 1536
    property real lh: 864
    property string side: "right"
    property real offset: 0.5
    property string extName: "Monitor"
    property string lapName: "Laptop"
    property bool hudOnLaptop: false
    signal moved(string side, real offset)

    property bool dragging: false
    property real dragX: 0
    property real dragY: 0
    property real grabX: 0
    property real grabY: 0
    property real frozenX: 0
    property real frozenY: 0
    property string hold: ""
    property real holdOff: 0.5
    readonly property string effSide: hold.length ? hold : side
    readonly property real effOff: hold.length ? holdOff : offset
    property string liveSide: effSide
    property real liveOffset: effOff

    readonly property real k: Math.max(0.01, Math.min(width * 0.9 / (ew + lw), height * 0.86 / (eh + lh)))
    readonly property real mw: ew * k
    readonly property real mh: eh * k
    readonly property real pw: lw * k
    readonly property real ph: lh * k

    function rel(s, o) {
        if (s === "left") return [-pw, o * (mh - ph)]
        if (s === "above") return [o * (mw - pw), -ph]
        if (s === "below") return [o * (mw - pw), mh]
        return [mw, o * (mh - ph)]
    }

    readonly property var restRel: rel(effSide, effOff)
    readonly property real restMX: (width - (Math.max(mw, restRel[0] + pw) - Math.min(0, restRel[0]))) / 2 - Math.min(0, restRel[0])
    readonly property real restMY: (height - (Math.max(mh, restRel[1] + ph) - Math.min(0, restRel[1]))) / 2 - Math.min(0, restRel[1])
    readonly property real monX: dragging ? frozenX : restMX
    readonly property real monY: dragging ? frozenY : restMY
    readonly property var ghostRel: rel(liveSide, liveOffset)

    function magnet(v) {
        var marks = [0, 0.5, 1]
        for (var i = 0; i < marks.length; i++) {
            if (Math.abs(v - marks[i]) < 0.06) return marks[i]
        }
        return v
    }

    function snap(px, py) {
        var cx = px + pw / 2 - (monX + mw / 2)
        var cy = py + ph / 2 - (monY + mh / 2)
        var s, o, d
        if (Math.abs(cx) / (mw + pw) >= Math.abs(cy) / (mh + ph)) {
            s = cx > 0 ? "right" : "left"
            d = mh - ph
            o = Math.abs(d) < 2 ? 0.5 : (py - monY) / d
        } else {
            s = cy > 0 ? "below" : "above"
            d = mw - pw
            o = Math.abs(d) < 2 ? 0.5 : (px - monX) / d
        }
        liveSide = s
        liveOffset = magnet(Math.max(0, Math.min(1, o)))
    }

    onSideChanged: hold = ""
    onOffsetChanged: hold = ""

    Timer {
        running: a.hold.length > 0
        interval: 15000
        onTriggered: a.hold = ""
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: a.pal.field
        border.width: 1
        border.color: a.pal.fieldBorder
        clip: true

        Repeater {
            model: Math.max(0, Math.ceil(a.width / 24))
            Rectangle {
                x: index * 24
                width: 1
                height: a.height
                color: a.pal.grid
                opacity: 0.35
            }
        }
        Repeater {
            model: Math.max(0, Math.ceil(a.height / 24))
            Rectangle {
                y: index * 24
                width: a.width
                height: 1
                color: a.pal.grid
                opacity: 0.35
            }
        }
    }

    Rectangle {
        id: ghost
        visible: a.dragging
        x: a.monX + a.ghostRel[0]
        y: a.monY + a.ghostRel[1]
        width: a.pw
        height: a.ph
        radius: 6
        color: a.pal.ghost
        border.width: 2
        border.color: a.pal.select
        antialiasing: true
    }

    Rectangle {
        id: mon
        x: a.monX
        y: a.monY
        width: a.mw
        height: a.mh
        radius: 7
        antialiasing: true
        border.width: 2
        border.color: Qt.lighter(a.pal.sky, 1.2)
        Behavior on x { enabled: !a.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: !a.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: a.pal.shell0 }
            GradientStop { position: 0.5; color: a.pal.shell2 }
            GradientStop { position: 1.0; color: a.pal.shell4 }
        }
        Rectangle {
            x: 4; y: 3
            width: parent.width - 8
            height: parent.height * 0.42
            radius: 5
            color: Qt.rgba(1, 1, 1, 0.22)
        }
        Column {
            anchors.centerIn: parent
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "1"
                font.family: "Exo 2"
                font.weight: Font.Black
                font.pixelSize: Math.min(44, mon.height * 0.42)
                color: "#ffffff"
                style: Text.Raised
                styleColor: "#660b0d12"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: mon.width - 16
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: a.extName
                font.family: "Exo 2"
                font.weight: Font.Bold
                font.pixelSize: 11
                color: "#e6f4ff"
            }
        }
        Text {
            visible: !a.hudOnLaptop
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0430}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: "#ccffffff"
        }
    }

    Rectangle {
        id: lap
        x: a.dragging ? a.dragX : a.monX + a.restRel[0]
        y: a.dragging ? a.dragY : a.monY + a.restRel[1]
        width: a.pw
        height: a.ph
        radius: 6
        antialiasing: true
        border.width: 2
        border.color: drag.containsMouse || a.dragging ? "#ffffff" : Qt.lighter(a.pal.sky, 1.2)
        scale: a.dragging ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
        Behavior on x { enabled: !a.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on y { enabled: !a.dragging; NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: a.pal.fill0 }
            GradientStop { position: 0.5; color: a.pal.fill1 }
            GradientStop { position: 1.0; color: a.pal.fill2 }
        }
        Rectangle {
            x: 4; y: 3
            width: parent.width - 8
            height: parent.height * 0.42
            radius: 5
            color: Qt.rgba(1, 1, 1, 0.28)
        }
        Column {
            anchors.centerIn: parent
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "2"
                font.family: "Exo 2"
                font.weight: Font.Black
                font.pixelSize: Math.min(38, lap.height * 0.42)
                color: "#ffffff"
                style: Text.Raised
                styleColor: "#660b0d12"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: a.lapName
                font.family: "Exo 2"
                font.weight: Font.Bold
                font.pixelSize: 11
                color: "#e6f4ff"
            }
        }
        Text {
            visible: a.hudOnLaptop
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0430}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color: "#ccffffff"
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: a.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            onPressed: function(m) {
                a.frozenX = a.monX
                a.frozenY = a.monY
                a.dragX = lap.x
                a.dragY = lap.y
                var p = mapToItem(a, m.x, m.y)
                a.grabX = p.x - lap.x
                a.grabY = p.y - lap.y
                a.liveSide = a.effSide
                a.liveOffset = a.effOff
                a.dragging = true
            }
            onPositionChanged: function(m) {
                if (!a.dragging) return
                var p = mapToItem(a, m.x, m.y)
                a.dragX = Math.max(2, Math.min(a.width - a.pw - 2, p.x - a.grabX))
                a.dragY = Math.max(2, Math.min(a.height - a.ph - 2, p.y - a.grabY))
                a.snap(a.dragX, a.dragY)
            }
            onReleased: {
                var s = a.liveSide
                var o = a.liveOffset
                var same = s === a.effSide && Math.abs(o - a.effOff) < 0.001
                a.holdOff = o
                a.hold = s
                a.dragging = false
                if (!same) a.moved(s, o)
            }
            onCanceled: a.dragging = false
        }
    }
}
