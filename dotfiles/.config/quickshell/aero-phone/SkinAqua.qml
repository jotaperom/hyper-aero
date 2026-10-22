import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint

Item {
    id: root
    property var host
    property string variant: "aqua"
    readonly property alias pages: pagesItem
    readonly property var pal: host.pal
    readonly property var ap: Tint.palette(host.night ? aNight : aDay, host.accent)
    readonly property var aDay: ({
        w0: "#d98fe4ff", w1: "#cc3fb0f2", w2: "#d91e7ad9", w3: "#e60f4fb0",
        glass: "#30ffffff", rim: "#f2ffffff", foam: "#ffffff", ray: "#ffffff", bub: "#ffffff",
        base0: "#ffffff", base1: "#d4e1ef", base2: "#97a9c0", baseTop: "#f4f8fc", lamp: "#3d9be9",
        lid0: "#ffffff", lid1: "#b9c9dc", weed: "#5fd39a", fish: "#ffffff", label: "#ffffff"
    })
    readonly property var aNight: ({
        w0: "#cc3d8fd9", w1: "#cc1e5aa8", w2: "#d90f2f6e", w3: "#e6061636",
        glass: "#1a9fd8ff", rim: "#996fd3ff", foam: "#bdf0ff", ray: "#8fe3ff", bub: "#bdf0ff",
        base0: "#4a5a7c", base1: "#1f2a44", base2: "#0b111f", baseTop: "#33415f", lamp: "#6fd3ff",
        lid0: "#5a6c90", lid1: "#1f2a44", weed: "#3fb37f", fish: "#bdf0ff", label: "#e6eefb"
    })
    readonly property real tw: 360
    readonly property real th: 600
    readonly property real rr: 58
    readonly property real fit: Math.min(1, height / 864)
    property real shown: 0
    property real rise: 0
    property real level: 0
    property real slosh: 0
    property real content: 0
    property real t: 0
    readonly property real waterTop: 26 + (th - 32) * (1 - level)
    readonly property real amp: 2.4 + slosh * 10

    function tint(hex, a) { return host.tint(hex, a) }

    function open() {
        closeAnim.stop()
        openAnim.restart()
    }

    function close() {
        openAnim.stop()
        closeAnim.restart()
    }

    function edgeIn(y) {
        var top = 6 + rr, bot = th - 6 - rr
        var d = y < top ? top - y : (y > bot ? y - bot : 0)
        d = Math.min(rr, d)
        return 6 + rr - Math.sqrt(Math.max(0, rr * rr - d * d))
    }

    function surfPts() {
        var a = edgeIn(waterTop), b = tw - edgeIn(waterTop)
        var p = t * Math.PI * 2
        var pts = []
        var n = 40
        for (var i = 0; i <= n; i++) {
            var x = a + (b - a) * i / n
            var env = Math.max(0, Math.min(1, (x - a) / 36, (b - x) / 36))
            var y = waterTop + (Math.sin(x * 0.034 + p * 9) * amp + Math.sin(x * 0.071 - p * 14) * amp * 0.45) * env
            pts.push(Qt.point(x, y))
        }
        return pts
    }

    function waterPts() {
        var pts = surfPts()
        var y0 = waterTop
        var L = 6, R = tw - 6, T = 6, B = th - 6
        var right = [], left = []
        var i, a
        for (i = 0; i <= 12; i++) {
            a = -Math.PI / 2 + i / 12 * Math.PI / 2
            right.push(Qt.point(R - rr + Math.cos(a) * rr, T + rr + Math.sin(a) * rr))
        }
        for (i = 0; i <= 12; i++) {
            a = i / 12 * Math.PI / 2
            right.push(Qt.point(R - rr + Math.cos(a) * rr, B - rr + Math.sin(a) * rr))
        }
        for (i = 0; i <= 12; i++) {
            a = Math.PI / 2 + i / 12 * Math.PI / 2
            left.push(Qt.point(L + rr + Math.cos(a) * rr, B - rr + Math.sin(a) * rr))
        }
        for (i = 0; i <= 12; i++) {
            a = Math.PI + i / 12 * Math.PI / 2
            left.push(Qt.point(L + rr + Math.cos(a) * rr, T + rr + Math.sin(a) * rr))
        }
        for (i = 0; i < right.length; i++) if (right[i].y > y0) pts.push(right[i])
        for (i = 0; i < left.length; i++) if (left[i].y > y0) pts.push(left[i])
        pts.push(pts[0])
        return pts
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 260 }
        NumberAnimation { target: root; property: "rise"; from: 0; to: 1; duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        SequentialAnimation {
            PropertyAction { target: root; property: "content"; value: 0 }
            PauseAnimation { duration: 300 }
            ParallelAnimation {
                NumberAnimation { target: root; property: "level"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
                NumberAnimation { target: root; property: "slosh"; from: 1; to: 0; duration: 2000; easing.type: Easing.OutQuad }
                SequentialAnimation {
                    PauseAnimation { duration: 520 }
                    NumberAnimation { target: root; property: "content"; to: 1; duration: 520; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: root; property: "content"; to: 0; duration: 160 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "level"; to: 0; duration: 380; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "slosh"; to: 0.6; duration: 200 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "rise"; to: 0; duration: 260; easing.type: Easing.InBack }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 260 }
        }
        onFinished: if (root.host) root.host.closed()
    }

    NumberAnimation on t {
        running: root.shown > 0 && root.host.active
        from: 0
        to: 1
        duration: 24000
        loops: Animation.Infinite
    }

    HoverHandler { id: hover }
    property real sx: hover.hovered ? hover.point.position.x / Math.max(1, width) - 0.5 : 0
    Behavior on sx { SmoothedAnimation { velocity: 0.6 } }

    Item {
        id: rig
        width: root.tw + 60
        height: root.th + 92
        x: 46 * root.fit
        y: root.height - 22 * root.fit - height * root.fit
        transformOrigin: Item.TopLeft
        scale: root.fit
        opacity: Math.max(0, Math.min(1, root.shown * 2))

        Item {
            id: stand
            x: 0
            y: root.th - 6 + (1 - root.rise) * 60
            width: rig.width
            height: 92

            Rectangle {
                y: 26
                width: parent.width
                height: 60
                radius: 30
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.ap.base0 }
                    GradientStop { position: 0.45; color: root.ap.base1 }
                    GradientStop { position: 1.0; color: root.ap.base2 }
                }
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.7)
            }
            Rectangle {
                x: 6
                y: 6
                width: parent.width - 12
                height: 46
                radius: 23
                color: root.ap.baseTop
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.9)
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 16
                width: root.tw - 10
                height: 26
                radius: 13
                color: "transparent"
                border.width: 3
                border.color: root.tint(root.ap.lamp, 0.35 + 0.55 * root.level)
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 14
                    height: parent.height + 10
                    radius: height / 2
                    color: "transparent"
                    border.width: 6
                    border.color: root.tint(root.ap.lamp, 0.14 * root.level)
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 58
                text: "A Q U A · N E X U S"
                font.family: "Michroma"
                font.pixelSize: 8
                font.letterSpacing: 2
                color: root.host.night ? "#a9c4e6" : "#4f6680"
            }
        }

        Item {
            id: tank
            x: 30
            y: 0
            width: root.tw
            height: root.th
            transformOrigin: Item.Bottom
            scale: 0.72 + 0.28 * root.rise
            transform: Translate { y: (1 - root.rise) * 120 }

            Rectangle {
                anchors.fill: parent
                radius: root.rr + 6
                color: root.ap.glass
            }

            Shape {
                anchors.fill: parent
                visible: root.level > 0.005
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: 0; y1: root.waterTop
                        x2: 0; y2: root.th
                        GradientStop { position: 0.0; color: root.ap.w0 }
                        GradientStop { position: 0.3; color: root.ap.w1 }
                        GradientStop { position: 0.7; color: root.ap.w2 }
                        GradientStop { position: 1.0; color: root.ap.w3 }
                    }
                    PathPolyline { path: root.waterPts() }
                }
            }

            Item {
                id: life
                x: 8
                y: root.waterTop + 6
                width: root.tw - 16
                height: Math.max(0, root.th - 40 - y)
                clip: true
                opacity: Math.min(1, root.level * 1.4)

                Repeater {
                    model: 4
                    delegate: Rectangle {
                        required property int index
                        x: 30 + index * 86 + Math.sin((root.t * 6 + index * 0.27) * Math.PI * 2) * 22 + root.sx * 30
                        y: -20
                        width: 26 + index % 2 * 22
                        height: 380
                        rotation: 14
                        transformOrigin: Item.Top
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.tint(root.ap.ray, root.host.night ? 0.16 : 0.26) }
                            GradientStop { position: 1.0; color: root.tint(root.ap.ray, 0) }
                        }
                    }
                }

                Repeater {
                    model: [[14, 150, 0.0], [40, 110, 0.4], [300, 170, 0.2], [322, 120, 0.7]]
                    delegate: Shape {
                        required property var modelData
                        readonly property real sw: Math.sin((root.t * 5 + modelData[2]) * Math.PI * 2) * 14
                        x: modelData[0]
                        y: life.height - modelData[1]
                        width: 40
                        height: modelData[1]
                        preferredRendererType: Shape.CurveRenderer
                        opacity: 0.55
                        ShapePath {
                            strokeColor: root.ap.weed
                            strokeWidth: 5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 10; startY: modelData[1]
                            PathCubic {
                                x: 10 + sw; y: 0
                                control1X: 10 - sw * 0.6; control1Y: modelData[1] * 0.66
                                control2X: 10 + sw * 1.4; control2Y: modelData[1] * 0.33
                            }
                        }
                    }
                }

                Repeater {
                    model: [[3, 0.05, 150, 1, 1.0], [2, 0.55, 250, -1, 0.8], [4, 0.3, 360, 1, 0.65]]
                    delegate: Item {
                        required property var modelData
                        readonly property real p: (root.t * modelData[0] + modelData[1]) % 1
                        x: modelData[3] > 0 ? p * (life.width + 80) - 60 : life.width + 20 - p * (life.width + 80)
                        y: modelData[2] + Math.sin((root.t * 11 + modelData[1]) * Math.PI * 2) * 10
                        width: 40
                        height: 20
                        scale: modelData[4]
                        opacity: (root.host.night ? 0.42 : 0.5) * Math.max(0, Math.min(1, (x - 4) / 40, (life.width - x - 44) / 40))
                        visible: opacity > 0.01
                        transform: Scale { origin.x: 20; xScale: -modelData[3] }
                        Shape {
                            anchors.fill: parent
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: "transparent"
                                fillColor: root.ap.fish
                                startX: 30; startY: 10
                                PathQuad { x: 4; y: 10; controlX: 16; controlY: -4 }
                                PathQuad { x: 30; y: 10; controlX: 16; controlY: 24 }
                                PathMove { x: 28; y: 10 }
                                PathLine { x: 40; y: 2 }
                                PathLine { x: 37; y: 10 }
                                PathLine { x: 40; y: 18 }
                                PathLine { x: 28; y: 10 }
                            }
                        }
                        Rectangle { x: 9; y: 7; width: 3; height: 3; radius: 1.5; color: root.ap.w2 }
                    }
                }

                Repeater {
                    model: 18
                    delegate: Rectangle {
                        required property int index
                        readonly property real s: Math.abs(Math.sin(index * 12.9898) * 43758.5453) % 1
                        readonly property real s2: Math.abs(Math.sin(index * 78.233) * 12543.1234) % 1
                        readonly property real p: (root.t * (3 + Math.floor(s2 * 4)) + s) % 1
                        width: 4 + s2 * 9
                        height: width
                        radius: width / 2
                        x: 10 + s * (life.width - 30) + Math.sin((root.t * 18 + s) * Math.PI * 2) * 5
                        y: life.height - 4 - p * life.height
                        color: root.tint(root.ap.bub, 0.1)
                        border.width: 1
                        border.color: root.tint(root.ap.bub, 0.75)
                        opacity: Math.min(1, (1 - p) * 4) * Math.min(1, p * 8)
                        Rectangle {
                            x: parent.width * 0.22; y: parent.width * 0.18
                            width: parent.width * 0.32; height: width; radius: width / 2
                            color: root.tint(root.ap.bub, 0.9)
                        }
                    }
                }
            }

            Shape {
                anchors.fill: parent
                visible: root.level > 0.005
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: root.tint(root.ap.foam, 0.85)
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathPolyline { path: root.surfPts() }
                }
            }

            Item {
                id: status
                x: 26
                y: 40
                width: root.tw - 52
                height: 24
                opacity: root.content
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "◢ " + root.host.pageNames[root.host.page].toUpperCase()
                    font.family: "Michroma"
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    color: root.ap.label
                    style: Text.Raised
                    styleColor: "#660a2a66"
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.host.backend && root.host.backend.st.wifi ? "\u{F05A9}  " : "\u{F05AA}  ") + Qt.formatTime(root.host.now, "HH:mm")
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: 11
                    color: root.ap.label
                    style: Text.Raised
                    styleColor: "#660a2a66"
                }
            }

            Pages {
                id: pagesItem
                host: root.host
                x: 14
                y: 66
                width: root.tw - 28
                height: root.th - 66 - 92
                compact: true
                reveal: root.content
                opacity: root.content
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.th - 84
                spacing: 18
                opacity: root.content
                Repeater {
                    model: [
                        { k: 0, g: "\u{F003B}" }, { k: 1, g: "\u{F0493}" }, { k: 2, g: "\u{F00F6}" }, { k: -1, g: "\u{F0425}" }
                    ]
                    delegate: Item {
                        id: bb
                        required property var modelData
                        required property int index
                        readonly property bool on: modelData.k === root.host.page
                        width: 54
                        height: 54
                        y: Math.sin((root.t * 8 + index * 0.25) * Math.PI * 2) * 2.5
                        Rectangle {
                            anchors.fill: parent
                            radius: 27
                            scale: ba.pressed ? 0.92 : (ba.containsMouse ? 1.08 : 1)
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                            border.width: bb.on ? 2 : 1.2
                            border.color: bb.on ? "#ffffff" : root.tint(root.ap.bub, 0.8)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: bb.on ? root.pal.on0 : root.tint(root.ap.bub, 0.35) }
                                GradientStop { position: 0.6; color: bb.on ? root.pal.on2 : root.tint(root.ap.bub, 0.08) }
                                GradientStop { position: 1.0; color: bb.on ? root.pal.on1 : root.tint(root.ap.bub, 0.28) }
                            }
                            Rectangle {
                                x: 11; y: 4
                                width: 32; height: 18; radius: 9
                                color: Qt.rgba(1, 1, 1, ba.containsMouse ? 0.75 : 0.55)
                            }
                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 2
                                text: bb.modelData.g
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: "#ffffff"
                                style: Text.Raised
                                styleColor: "#800a2a66"
                            }
                        }
                        MouseArea {
                            id: ba
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (bb.modelData.k < 0) root.host.keypad("end")
                                else root.host.page = bb.modelData.k
                            }
                        }
                    }
                }
            }

            Rectangle {
                x: 16
                y: 52
                width: 20
                height: root.th - 150
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.host.night ? 0.16 : 0.38) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }
            Rectangle {
                x: root.tw - 26
                y: 70
                width: 8
                height: root.th * 0.42
                radius: 4
                color: Qt.rgba(1, 1, 1, root.host.night ? 0.08 : 0.2)
            }

            Rectangle {
                anchors.fill: parent
                radius: root.rr + 6
                color: "transparent"
                border.width: 2
                border.color: root.ap.rim
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: root.rr + 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.35)
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: -12
                width: root.tw - 70
                height: 24
                radius: 12
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.85)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.ap.lid0 }
                    GradientStop { position: 1.0; color: root.ap.lid1 }
                }
                Rectangle {
                    x: 10; y: 2
                    width: parent.width - 20; height: 9; radius: 4.5
                    color: Qt.rgba(1, 1, 1, 0.55)
                }
            }
        }
    }
}
