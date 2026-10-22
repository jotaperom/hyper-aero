import QtQuick
import QtQuick.Shapes
import "Registry.js" as Reg

FocusScope {
    id: ed
    property var core
    readonly property var pal: core.pal
    property int cols: 1
    property int rows: 1
    property int cell: 48
    property real ox: 0
    property real oy: 0
    readonly property int gap: 6
    property int act: -1
    property string mode: ""
    property real sx: 0
    property real sy: 0
    property real mx: 0
    property real my: 0
    property var orig: null
    property var cand: null
    property bool valid: true
    property string carryId: ""
    property string toastText: ""
    property bool trayOpen: true
    property int stamp: 0
    property int rev: 0
    readonly property bool busy: mode === "move" || mode === "resize"
    signal finished()

    ListModel { id: draft }

    function fit(spec) {
        var reg = Reg.find(spec.id)
        var w = Math.min(cols, Math.max(reg ? reg.minW : 1, spec.w))
        var h = Math.min(rows, Math.max(reg ? reg.minH : 1, spec.h))
        return { id: spec.id, c: Math.max(0, Math.min(cols - w, spec.c)), r: Math.max(0, Math.min(rows - h, spec.r)), w: w, h: h }
    }

    function begin() {
        draft.clear()
        var list = core.layout
        for (var i = 0; i < list.length; i++) {
            var s = fit(list[i])
            draft.append({ wid: s.id, c: s.c, r: s.r, w: s.w, h: s.h })
        }
        act = -1
        mode = ""
        cand = null
        trayOpen = true
        stamp++
        rev++
        forceActiveFocus()
    }

    Connections {
        target: ed.core
        function onEditingChanged() {
            if (ed.core.editing) ed.begin()
        }
    }

    function specAt(i) {
        var o = draft.get(i)
        return { id: o.wid, c: o.c, r: o.r, w: o.w, h: o.h }
    }

    function overlaps(a, b) {
        return a.c < b.c + b.w && b.c < a.c + a.w && a.r < b.r + b.h && b.r < a.r + a.h
    }

    function fits(spec, skip) {
        if (spec.c < 0 || spec.r < 0 || spec.c + spec.w > cols || spec.r + spec.h > rows) return false
        for (var i = 0; i < draft.count; i++) {
            if (i === skip) continue
            if (overlaps(spec, specAt(i))) return false
        }
        return true
    }

    function findSpot(w, h) {
        for (var r = 0; r + h <= rows; r++) {
            for (var c = 0; c + w <= cols; c++) {
                if (fits({ c: c, r: r, w: w, h: h }, -1)) return { c: c, r: r }
            }
        }
        return null
    }

    function indexOf(wid) {
        for (var i = 0; i < draft.count; i++) {
            if (draft.get(i).wid === wid) return i
        }
        return -1
    }

    function toast(t) {
        toastText = t
        toastTimer.restart()
    }

    function addWidget(wid) {
        var reg = Reg.find(wid)
        if (!reg || indexOf(wid) >= 0) return
        var w = reg.w, h = reg.h
        var at = findSpot(w, h)
        if (!at) {
            w = reg.minW
            h = reg.minH
            at = findSpot(w, h)
        }
        if (!at) {
            toast("No hay espacio libre para " + reg.name)
            return
        }
        draft.append({ wid: wid, c: at.c, r: at.r, w: w, h: h })
        rev++
    }

    function removeAt(i) {
        if (i >= 0 && i < draft.count) draft.remove(i)
        rev++
    }

    function reset() {
        draft.clear()
        var list = Reg.defaults(cols, rows)
        for (var i = 0; i < list.length; i++) {
            var s = fit(list[i])
            draft.append({ wid: s.id, c: s.c, r: s.r, w: s.w, h: s.h })
        }
        rev++
        toast("Diseño original restablecido")
    }

    function done() {
        var out = []
        for (var i = 0; i < draft.count; i++) out.push(specAt(i))
        core.setLayout(out)
        core.editing = false
        finished()
    }

    function cancel() {
        core.editing = false
        finished()
    }

    function pxX(c) { return ox + c * cell }
    function pxY(r) { return oy + r * cell }

    function startDrag(i, m, p) {
        act = i
        mode = m
        sx = p.x
        sy = p.y
        mx = p.x
        my = p.y
        orig = specAt(i)
        cand = orig
        valid = true
    }

    function moveDrag(p) {
        if (act < 0 || !orig) return
        mx = p.x
        my = p.y
        var s = orig
        var dx = p.x - sx
        var dy = p.y - sy
        var reg = Reg.find(s.id)
        if (mode === "move") {
            var c = Math.max(0, Math.min(cols - s.w, Math.round((pxX(s.c) + dx - ox) / cell)))
            var r = Math.max(0, Math.min(rows - s.h, Math.round((pxY(s.r) + dy - oy) / cell)))
            cand = { id: s.id, c: c, r: r, w: s.w, h: s.h }
        } else if (mode === "resize") {
            var w = Math.max(reg.minW, Math.min(cols - s.c, Math.round((s.w * cell + dx) / cell)))
            var h = Math.max(reg.minH, Math.min(rows - s.r, Math.round((s.h * cell + dy) / cell)))
            cand = { id: s.id, c: s.c, r: s.r, w: w, h: h }
        }
        valid = fits(cand, act)
    }

    function endDrag() {
        if (act >= 0 && cand && valid) draft.set(act, { c: cand.c, r: cand.r, w: cand.w, h: cand.h })
        else if (act >= 0 && cand && !valid) toast("Ese espacio está ocupado")
        act = -1
        mode = ""
        cand = null
        orig = null
    }

    function startCarry(wid, p) {
        carryId = wid
        mode = "carry"
        moveCarry(p)
    }

    function moveCarry(p) {
        var reg = Reg.find(carryId)
        if (!reg) return
        mx = p.x
        my = p.y
        var sizes = [[reg.w, reg.h], [reg.minW, reg.minH]]
        for (var k = 0; k < sizes.length; k++) {
            var w = sizes[k][0], h = sizes[k][1]
            var c = Math.max(0, Math.min(cols - w, Math.round((p.x - ox) / cell - w / 2)))
            var r = Math.max(0, Math.min(rows - h, Math.round((p.y - oy) / cell - h / 2)))
            cand = { id: carryId, c: c, r: r, w: w, h: h }
            valid = fits(cand, -1)
            if (valid) return
        }
    }

    function endCarry() {
        var overTray = tray.contains(tray.mapFromItem(ed, mx, my)) && trayOpen
        if (cand && valid && !overTray) {
            draft.append({ wid: cand.id, c: cand.c, r: cand.r, w: cand.w, h: cand.h })
            rev++
        } else if (!overTray) {
            toast("No cabe ahí")
        }
        mode = ""
        carryId = ""
        cand = null
    }

    Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Escape) {
            if (ed.mode.length) {
                ed.act = -1
                ed.mode = ""
                ed.cand = null
            } else {
                ed.cancel()
            }
            e.accepted = true
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            ed.done()
            e.accepted = true
        }
    }

    Timer {
        id: toastTimer
        interval: 1800
        onTriggered: ed.toastText = ""
    }

    Rectangle {
        anchors.fill: parent
        color: ed.pal.scrim
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
        }
    }

    Canvas {
        id: gridCanvas
        x: ed.ox
        y: ed.oy
        width: ed.cols * ed.cell + 1
        height: ed.rows * ed.cell + 1
        property color line: ed.pal.grid
        property color dot: ed.pal.gridDot
        onLineChanged: requestPaint()
        onDotChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        opacity: 0
        Component.onCompleted: requestPaint()
        NumberAnimation on opacity {
            id: gridIn
            to: 1
            duration: 420
            easing.type: Easing.OutCubic
        }
        Connections {
            target: ed
            function onStampChanged() {
                gridCanvas.opacity = 0
                gridIn.restart()
            }
        }
        onPaint: {
            var g = getContext("2d")
            g.reset()
            g.strokeStyle = line
            g.lineWidth = 1
            g.beginPath()
            for (var c = 0; c <= ed.cols; c++) {
                g.moveTo(c * ed.cell + 0.5, 0)
                g.lineTo(c * ed.cell + 0.5, ed.rows * ed.cell)
            }
            for (var r = 0; r <= ed.rows; r++) {
                g.moveTo(0, r * ed.cell + 0.5)
                g.lineTo(ed.cols * ed.cell, r * ed.cell + 0.5)
            }
            g.stroke()
            g.fillStyle = dot
            for (var i = 0; i <= ed.cols; i++) {
                for (var j = 0; j <= ed.rows; j++) {
                    g.beginPath()
                    g.arc(i * ed.cell + 0.5, j * ed.cell + 0.5, 1.6, 0, Math.PI * 2)
                    g.fill()
                }
            }
        }
    }

    Repeater {
        model: [[0, 0, 1, 1], [1, 0, -1, 1], [0, 1, 1, -1], [1, 1, -1, -1]]
        delegate: Shape {
            required property var modelData
            x: ed.ox - 8 + modelData[0] * (ed.cols * ed.cell + 16)
            y: ed.oy - 8 + modelData[1] * (ed.rows * ed.cell + 16)
            width: 1
            height: 1
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: ed.pal.select
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                startX: modelData[2] * 22; startY: 0
                PathLine { x: 0; y: 0 }
                PathLine { x: 0; y: modelData[3] * 22 }
            }
        }
    }

    Rectangle {
        id: ghost
        visible: ed.cand !== null && ed.mode.length > 0
        x: ed.cand ? ed.pxX(ed.cand.c) + ed.gap : 0
        y: ed.cand ? ed.pxY(ed.cand.r) + ed.gap : 0
        width: ed.cand ? ed.cand.w * ed.cell - ed.gap * 2 : 0
        height: ed.cand ? ed.cand.h * ed.cell - ed.gap * 2 : 0
        radius: 20
        color: ed.valid ? ed.pal.ghost : "#33ff4d5e"
        border.width: 2
        border.color: ed.valid ? ed.pal.select : "#ff4d5e"
        Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
    }

    Repeater {
        model: draft
        delegate: Item {
            id: it
            required property int index
            required property string wid
            required property int c
            required property int r
            required property int w
            required property int h
            readonly property bool held: ed.act === index && ed.mode.length > 0
            readonly property bool sizing: held && ed.mode === "resize" && ed.cand !== null
            readonly property int sw: sizing ? ed.cand.w : w
            readonly property int shh: sizing ? ed.cand.h : h
            readonly property var reg: Reg.find(wid)
            x: held && ed.mode === "move" ? ed.pxX(c) + ed.gap + (ed.mx - ed.sx) : ed.pxX(c) + ed.gap
            y: held && ed.mode === "move" ? ed.pxY(r) + ed.gap + (ed.my - ed.sy) : ed.pxY(r) + ed.gap
            width: sw * ed.cell - ed.gap * 2
            height: shh * ed.cell - ed.gap * 2
            z: held ? 20 : 2
            Behavior on x { enabled: !it.held; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { enabled: !it.held; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

            WidgetFrame {
                anchors.fill: parent
                wid: it.wid
                core: ed.core
                opacity: it.held && !ed.valid ? 0.55 : 1
                scale: it.held && ed.mode === "move" ? 1.02 : 1
                Behavior on scale { NumberAnimation { duration: 140 } }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 23
                color: "transparent"
                border.width: it.held || body.containsMouse ? 2 : 1
                border.color: ed.pal.select
                opacity: it.held || body.containsMouse ? 1 : 0.55
            }

            MouseArea {
                id: body
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: function(m) {
                    if (m.button === Qt.RightButton) {
                        ed.removeAt(it.index)
                        return
                    }
                    ed.startDrag(it.index, "move", mapToItem(ed, m.x, m.y))
                }
                onPositionChanged: function(m) {
                    if (pressed && ed.mode === "move") ed.moveDrag(mapToItem(ed, m.x, m.y))
                }
                onReleased: if (ed.mode === "move") ed.endDrag()
            }

            Rectangle {
                x: 10
                y: -11
                height: 20
                width: chip.implicitWidth + 20
                radius: 10
                color: ed.pal.select
                border.width: 1
                border.color: "#ccffffff"
                Text {
                    id: chip
                    anchors.centerIn: parent
                    text: it.reg ? it.reg.glyph + "  " + it.reg.name : it.wid
                    font.family: "Michroma"
                    font.pixelSize: 8
                    color: "#ffffff"
                }
            }

            Rectangle {
                x: parent.width - 14
                y: -10
                width: 24
                height: 24
                radius: 12
                antialiasing: true
                border.width: 1
                border.color: "#ccffffff"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: closeArea.containsMouse ? "#ff8d98" : "#f2f5f8" }
                    GradientStop { position: 1.0; color: closeArea.containsMouse ? "#d6304a" : "#c9d3de" }
                }
                Text {
                    anchors.centerIn: parent
                    text: "\u{F0156}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: closeArea.containsMouse ? "#ffffff" : "#c4283b"
                }
                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ed.removeAt(it.index)
                }
            }

            Rectangle {
                x: parent.width - 18
                y: parent.height - 18
                width: 28
                height: 28
                radius: 14
                antialiasing: true
                border.width: 1
                border.color: "#e6ffffff"
                scale: knob.pressed ? 1.15 : (knob.containsMouse ? 1.08 : 1)
                Behavior on scale { NumberAnimation { duration: 110 } }
                gradient: Gradient {
                    GradientStop { position: 0.0; color: ed.pal.fill0 }
                    GradientStop { position: 0.5; color: ed.pal.fill1 }
                    GradientStop { position: 1.0; color: ed.pal.fill2 }
                }
                Text {
                    anchors.centerIn: parent
                    text: "\u{F045D}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: "#ffffff"
                }
                MouseArea {
                    id: knob
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.SizeFDiagCursor
                    onPressed: function(m) { ed.startDrag(it.index, "resize", mapToItem(ed, m.x, m.y)) }
                    onPositionChanged: function(m) {
                        if (pressed && ed.mode === "resize") ed.moveDrag(mapToItem(ed, m.x, m.y))
                    }
                    onReleased: if (ed.mode === "resize") ed.endDrag()
                }
            }

            Rectangle {
                visible: it.sizing
                anchors.centerIn: parent
                width: sizeText.implicitWidth + 24
                height: 30
                radius: 15
                color: "#cc0b1426"
                border.width: 1
                border.color: ed.valid ? ed.pal.select : "#ff4d5e"
                Text {
                    id: sizeText
                    anchors.centerIn: parent
                    text: it.sw + " × " + it.shh
                    font.family: "Michroma"
                    font.pixelSize: 12
                    color: "#ffffff"
                }
            }
        }
    }

    Rectangle {
        visible: ed.mode === "carry" && ed.carryId.length > 0
        x: ed.mx - width / 2
        y: ed.my - height / 2
        z: 30
        width: 112
        height: 70
        radius: 16
        opacity: 0.92
        border.width: 2
        border.color: ed.valid ? ed.pal.select : "#ff4d5e"
        gradient: Gradient {
            GradientStop { position: 0.0; color: ed.pal.tray0 }
            GradientStop { position: 1.0; color: ed.pal.tray2 }
        }
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ed.carryId.length ? Reg.find(ed.carryId).glyph : ""
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 22
                color: ed.pal.accent
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ed.carryId.length ? Reg.find(ed.carryId).name : ""
                font.family: "Michroma"
                font.pixelSize: 8
                color: ed.pal.ink
            }
        }
    }

    Tray {
        id: tray
        ed: ed
        z: 25
        width: Math.min(ed.width - 40, 1240)
        anchors.horizontalCenter: parent.horizontalCenter
        y: ed.height - (ed.trayOpen && !ed.busy ? height + 14 : 26)
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        visible: opacity > 0.01
        opacity: ed.toastText.length ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        z: 40
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        width: toastLabel.implicitWidth + 36
        height: 36
        radius: 18
        color: "#e60b1426"
        border.width: 1
        border.color: ed.pal.select
        Text {
            id: toastLabel
            anchors.centerIn: parent
            text: ed.toastText
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 13
            color: "#ffffff"
        }
    }
}
