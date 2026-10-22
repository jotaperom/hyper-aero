import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint

Item {
    id: root
    property var host
    property string variant: ""
    readonly property alias pages: pagesItem
    readonly property var backend: host ? host.backend : null
    readonly property bool active: host.active
    readonly property int page: host.page
    readonly property var now: host.now
    readonly property bool night: host.night
    readonly property bool inSub: host.inSub
    readonly property string toastText: host.toastText
    readonly property var pageNames: host.pageNames
    readonly property var pal: Tint.palette(night ? flipNight : flipDay, host.accent)
    property real shown: 0
    readonly property real pw: 352
    readonly property real lidH: 530
    readonly property real baseH: 450
    readonly property real ph: lidH + baseH
    readonly property real cut: 172
    readonly property real liftScale: Math.min(fit, (height - 64) / ph)
    readonly property real curScale: fit + (liftScale - fit) * lift
    readonly property real fit: Math.min(1, height / 864)
    property real rise: 0
    property real twist: 1
    property real glow: 0
    property real sweep: 0
    property real pulse: 0
    property real fold: 1
    property real keyLight: 0
    property real lift: 0
    readonly property real hinge: fold * 180

    function tx(v) { return host.tx(v) }
    function tint(hex, a) { return host.tint(hex, a) }
    function keypad(k) { host.keypad(k) }

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

    readonly property var flipDay: ({
        scrim: "#0b2a66", scrimA: 0.13, paper0: "#f4f8fc", paper1: "#d0e2f4", bubble: "#eef3f8", bar0: "#2350c8", bar1: "#142a8c",
        text: "#0b0d12", muted: "#5a6270", accent: "#1e6fd9", glow: "#3d9be9", ring: "#ffffff",
        tile0: "#f7ffffff", tile1: "#e6eef6fd", tile2: "#d9e1ecf8", tile3: "#e6eef4fb",
        tileBorder: "#b3ffffff", onBorder: "#e61446c2",
        on0: "#8cc6f5", on1: "#3d9be9", on2: "#1446c2", on3: "#1e6fd9",
        glossTop: 0.75, badge: "#d9ffffff", track: "#99ffffff",
        icon0: "#fdffffff", icon1: "#f2edf4fc", icon2: "#f2d3e2f3",
        iconBorder: "#e6ffffff", iconGloss: 0.7,
        field: "#ebffffff", shelf: "#6bffffff", accentFill: "#1e6fd9",
        hero: "#ffffff", heroShadow: "#801446c2", heroSub: "#f0ffffff",
        label: "#ffffff", labelShadow: "#b30b2a66", status: "#ffffff",
        wall0: "#1446c2", wall1: "#2a7fe0", wall2: "#4c9eec", wall3: "#86c4f4",
        blobA: "#55ffffff", blobB: "#38ffffff", blobC: "#2effffff", arc: "#73ffffff",
        body0: "#f5f9ff", body1: "#b6d3f2", body2: "#e2eefb", body3: "#86a9d2", body4: "#cfe3f7",
        edge0: "#5f7fa8", edge1: "#9fbbdc", rim: "#ffffff", bezel: "#0b0f18",
        halo: "#663d9be9", shadow: "#8c0b1a3a", home: "#e6ffffff",
        key0: "#ffffff", key1: "#f1f6fc", key2: "#d9e5f2", key3: "#ecf3fa",
        keyEdge: "#7f9cc0", keyRim: "#ccffffff", keyText: "#1d2836", keySub: "#5f6b7c", keyLit: "#1e6fd9",
        brand: "#5d7aa0", hingeA: "#7d9cc4", hingeB: "#f4f9ff", outer: "#0b1426"
    })

    readonly property var flipNight: ({
        scrim: "#020610", scrimA: 0.14, paper0: "#dce9f6", paper1: "#a9c5e3", bubble: "#16243f", bar0: "#1f3f86", bar1: "#0e1d44",
        text: "#e6eefb", muted: "#8b97ab", accent: "#6fd3ff", glow: "#6fd3ff", ring: "#6fd3ff",
        tile0: "#d92c4370", tile1: "#d91d3058", tile2: "#d914234a", tile3: "#d91a2c52",
        tileBorder: "#596fd3ff", onBorder: "#d96fd3ff",
        on0: "#8cc6f5", on1: "#3d9be9", on2: "#1446c2", on3: "#1e6fd9",
        glossTop: 0.16, badge: "#800a1428", track: "#b3070c18",
        icon0: "#f0334c7c", icon1: "#f01c2c52", icon2: "#f0111c38",
        iconBorder: "#666fd3ff", iconGloss: 0.22,
        field: "#d9070c18", shelf: "#8c0e182e", accentFill: "#1e6fd9",
        hero: "#e6eefb", heroShadow: "#99000000", heroSub: "#a9c4e6",
        label: "#e6eefb", labelShadow: "#e6000000", status: "#e6eefb",
        wall0: "#0f2250", wall1: "#0a1736", wall2: "#070f24", wall3: "#04070f",
        blobA: "#4d3d9be9", blobB: "#2e6fd3ff", blobC: "#661446c2", arc: "#596fd3ff",
        body0: "#4b5f88", body1: "#1c2742", body2: "#33436a", body3: "#0d1424", body4: "#27345a",
        edge0: "#05080f", edge1: "#1a2540", rim: "#806fd3ff", bezel: "#020409",
        halo: "#593d9be9", shadow: "#cc000000", home: "#cce6eefb",
        key0: "#4a5c84", key1: "#2b3a5c", key2: "#1b2643", key3: "#25324f",
        keyEdge: "#04070e", keyRim: "#596fd3ff", keyText: "#c3d4ee", keySub: "#7d8ca8", keyLit: "#6fd3ff",
        brand: "#7f95bd", hingeA: "#0d1424", hingeB: "#5a6f9a", outer: "#02050c"
    })

    HoverHandler { id: hover }

    property real hx: hover.hovered ? hover.point.position.x / Math.max(1, width) - 0.5 : 0
    property real hy: hover.hovered ? hover.point.position.y / Math.max(1, height) - 0.5 : 0
    property real sx: hx
    property real sy: hy
    Behavior on sx { SmoothedAnimation { velocity: 0.7 } }
    Behavior on sy { SmoothedAnimation { velocity: 0.7 } }

    readonly property real tiltY: 12 + sx * 9 + twist * 30
    readonly property real tiltX: 7 - sy * 6 + twist * 20
    readonly property real spin: 4 - twist * 14
    readonly property real ang: Math.sqrt(tiltX * tiltX + tiltY * tiltY)
    readonly property real axX: ang > 0.001 ? tiltX / ang : 1
    readonly property real axY: ang > 0.001 ? tiltY / ang : 0

    readonly property real topY: height + cut - ph * fit
    readonly property real jointY: height + cut - lift * (cut + 8) - baseH * curScale
    readonly property bool wantLift: active && hover.hovered
        && hover.point.position.x > rig.x - 20 && hover.point.position.x < rig.x + pw * fit + 30
        && hover.point.position.y > jointY + 30 * fit
    onWantLiftChanged: liftTimer.restart()

    Timer {
        id: liftTimer
        interval: root.wantLift ? 140 : 420
        onTriggered: root.lift = root.wantLift ? 1 : 0
    }
    Behavior on lift { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 380; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "rise"; from: 0; to: 1; duration: 640; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        NumberAnimation { target: root; property: "twist"; from: 1; to: 0; duration: 1300; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.75 }
        SequentialAnimation {
            PropertyAction { target: root; property: "fold"; value: 1 }
            PauseAnimation { duration: 330 }
            NumberAnimation { target: root; property: "fold"; from: 1; to: 0; duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 640 }
            NumberAnimation { target: root; property: "glow"; from: 0; to: 1; duration: 560; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 720 }
            NumberAnimation { target: root; property: "keyLight"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 900 }
            NumberAnimation { target: root; property: "sweep"; from: 0; to: 1; duration: 950; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            PauseAnimation { duration: 760 }
            NumberAnimation { target: root; property: "pulse"; from: 0; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "glow"; to: 0; duration: 160; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "keyLight"; to: 0; duration: 160 }
            NumberAnimation { target: root; property: "lift"; to: 0; duration: 160 }
            NumberAnimation { target: root; property: "fold"; to: 1; duration: 300; easing.type: Easing.InCubic }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "rise"; to: 0; duration: 340; easing.type: Easing.InBack; easing.overshoot: 1.5 }
            NumberAnimation { target: root; property: "twist"; to: -0.4; duration: 340; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 340; easing.type: Easing.InCubic }
        }
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
        property real cy: root.topY + 272 * root.fit
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
        scale: root.curScale
        opacity: Math.max(0, Math.min(1, root.shown * 2))
        transform: [
            Rotation { origin.x: root.pw / 2; origin.y: root.ph; angle: root.spin },
            Translate { y: (1 - root.rise) * root.ph * 0.95 - root.lift * (root.cut + 8) }
        ]

        Shape {
            width: root.pw * 2.4
            height: width
            x: (root.pw - width) / 2
            y: root.lidH / 2 - height / 2
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

        Item {
            id: base
            y: root.lidH
            width: root.pw
            height: root.baseH

            Repeater {
                model: 18
                delegate: Rectangle {
                    required property int index
                    width: root.pw
                    height: root.baseH
                    topLeftRadius: 22; topRightRadius: 22
                    bottomLeftRadius: 60; bottomRightRadius: 60
                    antialiasing: true
                    color: Qt.tint(root.pal.edge0, root.tint(root.pal.edge1, index / 17))
                    transform: Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.ph / 2 - root.lidH
                        origin.z: (18 - index) * 0.5
                        axis.x: root.axX
                        axis.y: root.axY
                        axis.z: 0
                        angle: root.ang
                    }
                }
            }

            Item {
                width: root.pw
                height: root.baseH
                transform: Rotation {
                    origin.x: root.pw / 2
                    origin.y: root.ph / 2 - root.lidH
                    axis.x: root.axX
                    axis.y: root.axY
                    axis.z: 0
                    angle: root.ang
                }

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 22; topRightRadius: 22
                    bottomLeftRadius: 60; bottomRightRadius: 60
                    antialiasing: true
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.pal.body3 }
                        GradientStop { position: 0.04; color: root.pal.body0 }
                        GradientStop { position: 0.2; color: root.pal.body1 }
                        GradientStop { position: 0.55; color: root.pal.body2 }
                        GradientStop { position: 0.9; color: root.pal.body4 }
                        GradientStop { position: 0.97; color: root.pal.body0 }
                        GradientStop { position: 1.0; color: root.pal.body3 }
                    }
                }

                Rectangle {
                    x: 3; y: 3
                    width: parent.width - 6
                    height: 170
                    topLeftRadius: 20; topRightRadius: 20
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.night ? 0.12 : 0.5) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }

                Rectangle {
                    x: 14; y: 30
                    width: parent.width - 28
                    height: parent.height - 44
                    radius: 40
                    antialiasing: true
                    color: root.night ? "#33000000" : "#1a0b2a66"
                    border.width: 1
                    border.color: root.night ? "#1a6fd3ff" : "#66ffffff"
                }

                Keypad {
                    anchors.fill: parent
                    pal: root.pal
                    night: root.night
                    light: root.keyLight
                    onKey: function (k) { root.keypad(k) }
                }

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 22; topRightRadius: 22
                    bottomLeftRadius: 60; bottomRightRadius: 60
                    antialiasing: true
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.pal.rim
                    opacity: 0.8
                }
            }
        }

        Item {
            id: lid
            width: root.pw
            height: root.lidH

            Repeater {
                model: 16
                delegate: Rectangle {
                    required property int index
                    width: root.pw
                    height: root.lidH
                    topLeftRadius: 60; topRightRadius: 60
                    bottomLeftRadius: 22; bottomRightRadius: 22
                    antialiasing: true
                    color: Qt.tint(root.pal.edge0, root.tint(root.pal.edge1, index / 15))
                    transform: [
                        Rotation {
                            origin.x: root.pw / 2
                            origin.y: root.lidH
                            origin.z: (16 - index) * 0.5
                            axis.x: 1; axis.y: 0; axis.z: 0
                            angle: -root.hinge
                        },
                        Rotation {
                            origin.x: root.pw / 2
                            origin.y: root.ph / 2
                            origin.z: (16 - index) * 0.5
                            axis.x: root.axX
                            axis.y: root.axY
                            axis.z: 0
                            angle: root.ang
                        }
                    ]
                }
            }

            Item {
                id: lidFront
                width: root.pw
                height: root.lidH
                visible: root.hinge < 90
                transform: [
                    Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.lidH
                        axis.x: 1; axis.y: 0; axis.z: 0
                        angle: -root.hinge
                    },
                    Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.ph / 2
                        axis.x: root.axX
                        axis.y: root.axY
                        axis.z: 0
                        angle: root.ang
                    }
                ]

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 60; topRightRadius: 60
                    bottomLeftRadius: 22; bottomRightRadius: 22
                    antialiasing: true
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.pal.body3 }
                        GradientStop { position: 0.04; color: root.pal.body0 }
                        GradientStop { position: 0.2; color: root.pal.body1 }
                        GradientStop { position: 0.55; color: root.pal.body2 }
                        GradientStop { position: 0.9; color: root.pal.body4 }
                        GradientStop { position: 0.97; color: root.pal.body0 }
                        GradientStop { position: 1.0; color: root.pal.body3 }
                    }
                }

                Rectangle {
                    x: 3; y: 3
                    width: parent.width - 6
                    height: 120
                    topLeftRadius: 57; topRightRadius: 57
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.night ? 0.16 : 0.6) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 17
                    width: 74; height: 8
                    radius: 4
                    antialiasing: true
                    color: root.pal.bezel
                    border.width: 1
                    border.color: root.night ? "#336fd3ff" : "#99ffffff"
                    Row {
                        anchors.centerIn: parent
                        spacing: 3
                        Repeater {
                            model: 9
                            delegate: Rectangle { width: 4; height: 2; radius: 1; color: "#33ffffff" }
                        }
                    }
                }

                Rectangle {
                    x: root.pw / 2 + 56
                    y: 14
                    width: 14; height: 14; radius: 7
                    antialiasing: true
                    color: "#0b1426"
                    border.width: 1
                    border.color: root.night ? "#556fd3ff" : "#ccffffff"
                    Rectangle { x: 4; y: 3; width: 4; height: 4; radius: 2; color: "#5a8fd6"; opacity: 0.85 }
                }

                Rectangle {
                    x: root.pw / 2 - 72
                    y: 17
                    width: 8; height: 8; radius: 4
                    antialiasing: true
                    color: root.backend && root.backend.st.rec ? "#ff4d5e"
                         : (root.backend && root.backend.st.dnd ? "#f0b44c" : (root.night ? root.pal.glow : "#3ddc97"))
                    opacity: 0.6 + 0.4 * Math.abs(Math.sin(root.now.getSeconds() * Math.PI / 2))
                    Rectangle { anchors.fill: parent; anchors.margins: -3; radius: width / 2; color: "transparent"; border.width: 2; border.color: parent.color; opacity: 0.35 }
                }

                Rectangle {
                    x: 16; y: 36
                    width: root.pw - 32
                    height: 464
                    radius: 24
                    antialiasing: true
                    color: root.pal.bezel
                    border.width: 1
                    border.color: root.night ? "#336fd3ff" : "#40ffffff"
                }

                Rectangle {
                    id: screen
                    x: 26; y: 46
                    width: root.pw - 52
                    height: 444
                    radius: 16
                    antialiasing: true
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.pal.wall0 }
                        GradientStop { position: 0.35; color: root.pal.wall1 }
                        GradientStop { position: 0.75; color: root.pal.wall2 }
                        GradientStop { position: 1.0; color: root.pal.wall3 }
                    }

                    Rectangle {
                        x: -60 + root.sx * 18; y: 40
                        width: 210; height: 210; radius: 105
                        color: root.pal.blobA
                        antialiasing: true
                    }
                    Rectangle {
                        x: 160 + root.sx * 26; y: 190
                        width: 150; height: 150; radius: 75
                        color: root.pal.blobB
                        antialiasing: true
                    }
                    Rectangle {
                        x: 30 + root.sx * 34; y: 330
                        width: 110; height: 110; radius: 55
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
                            startX: -20; startY: 300
                            PathQuad { x: screen.width + 30; y: 220; controlX: screen.width * 0.45; controlY: 410 }
                        }
                        ShapePath {
                            strokeColor: root.pal.arc
                            strokeWidth: 1
                            fillColor: "transparent"
                            startX: -20; startY: 325
                            PathQuad { x: screen.width + 30; y: 252; controlX: screen.width * 0.5; controlY: 440 }
                        }
                    }

                    Rectangle {
                        id: status
                        width: parent.width
                        height: 26
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.night ? 0.35 : 0.16) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
                        }

                        Row {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Repeater {
                                model: 4
                                delegate: Rectangle {
                                    required property int index
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    height: 4 + index * 2.5
                                    radius: 1
                                    color: root.pal.status
                                    opacity: root.backend && root.backend.st.wifi ? 1 : (index === 0 ? 0.9 : 0.25)
                                }
                            }
                            Item { width: 5; height: 1 }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.backend && root.backend.st.wifi ? "AERO" : "SIN RED"
                                font.family: "Michroma"
                                font.pixelSize: 8
                                font.letterSpacing: 1
                                color: root.pal.status
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    required property int index
                                    width: root.page === index ? 14 : 5
                                    height: 5
                                    radius: 2.5
                                    antialiasing: true
                                    color: root.page === index ? root.pal.home : Qt.rgba(1, 1, 1, 0.4)
                                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                }
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            Text {
                                visible: !!(root.backend && root.backend.st.rec)
                                anchors.verticalCenter: parent.verticalCenter
                                text: "●"
                                font.pixelSize: 10
                                color: "#ff4d5e"
                            }
                            Text {
                                visible: !!(root.backend && root.backend.st.bt)
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\u{F00AF}"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: root.pal.status
                            }
                            Text {
                                visible: !!(root.backend && root.backend.st.bat >= 0)
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.backend && root.backend.st.charging ? "\u{F0084}" : "\u{F0079}")
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: root.pal.status
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.formatTime(root.now, "HH:mm")
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
                        anchors.bottom: soft.top
                        width: parent.width
                        compact: true
                        reveal: root.glow
                    }

                    Rectangle {
                        id: soft
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 28
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.0) }
                            GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, root.night ? 0.4 : 0.2) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.night ? 0.55 : 0.32) }
                        }

                        Text {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 2
                            text: root.inSub ? "Atrás" : root.pageNames[(root.page + 2) % 3]
                            font.family: "Exo 2"
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            color: root.pal.status
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 2
                            text: root.toastText.length ? root.toastText
                                : (root.page === 0 ? "Abrir" : (root.page === 2 ? "Guardar" : "●"))
                            font.family: "Exo 2"
                            font.weight: Font.Black
                            font.pixelSize: root.toastText.length ? 12 : 11
                            color: root.toastText.length ? "#ffffff" : root.pal.status
                            style: root.toastText.length ? Text.Outline : Text.Normal
                            styleColor: root.pal.on2
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 2
                            text: root.pageNames[(root.page + 1) % 3]
                            font.family: "Exo 2"
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            color: root.pal.status
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
                        PathRectangle { x: 0; y: 0; width: screen.width; height: screen.height; radius: 16 }
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
                        PathRectangle { x: 0; y: 0; width: screen.width; height: screen.height; radius: 16 }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 503
                    text: "HYPER·AERO"
                    font.family: "Michroma"
                    font.pixelSize: 9
                    font.letterSpacing: 3
                    color: root.pal.brand
                    style: Text.Raised
                    styleColor: root.night ? "#80000000" : "#ccffffff"
                }

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 60; topRightRadius: 60
                    bottomLeftRadius: 22; bottomRightRadius: 22
                    antialiasing: true
                    color: "transparent"
                    border.width: 1.5 + (root.pulse > 0 && root.pulse < 1 ? (1 - root.pulse) * 2 : 0)
                    border.color: root.pulse > 0 && root.pulse < 0.6 ? root.pal.glow : root.pal.rim
                    opacity: 0.85
                }
            }

            Item {
                id: lidBack
                width: root.pw
                height: root.lidH
                visible: root.hinge >= 90
                transform: [
                    Scale { origin.y: root.lidH / 2; yScale: -1 },
                    Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.lidH
                        axis.x: 1; axis.y: 0; axis.z: 0
                        angle: -root.hinge
                    },
                    Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.ph / 2
                        axis.x: root.axX
                        axis.y: root.axY
                        axis.z: 0
                        angle: root.ang
                    }
                ]

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 22; topRightRadius: 22
                    bottomLeftRadius: 60; bottomRightRadius: 60
                    antialiasing: true
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.pal.body3 }
                        GradientStop { position: 0.05; color: root.pal.body0 }
                        GradientStop { position: 0.3; color: root.pal.body1 }
                        GradientStop { position: 0.6; color: root.pal.body2 }
                        GradientStop { position: 0.95; color: root.pal.body0 }
                        GradientStop { position: 1.0; color: root.pal.body3 }
                    }
                }

                Item {
                    anchors.fill: parent

                    Rectangle {
                        x: 3; y: 3
                        width: parent.width - 6
                        height: 200
                        topLeftRadius: 20; topRightRadius: 20
                        antialiasing: true
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.night ? 0.14 : 0.55) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 46
                        width: 40; height: 40; radius: 20
                        antialiasing: true
                        color: "#0b1426"
                        border.width: 3
                        border.color: root.pal.hingeA
                        Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: "#1d3358" }
                        Rectangle { x: 11; y: 9; width: 6; height: 6; radius: 3; color: "#9fd0ff"; opacity: 0.8 }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 104
                        width: 168; height: 76
                        radius: 18
                        antialiasing: true
                        color: root.pal.outer
                        border.width: 2
                        border.color: root.night ? "#806fd3ff" : "#e6ffffff"
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatTime(root.now, "HH:mm")
                                font.family: "Michroma"
                                font.pixelSize: 26
                                color: root.pal.glow
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.locale("es_ES").toString(root.now, "ddd d MMM").toUpperCase()
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 9
                                color: root.pal.glow
                                opacity: 0.75
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: root.lidH - 90
                        text: "NEXUS"
                        font.family: "Michroma"
                        font.pixelSize: 16
                        font.letterSpacing: 6
                        color: root.pal.brand
                        style: Text.Raised
                        styleColor: root.night ? "#80000000" : "#ccffffff"
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: 22; topRightRadius: 22
                    bottomLeftRadius: 60; bottomRightRadius: 60
                    antialiasing: true
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.pal.rim
                    opacity: 0.85
                }
            }
        }

        Item {
            id: barrel
            x: (root.pw - width) / 2
            y: root.lidH - height / 2
            width: 236
            height: 30
            transform: Rotation {
                origin.x: barrel.width / 2
                origin.y: root.ph / 2 - barrel.y
                axis.x: root.axX
                axis.y: root.axY
                axis.z: 0
                angle: root.ang
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.pal.hingeA }
                    GradientStop { position: 0.3; color: root.pal.hingeB }
                    GradientStop { position: 0.55; color: root.pal.body1 }
                    GradientStop { position: 1.0; color: root.pal.hingeA }
                }
                border.width: 1
                border.color: root.night ? "#336fd3ff" : "#99ffffff"
            }
            Rectangle {
                x: 44; y: 6
                width: parent.width - 88
                height: parent.height - 12
                radius: height / 2
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.pal.on2 }
                    GradientStop { position: 0.4; color: root.pal.on0 }
                    GradientStop { position: 1.0; color: root.pal.on2 }
                }
                opacity: 0.55 + 0.45 * root.keyLight
            }
        }
    }
}
