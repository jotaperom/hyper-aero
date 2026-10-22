import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint

Item {
    id: root
    property var host
    property string variant: "visor"
    readonly property alias pages: pagesItem
    readonly property var vp: Tint.palette(vBase, host.accent)
    readonly property var pal: Object.assign({}, host.pal, vp)
    readonly property var vBase: ({
        line: "#6fd3ff", deep: "#1e6fd9", amber: "#ffb347",
        fillN: "#e6040a16", fillD: "#d90a1a36",
        text: "#e6f4ff", muted: "#8fb4d6", accent: "#8fe3ff", glow: "#6fd3ff", ring: "#bdf0ff",
        tile0: "#cc1a3a66", tile1: "#cc12294d", tile2: "#cc0c1d3a", tile3: "#cc102446",
        tileBorder: "#806fd3ff", onBorder: "#e6bdf0ff",
        on0: "#8cc6f5", on1: "#3d9be9", on2: "#1446c2", on3: "#1e6fd9",
        glossTop: 0.1, badge: "#4d1e6fd9", track: "#99050c1a",
        icon0: "#cc1f3a66", icon1: "#cc142a4d", icon2: "#cc0c1d3a", iconBorder: "#996fd3ff", iconGloss: 0.14,
        field: "#cc050c1a", shelf: "#80081428", accentFill: "#1e6fd9",
        hero: "#e6f4ff", heroShadow: "#99000000", heroSub: "#a9d4f2",
        label: "#e6f4ff", labelShadow: "#e6000000", status: "#e6f4ff",
        bubble: "#cc12294d", bar0: "#1f3f86", bar1: "#0e1d44",
        blobA: "#146fd3ff", blobB: "#106fd3ff", blobC: "#0c6fd3ff", arc: "#666fd3ff",
        paper0: "#cfeeff", paper1: "#8cc6f5"
    })
    readonly property real pw: 400
    readonly property real ph: 600
    readonly property real fit: Math.min(1, height / 864)
    property real shown: 0
    property real line: 0
    property real unfold: 0
    property real lock: 0
    property real content: 0
    property real t: 0
    readonly property int bat: host.backend && host.backend.st.bat !== undefined ? host.backend.st.bat : 100
    readonly property bool wifi: host.backend && host.backend.st.wifi ? true : false

    function tint(hex, a) { return host.tint(hex, a) }

    function open() {
        closeAnim.stop()
        openAnim.restart()
    }

    function close() {
        openAnim.stop()
        closeAnim.restart()
    }

    function chamf(i) {
        var w = pw, h = ph
        var a = 36 - i * 0.41, b = 14 - i * 0.41
        return [
            Qt.point(i + a, i), Qt.point(w - i - b, i), Qt.point(w - i, i + b),
            Qt.point(w - i, h - i - a), Qt.point(w - i - a, h - i), Qt.point(i + b, h - i),
            Qt.point(i, h - i - b), Qt.point(i, i + a), Qt.point(i + a, i)
        ]
    }

    HoverHandler { id: hover }
    property real sx: hover.hovered ? hover.point.position.x / Math.max(1, width) - 0.5 : 0
    property real sy: hover.hovered ? hover.point.position.y / Math.max(1, height) - 0.5 : 0
    Behavior on sx { SmoothedAnimation { velocity: 0.7 } }
    Behavior on sy { SmoothedAnimation { velocity: 0.7 } }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 200 }
        SequentialAnimation {
            PropertyAction { target: root; property: "content"; value: 0 }
            NumberAnimation { target: root; property: "line"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "unfold"; from: 0; to: 1; duration: 420; easing.type: Easing.InOutCubic }
            ParallelAnimation {
                NumberAnimation { target: root; property: "lock"; from: 0; to: 1; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                NumberAnimation { target: root; property: "content"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }
            }
        }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "content"; to: 0; duration: 150 }
            NumberAnimation { target: root; property: "lock"; to: 0; duration: 200; easing.type: Easing.InCubic }
        }
        NumberAnimation { target: root; property: "unfold"; to: 0; duration: 260; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "line"; to: 0; duration: 180 }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 200 }
        }
        onFinished: if (root.host) root.host.closed()
    }

    NumberAnimation on t {
        running: root.shown > 0 && root.host.active
        from: 0
        to: 1
        duration: 12000
        loops: Animation.Infinite
    }

    Item {
        id: rig
        width: root.pw + 70
        height: root.ph + 64
        x: 30 * root.fit
        y: root.height - 18 * root.fit - height * root.fit
        transformOrigin: Item.TopLeft
        scale: root.fit
        opacity: Math.max(0, Math.min(1, root.shown * 2))

        Item {
            id: leftRail
            x: 6 + root.sx * 6
            y: 20 + root.sy * 4
            width: 20
            height: root.ph
            opacity: root.lock

            Rectangle {
                x: -2
                y: 52
                width: 20
                height: root.ph - 104
                visible: !root.host.night
                color: "#8c0a1a36"
            }
            Repeater {
                model: Math.floor((root.ph - 120) / 10) + 1
                delegate: Rectangle {
                    required property int index
                    x: index % 5 === 0 ? 4 : 10
                    y: 60 + index * 10
                    width: index % 5 === 0 ? 12 : 6
                    height: 1
                    color: root.tint(root.vp.line, index % 5 === 0 ? 0.7 : 0.35)
                }
            }
            Shape {
                x: 0
                y: 60 + root.host.page / Math.max(1, root.host.pageNames.length - 1) * (root.ph - 120) - 6
                Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutBack } }
                width: 10
                height: 12
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: root.vp.amber
                    startX: 0; startY: 0
                    PathLine { x: 9; y: 6 }
                    PathLine { x: 0; y: 12 }
                    PathLine { x: 0; y: 0 }
                }
            }
        }

        Item {
            id: rightRail
            x: 30 + root.pw + 10 + root.sx * 6
            y: 20 + root.sy * 4
            width: 26
            height: root.ph
            opacity: root.lock

            Rectangle {
                x: -4
                y: 58
                width: 26
                height: 274
                visible: !root.host.night
                color: "#8c0a1a36"
            }
            Text {
                y: 64
                text: "PWR"
                font.family: "Michroma"
                font.pixelSize: 7
                color: root.tint(root.vp.line, 0.8)
            }
            Column {
                y: 80
                spacing: 4
                Repeater {
                    model: 10
                    delegate: Rectangle {
                        required property int index
                        readonly property bool lit: (9 - index) < Math.ceil(root.bat / 10)
                        width: 16
                        height: 14
                        color: lit ? (root.bat < 25 ? root.vp.amber : root.tint(root.vp.line, 0.85)) : "transparent"
                        border.width: 1
                        border.color: root.tint(root.vp.line, 0.4)
                    }
                }
            }
            Text {
                y: 262
                text: root.bat + "%"
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
                font.pixelSize: 9
                color: root.bat < 25 ? root.vp.amber : root.vp.text
            }
            Row {
                y: 300
                spacing: 2
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        required property int index
                        y: 12 - (index + 1) * 3
                        width: 3
                        height: (index + 1) * 3
                        color: root.wifi ? root.tint(root.vp.line, 0.9) : root.tint(root.vp.line, 0.2)
                    }
                }
            }
            Text {
                y: 318
                text: root.wifi ? "NET" : "OFF"
                font.family: "Michroma"
                font.pixelSize: 7
                color: root.wifi ? root.tint(root.vp.line, 0.8) : root.vp.amber
            }
        }

        Item {
            id: frame
            x: 30
            y: 20
            width: root.pw
            height: root.ph

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.ph / 2 - 1
                width: root.pw * root.line
                height: 2
                visible: root.unfold < 0.02 && root.line > 0
                color: root.vp.ring
                Rectangle { anchors.centerIn: parent; width: parent.width; height: 12; radius: 6; color: root.tint(root.vp.line, 0.3) }
            }

            Item {
                id: reveal
                y: root.ph / 2 * (1 - root.unfold)
                width: root.pw
                height: root.ph * root.unfold
                clip: true

                Item {
                    y: -reveal.y
                    width: root.pw
                    height: root.ph

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            fillColor: root.host.night ? root.vp.fillN : root.vp.fillD
                            strokeColor: root.vp.line
                            strokeWidth: 1.6
                            joinStyle: ShapePath.MiterJoin
                            PathPolyline { path: root.chamf(0) }
                        }
                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: root.tint(root.vp.line, 0.28)
                            strokeWidth: 1
                            joinStyle: ShapePath.MiterJoin
                            PathPolyline { path: root.chamf(6) }
                        }
                    }

                    Repeater {
                        model: Math.floor((root.pw - 40) / 32)
                        delegate: Rectangle {
                            required property int index
                            x: 28 + index * 32
                            y: 52
                            width: 1
                            height: root.ph - 120
                            color: root.tint(root.vp.line, 0.05)
                        }
                    }
                    Repeater {
                        model: Math.floor((root.ph - 120) / 32) + 1
                        delegate: Rectangle {
                            required property int index
                            x: 14
                            y: 52 + index * 32
                            width: root.pw - 28
                            height: 1
                            color: root.tint(root.vp.line, 0.05)
                        }
                    }

                    Item {
                        id: head
                        x: 14
                        y: 6
                        width: root.pw - 28
                        height: 38
                        opacity: root.content

                        Item {
                            x: 26
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            height: 24
                            Shape {
                                anchors.fill: parent
                                rotation: root.t * 360 * 3
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeColor: root.vp.line
                                    strokeWidth: 2
                                    fillColor: "transparent"
                                    capStyle: ShapePath.FlatCap
                                    PathAngleArc { centerX: 12; centerY: 12; radiusX: 10; radiusY: 10; startAngle: 0; sweepAngle: 100 }
                                    PathMove { x: 12 + 10 * Math.cos(Math.PI); y: 12 }
                                    PathAngleArc { centerX: 12; centerY: 12; radiusX: 10; radiusY: 10; startAngle: 180; sweepAngle: 100 }
                                }
                            }
                            Shape {
                                anchors.fill: parent
                                rotation: -root.t * 360 * 5
                                preferredRendererType: Shape.CurveRenderer
                                ShapePath {
                                    strokeColor: root.vp.amber
                                    strokeWidth: 1.5
                                    fillColor: "transparent"
                                    PathAngleArc { centerX: 12; centerY: 12; radiusX: 5; radiusY: 5; startAngle: 0; sweepAngle: 240 }
                                }
                            }
                        }
                        Text {
                            x: 58
                            anchors.verticalCenter: parent.verticalCenter
                            text: "VISOR"
                            font.family: "Michroma"
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            color: root.vp.text
                        }
                        Text {
                            x: 132
                            anchors.verticalCenter: parent.verticalCenter
                            text: "// " + root.host.pageNames[root.host.page].toUpperCase()
                            font.family: "Michroma"
                            font.pixelSize: 8
                            font.letterSpacing: 1
                            color: root.vp.muted
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatTime(root.host.now, "HH:mm:ss")
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 11
                            color: root.vp.text
                        }
                    }

                    Row {
                        x: 22
                        y: 44
                        spacing: 3
                        opacity: root.content
                        Repeater {
                            model: 39
                            delegate: Rectangle {
                                required property int index
                                readonly property real d: Math.abs(index - (root.t * 6 % 1) * 39)
                                width: 6
                                height: 3
                                color: root.tint(root.vp.line, d < 2.5 ? 0.95 : 0.22)
                            }
                        }
                    }

                    Pages {
                        id: pagesItem
                        host: root.host
                        pal: root.pal
                        x: 12
                        y: 54
                        width: root.pw - 24
                        height: root.ph - 54 - 64
                        compact: true
                        reveal: root.content
                        opacity: root.content
                    }

                    Rectangle {
                        y: (root.t * 3 % 1) * (root.ph + 50) - 50
                        width: root.pw
                        height: 50
                        visible: root.content > 0.99
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.9; color: root.tint(root.vp.line, 0.06) }
                            GradientStop { position: 1.0; color: root.tint(root.vp.line, 0.2) }
                        }
                    }

                    Row {
                        id: tabs
                        x: 26
                        y: root.ph - 50
                        spacing: 6
                        opacity: root.content
                        Repeater {
                            model: root.host.pageNames.length + 1
                            delegate: Item {
                                id: tab
                                required property int index
                                readonly property bool closer: index === root.host.pageNames.length
                                readonly property bool on: !closer && root.host.page === index
                                readonly property string ink: closer ? root.vp.amber : root.vp.line
                                width: closer ? 48 : 90
                                height: 30
                                Shape {
                                    anchors.fill: parent
                                    preferredRendererType: Shape.CurveRenderer
                                    ShapePath {
                                        fillColor: tab.on ? root.tint(tab.ink, 0.38) : (ta.containsMouse ? root.tint(tab.ink, 0.16) : root.tint(tab.ink, 0.04))
                                        strokeColor: root.tint(tab.ink, tab.on ? 1 : 0.55)
                                        strokeWidth: 1.2
                                        joinStyle: ShapePath.MiterJoin
                                        startX: 10; startY: 0
                                        PathLine { x: tab.width; y: 0 }
                                        PathLine { x: tab.width - 10; y: tab.height }
                                        PathLine { x: 0; y: tab.height }
                                        PathLine { x: 10; y: 0 }
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: tab.closer ? "\u{F0156}" : root.host.pageNames[tab.index].toUpperCase()
                                    font.family: tab.closer ? "JetBrainsMono Nerd Font" : "Michroma"
                                    font.pixelSize: tab.closer ? 15 : 8
                                    font.letterSpacing: tab.closer ? 0 : 1
                                    color: tab.closer ? root.vp.amber : root.vp.text
                                }
                                MouseArea {
                                    id: ta
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (tab.closer) root.host.keypad("end")
                                        else root.host.page = tab.index
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        x: root.pw - 28
                        y: 4
                        width: 8
                        height: 8
                        color: root.vp.amber
                        opacity: 0.5 + 0.5 * Math.abs(Math.sin(root.t * Math.PI * 12))
                    }
                }
            }

            Rectangle {
                x: -4
                width: root.pw + 8
                height: 2
                y: reveal.y - 1
                visible: root.unfold > 0.01 && root.unfold < 0.99
                color: root.vp.ring
            }
            Rectangle {
                x: -4
                width: root.pw + 8
                height: 2
                y: reveal.y + reveal.height - 1
                visible: root.unfold > 0.01 && root.unfold < 0.99
                color: root.vp.ring
            }

            Repeater {
                model: [[0, 0, 1, 1], [1, 0, -1, 1], [0, 1, 1, -1], [1, 1, -1, -1]]
                delegate: Shape {
                    required property var modelData
                    readonly property real off: 10 + (1 - root.lock) * 80
                    x: modelData[0] * root.pw - modelData[2] * off + root.sx * 12
                    y: modelData[1] * root.ph - modelData[3] * off + root.sy * 8
                    opacity: root.lock
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: root.vp.ring
                        strokeWidth: 3
                        fillColor: "transparent"
                        capStyle: ShapePath.SquareCap
                        joinStyle: ShapePath.MiterJoin
                        startX: modelData[2] * 30; startY: 0
                        PathLine { x: 0; y: 0 }
                        PathLine { x: 0; y: modelData[3] * 30 }
                    }
                }
            }
        }

        Rectangle {
            x: 24
            y: root.ph + 30
            width: lat.implicitWidth + 12
            height: 20
            visible: !root.host.night
            opacity: root.lock
            color: "#8c0a1a36"
        }
        Text {
            id: lat
            x: 30
            y: root.ph + 36
            opacity: root.lock * 0.85
            text: "AERO LINK  ·  NEXUS  ·  SYS OK"
            font.family: "Michroma"
            font.pixelSize: 7
            font.letterSpacing: 1.5
            color: root.host.night ? root.tint(root.vp.line, 0.9) : "#ffffff"
            style: Text.Raised
            styleColor: "#660a1a36"
        }
    }
}
