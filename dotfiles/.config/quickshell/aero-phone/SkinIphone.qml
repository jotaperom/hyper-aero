import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property var host
    property string variant: ""
    readonly property alias pages: pagesItem
    readonly property var backend: host ? host.backend : null
    readonly property var pal: host.pal
    readonly property int page: host.page
    readonly property var now: host.now
    readonly property bool night: host.night
    property real shown: 0
    readonly property real pw: 352
    readonly property real ph: 800
    readonly property real cut: 80
    readonly property real safe: 128
    readonly property real fit: Math.min(1, height / 864)
    property real rise: 0
    property real twist: 1
    property real glow: 0
    property real sweep: 0
    property real pulse: 0

    function tx(v) { return host.tx(v) }
    function tint(hex, a) { return host.tint(hex, a) }

    function open() {
        closeAnim.stop()
        sweep = 0
        pulse = 0
        openAnim.restart()
        bubbles.launch()
    }

    function close() {
        openAnim.stop()
        closeAnim.restart()
    }

    HoverHandler { id: hover }

    property real hx: hover.hovered ? hover.point.position.x / Math.max(1, width) - 0.5 : 0
    property real hy: hover.hovered ? hover.point.position.y / Math.max(1, height) - 0.5 : 0
    property real sx: hx
    property real sy: hy
    Behavior on sx { SmoothedAnimation { velocity: 0.7 } }
    Behavior on sy { SmoothedAnimation { velocity: 0.7 } }

    readonly property real tiltY: 13 + sx * 10 + twist * 36
    readonly property real tiltX: 8 - sy * 8 + twist * 26
    readonly property real spin: 4 - twist * 18
    readonly property real ang: Math.sqrt(tiltX * tiltX + tiltY * tiltY)
    readonly property real axX: ang > 0.001 ? tiltX / ang : 1
    readonly property real axY: ang > 0.001 ? tiltY / ang : 0

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 420; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "rise"; from: 0; to: 1; duration: 820; easing.type: Easing.OutBack; easing.overshoot: 1.35 }
        NumberAnimation { target: root; property: "twist"; from: 1; to: 0; duration: 1400; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.7 }
        SequentialAnimation {
            PauseAnimation { duration: 300 }
            NumberAnimation { target: root; property: "glow"; from: 0; to: 1; duration: 640; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 560 }
            NumberAnimation { target: root; property: "sweep"; from: 0; to: 1; duration: 950; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            PauseAnimation { duration: 440 }
            NumberAnimation { target: root; property: "pulse"; from: 0; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        }
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: root; property: "rise"; to: 0; duration: 360; easing.type: Easing.InBack; easing.overshoot: 1.6 }
        NumberAnimation { target: root; property: "twist"; to: -0.45; duration: 360; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "glow"; to: 0; duration: 220; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "shown"; to: 0; duration: 360; easing.type: Easing.InCubic }
        onFinished: if (root.host) root.host.closed()
    }

    Item {
        id: bubbles
        anchors.fill: parent

        function launch() {
            for (var i = 0; i < bubbleRep.count; i++) bubbleRep.itemAt(i).go()
        }

        Repeater {
            id: bubbleRep
            model: [
                { x: -0.22, s: 26, d: 120, t: 1900, h: 0.70, w: 14 },
                { x: 0.08, s: 40, d: 260, t: 2300, h: 0.86, w: 20 },
                { x: 0.30, s: 18, d: 60, t: 1600, h: 0.55, w: 10 },
                { x: 0.55, s: 32, d: 380, t: 2100, h: 0.78, w: 18 },
                { x: 0.78, s: 22, d: 200, t: 1750, h: 0.62, w: 12 },
                { x: 1.02, s: 46, d: 320, t: 2500, h: 0.92, w: 24 },
                { x: 1.18, s: 20, d: 520, t: 1800, h: 0.66, w: 12 },
                { x: 1.36, s: 30, d: 160, t: 2200, h: 0.80, w: 16 },
                { x: 0.42, s: 14, d: 640, t: 1500, h: 0.50, w: 8 },
                { x: 1.55, s: 16, d: 460, t: 1700, h: 0.58, w: 10 }
            ]
            delegate: Item {
                id: bub
                required property var modelData
                required property int index
                property real t: 0
                width: modelData.s
                height: width
                x: rig.x + root.pw * root.fit * modelData.x + Math.sin(t * Math.PI * 2 + index) * modelData.w
                y: root.height - t * root.height * modelData.h
                opacity: Math.sin(Math.min(1, t) * Math.PI) * 0.9
                visible: t > 0 && t < 1

                function go() {
                    anim.restart()
                }

                SequentialAnimation {
                    id: anim
                    PropertyAction { target: bub; property: "t"; value: 0 }
                    PauseAnimation { duration: bub.modelData.d }
                    NumberAnimation { target: bub; property: "t"; from: 0.001; to: 1; duration: bub.modelData.t; easing.type: Easing.OutQuad }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    antialiasing: true
                    border.width: 1.2
                    border.color: root.night ? root.tx("#bb6fd3ff") : "#e6ffffff"
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.night ? root.tx("#386fd3ff") : "#4dffffff" }
                        GradientStop { position: 0.7; color: root.night ? root.tx("#0a6fd3ff") : "#0dffffff" }
                        GradientStop { position: 1.0; color: root.night ? root.tx("#2a6fd3ff") : "#40ffffff" }
                    }
                }
                Rectangle {
                    x: parent.width * 0.2
                    y: parent.height * 0.16
                    width: parent.width * 0.34
                    height: parent.height * 0.2
                    radius: height / 2
                    rotation: -32
                    antialiasing: true
                    color: "#e6ffffff"
                }
            }
        }
    }

    Rectangle {
        id: ring
        property real cx: rig.x + root.pw * root.fit / 2
        property real cy: root.height - (root.ph - root.cut) * root.fit / 2
        width: 360 * root.fit * (0.5 + root.pulse * 1.5)
        height: width
        radius: width / 2
        x: cx - width / 2
        y: cy - height / 2
        antialiasing: true
        color: "transparent"
        border.width: 3
        border.color: root.pal.glow
        opacity: root.pulse > 0 && root.pulse < 1 ? (1 - root.pulse) * 0.7 : 0
    }

    Rectangle {
        width: ring.width * 0.8
        height: width
        radius: width / 2
        x: ring.cx - width / 2
        y: ring.cy - height / 2
        antialiasing: true
        color: "transparent"
        border.width: 1.5
        border.color: root.night ? root.pal.glow : "#ffffff"
        opacity: ring.opacity * 0.7
    }

    Item {
        id: rig
        width: root.pw
        height: root.ph
        x: 70 * root.fit
        y: root.height + root.cut - root.ph
        transformOrigin: Item.Bottom
        scale: root.fit
        opacity: Math.max(0, Math.min(1, root.shown * 2))
        transform: [
            Rotation { origin.x: root.pw / 2; origin.y: root.ph; angle: root.spin },
            Translate { y: (1 - root.rise) * root.ph * 0.95 }
        ]

        Shape {
            width: root.pw * 2.4
            height: width
            x: (root.pw - width) / 2
            y: (root.ph - height) / 2 - 60
            opacity: (root.night ? 1 : 0.6) * (0.6 + 0.4 * root.glow)
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: root.pw * 1.2; centerY: root.pw * 1.2
                    centerRadius: root.pw * 1.2
                    focalX: centerX; focalY: centerY
                    GradientStop { position: 0.0; color: root.pal.halo }
                    GradientStop { position: 0.55; color: root.tx("#143d9be9") }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                PathRectangle { x: 0; y: 0; width: root.pw * 2.4; height: root.pw * 2.4 }
            }
        }

        Repeater {
            model: 36
            delegate: Rectangle {
                required property int index
                width: root.pw
                height: root.ph
                radius: 56
                antialiasing: true
                color: Qt.tint(root.pal.edge0, root.tint(root.pal.edge1, index / 35))
                transform: Rotation {
                    origin.x: root.pw / 2
                    origin.y: root.ph / 2
                    origin.z: (36 - index) * 0.42
                    axis.x: root.axX
                    axis.y: root.axY
                    axis.z: 0
                    angle: root.ang
                }
            }
        }

        Item {
            id: face
            width: root.pw
            height: root.ph
            transform: Rotation {
                origin.x: root.pw / 2
                origin.y: root.ph / 2
                axis.x: root.axX
                axis.y: root.axY
                axis.z: 0
                angle: root.ang
            }

            Repeater {
                model: [
                    { left: true, y: 128, h: 30 },
                    { left: true, y: 182, h: 58 },
                    { left: true, y: 252, h: 58 },
                    { left: false, y: 214, h: 92 }
                ]
                delegate: Rectangle {
                    x: modelData.left ? -3 : root.pw - 4
                    y: modelData.y
                    width: 7
                    height: modelData.h
                    radius: 3
                    antialiasing: true
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.pal.body3 }
                        GradientStop { position: 0.5; color: root.pal.body0 }
                        GradientStop { position: 1.0; color: root.pal.body3 }
                    }
                }
            }

            Rectangle {
                id: body
                anchors.fill: parent
                radius: 56
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.pal.body3 }
                    GradientStop { position: 0.035; color: root.pal.body0 }
                    GradientStop { position: 0.2; color: root.pal.body1 }
                    GradientStop { position: 0.55; color: root.pal.body2 }
                    GradientStop { position: 0.9; color: root.pal.body4 }
                    GradientStop { position: 0.97; color: root.pal.body0 }
                    GradientStop { position: 1.0; color: root.pal.body3 }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 51
                antialiasing: true
                color: root.pal.bezel
            }

            Rectangle {
                id: screen
                anchors.fill: parent
                anchors.margins: 11
                radius: 45
                antialiasing: true
                clip: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.pal.wall0 }
                    GradientStop { position: 0.35; color: root.pal.wall1 }
                    GradientStop { position: 0.75; color: root.pal.wall2 }
                    GradientStop { position: 1.0; color: root.pal.wall3 }
                }

                Rectangle {
                    x: -60 + root.sx * 18; y: 70
                    width: 230; height: 230; radius: 115
                    color: root.pal.blobA
                    antialiasing: true
                }
                Rectangle {
                    x: 170 + root.sx * 26; y: 260
                    width: 170; height: 170; radius: 85
                    color: root.pal.blobB
                    antialiasing: true
                }
                Rectangle {
                    x: 40 + root.sx * 34; y: 470
                    width: 120; height: 120; radius: 60
                    color: root.pal.blobC
                    antialiasing: true
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: root.pal.arc
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        startX: -20; startY: 410
                        PathQuad { x: screen.width + 30; y: 300; controlX: screen.width * 0.45; controlY: 560 }
                    }
                    ShapePath {
                        strokeColor: root.pal.arc
                        strokeWidth: 1
                        fillColor: "transparent"
                        startX: -20; startY: 440
                        PathQuad { x: screen.width + 30; y: 340; controlX: screen.width * 0.5; controlY: 600 }
                    }
                }

                Item {
                    id: status
                    width: parent.width
                    height: 50

                    Text {
                        x: 34
                        anchors.verticalCenter: island.verticalCenter
                        text: Qt.formatTime(root.now, "HH:mm")
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 14
                        color: root.pal.status
                    }

                    Rectangle {
                        id: island
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 11
                        width: 104
                        height: 30
                        radius: 15
                        antialiasing: true
                        color: "#000000"
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 12; height: 12; radius: 6
                            antialiasing: true
                            color: "#0b1426"
                            border.width: 1
                            border.color: "#1d2c4a"
                            Rectangle {
                                x: 3; y: 3
                                width: 4; height: 4; radius: 2
                                color: "#5a8fd6"
                                opacity: 0.8
                            }
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6; height: 6; radius: 3
                            antialiasing: true
                            color: root.backend && root.backend.st.dnd ? "#f0b44c" : (root.night ? root.pal.glow : "#3ddc97")
                            opacity: 0.9
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 30
                        anchors.verticalCenter: island.verticalCenter
                        spacing: 6
                        Text {
                            text: root.backend && root.backend.st.wifi ? "\u{F05A9}" : "\u{F05AA}"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: root.pal.status
                        }
                        Text {
                            visible: !!(root.backend && root.backend.st.bat >= 0)
                            text: (root.backend && root.backend.st.charging ? "\u{F0084}" : "\u{F0079}") + " " + (root.backend ? root.backend.st.bat : 0)
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            color: root.pal.status
                        }
                    }
                }

                Pages {
                    id: pagesItem
                    host: root.host
                    anchors.top: status.bottom
                    anchors.bottom: dots.top
                    anchors.bottomMargin: 4
                    width: parent.width
                    compact: false
                    reveal: root.glow
                }

                Row {
                    id: dots
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.safe - 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 7
                    Repeater {
                        model: 3
                        delegate: Rectangle {
                            required property int index
                            width: root.page === index ? 22 : 8
                            height: 8
                            radius: 4
                            antialiasing: true
                            color: root.page === index ? root.pal.home : Qt.rgba(1, 1, 1, 0.38)
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.host.page = index
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: root.pal.bezel
                    opacity: 1 - root.glow
                    visible: opacity > 0.01
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * (0.2 + root.glow * 1.6)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 3
                    border.color: root.pal.glow
                    opacity: root.glow > 0 && root.glow < 1 ? (1 - root.glow) * 0.8 : 0
                }
            }

            Shape {
                x: screen.x
                y: screen.y
                width: screen.width
                height: screen.height
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: -40 - root.sx * 120; y1: 0
                        x2: screen.width + 40 - root.sx * 120; y2: screen.height
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 0.26; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 0.31; color: Qt.rgba(1, 1, 1, root.night ? 0.07 : 0.12) }
                        GradientStop { position: 0.44; color: Qt.rgba(1, 1, 1, 0.02) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    PathRectangle { x: 0; y: 0; width: screen.width; height: screen.height; radius: 45 }
                }
            }

            Shape {
                x: screen.x
                y: screen.y
                width: screen.width
                height: screen.height
                visible: root.sweep > 0 && root.sweep < 1
                opacity: Math.sin(root.sweep * Math.PI)
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: -screen.width * 1.4 + root.sweep * screen.width * 2.8; y1: 0
                        x2: x1 + screen.width * 0.9; y2: screen.height * 0.55
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 0.42; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.night ? 0.32 : 0.5) }
                        GradientStop { position: 0.56; color: Qt.rgba(1, 1, 1, 0.08) }
                        GradientStop { position: 0.62; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    PathRectangle { x: 0; y: 0; width: screen.width; height: screen.height; radius: 45 }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 56
                antialiasing: true
                color: "transparent"
                border.width: 1.5 + (root.pulse > 0 && root.pulse < 1 ? (1 - root.pulse) * 2 : 0)
                border.color: root.pulse > 0 && root.pulse < 0.6 ? root.pal.glow : root.pal.rim
                opacity: 0.85
            }
        }
    }
}
