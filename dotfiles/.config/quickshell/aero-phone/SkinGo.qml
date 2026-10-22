import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint

Item {
    id: root
    property var host
    property string variant: "go-white"
    readonly property alias pages: pagesItem
    readonly property bool dark: variant === "go-black"
    readonly property var pal: host.pal
    readonly property var gp: Tint.palette(dark ? goBlack : goWhite, host.accent)
    readonly property var goWhite: ({
        c0: "#ffffff", c1: "#f3f6fa", c2: "#e1e7ef", c3: "#f7f9fc", edge0: "#8f9bab", edge1: "#d5dce6",
        ink: "#5d6878", inkStrong: "#2a3240", gel: "#8c3d9be9", gelRim: "#e6ffffff", sheen: 0.75,
        key0: "#ffffff", key1: "#eef3f9", key2: "#d6e0ec", key3: "#f4f7fb", keyRim: "#b38a99ad", keyGlyph: "#4a5568",
        grille: "#40707c8c"
    })
    readonly property var goBlack: ({
        c0: "#4c5260", c1: "#1b1e25", c2: "#0a0b0f", c3: "#1c2028", edge0: "#000000", edge1: "#20242d",
        ink: "#8e9aae", inkStrong: "#d5deec", gel: "#8c3d9be9", gelRim: "#806fd3ff", sheen: 0.28,
        key0: "#3c424e", key1: "#22262e", key2: "#14161b", key3: "#1d2027", keyRim: "#40ffffff", keyGlyph: "#c5d1e3",
        grille: "#40000000"
    })
    readonly property real bw: 1000
    readonly property real bh: 410
    readonly property real fit: Math.min(1, height / 864, width / 1300) * 0.86
    property real shown: 0
    property real rise: 0
    property real twist: 1
    property real power: 0
    property real flash: 0
    property real sweep: 0

    function open() {
        closeAnim.stop()
        sweep = 0
        openAnim.restart()
    }

    function close() {
        openAnim.stop()
        closeAnim.restart()
    }

    HoverHandler { id: hover }
    property real sx: hover.hovered ? hover.point.position.x / Math.max(1, width) - 0.5 : 0
    property real sy: hover.hovered ? hover.point.position.y / Math.max(1, height) - 0.5 : 0
    Behavior on sx { SmoothedAnimation { velocity: 0.7 } }
    Behavior on sy { SmoothedAnimation { velocity: 0.7 } }
    readonly property real tiltY: 8 + sx * 8 + twist * 26
    readonly property real tiltX: 9 - sy * 7 + twist * 18
    readonly property real ang: Math.sqrt(tiltX * tiltX + tiltY * tiltY)
    readonly property real axX: ang > 0.001 ? tiltX / ang : 1
    readonly property real axY: ang > 0.001 ? tiltY / ang : 0

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 380; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "rise"; from: 0; to: 1; duration: 720; easing.type: Easing.OutBack; easing.overshoot: 1.25 }
        NumberAnimation { target: root; property: "twist"; from: 1; to: 0; duration: 1300; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.8 }
        SequentialAnimation {
            PropertyAction { target: root; property: "power"; value: 0 }
            PauseAnimation { duration: 520 }
            NumberAnimation { target: root; property: "flash"; from: 0; to: 1; duration: 90 }
            ParallelAnimation {
                NumberAnimation { target: root; property: "power"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
                NumberAnimation { target: root; property: "flash"; to: 0; duration: 520 }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 980 }
            NumberAnimation { target: root; property: "sweep"; from: 0; to: 1; duration: 900; easing.type: Easing.InOutSine }
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: root; property: "power"; to: 0.04; duration: 200; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "power"; to: 0; duration: 140 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "rise"; to: 0; duration: 340; easing.type: Easing.InBack; easing.overshoot: 1.4 }
            NumberAnimation { target: root; property: "twist"; to: -0.4; duration: 340 }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 340 }
        }
        onFinished: if (root.host) root.host.closed()
    }

    Item {
        id: rig
        width: root.bw
        height: root.bh
        x: 46 * root.fit
        y: root.height - (root.bh + 40) * root.fit
        transformOrigin: Item.TopLeft
        scale: root.fit
        opacity: Math.max(0, Math.min(1, root.shown * 2))
        transform: [
            Rotation { origin.x: root.bw / 2; origin.y: root.bh; angle: -2 + root.twist * 8 },
            Translate { y: (1 - root.rise) * 620 }
        ]

        Rectangle {
            x: 30; y: 26
            width: root.bw - 60
            height: root.bh - 10
            radius: 120
            color: root.dark ? "#66000000" : "#330b1a3a"
            transform: Translate { x: 10; y: 18 }
        }

        Repeater {
            model: [[100, -9], [root.bw - 100 - 150, -9]]
            delegate: Rectangle {
                required property var modelData
                required property int index
                x: modelData[0]
                y: modelData[1] + (shoulder.pressed && shoulder.which === index ? 3 : 0)
                width: 150
                height: 30
                radius: 14
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.gp.key0 }
                    GradientStop { position: 1.0; color: root.gp.key2 }
                }
                border.width: 1
                border.color: root.gp.keyRim
                transform: Rotation {
                    origin.x: root.bw / 2 - modelData[0]
                    origin.y: root.bh / 2 - modelData[1]
                    axis.x: root.axX
                    axis.y: root.axY
                    axis.z: 0
                    angle: root.ang
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 2
                    text: index === 0 ? "L" : "R"
                    font.family: "Michroma"
                    font.pixelSize: 9
                    color: root.gp.ink
                }
                MouseArea {
                    id: shoulder
                    property int which: index
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.host.keypad(index === 0 ? "softL" : "softR")
                }
            }
        }

        Repeater {
            model: 14
            delegate: GoBody {
                required property int index
                c1: Qt.tint(root.gp.edge0, root.tint(root.gp.edge1, index / 13))
                flat: true
                transform: Rotation {
                    origin.x: root.bw / 2
                    origin.y: root.bh / 2
                    origin.z: (14 - index) * 0.6
                    axis.x: root.axX
                    axis.y: root.axY
                    axis.z: 0
                    angle: root.ang
                }
            }
        }

        Item {
            id: face
            width: root.bw
            height: root.bh
            transform: Rotation {
                origin.x: root.bw / 2
                origin.y: root.bh / 2
                axis.x: root.axX
                axis.y: root.axY
                axis.z: 0
                angle: root.ang
            }

            GoBody {
                c0: root.gp.c0
                c1: root.gp.c1
                c2: root.gp.c2
                c3: root.gp.c3
                line: root.dark ? "#33ffffff" : "#ccffffff"
                lineWidth: 1.5
            }

            Shape {
                width: root.bw
                height: root.bh
                preferredRendererType: Shape.CurveRenderer
                opacity: root.gp.sheen
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0
                        x2: 0; y2: 150
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.9) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    startX: 70; startY: 4
                    PathLine { x: root.bw - 70; y: 4 }
                    PathQuad { x: root.bw - 6; y: 66; controlX: root.bw - 6; controlY: 4 }
                    PathLine { x: root.bw - 6; y: 150 }
                    PathLine { x: 6; y: 150 }
                    PathLine { x: 6; y: 66 }
                    PathQuad { x: 70; y: 4; controlX: 6; controlY: 4 }
                }
            }

            Shape {
                width: root.bw
                height: root.bh
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0
                        x2: root.bw; y2: root.bh
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.42; color: "transparent" }
                        GradientStop { position: 0.5; color: root.tint(root.pal.glow, root.dark ? 0.16 : 0.12) }
                        GradientStop { position: 0.6; color: "transparent" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    startX: 64; startY: 0
                    PathLine { x: root.bw - 64; y: 0 }
                    PathLine { x: root.bw; y: 64 }
                    PathLine { x: root.bw; y: 296 }
                    PathLine { x: root.bw - 330; y: 374 }
                    PathLine { x: 330; y: 374 }
                    PathLine { x: 0; y: 296 }
                    PathLine { x: 0; y: 64 }
                }
            }

            Rectangle {
                x: (root.bw - width) / 2
                y: 18
                width: 588
                height: 340
                radius: 34
                antialiasing: true
                color: root.gp.gel
                border.width: 2
                border.color: root.gp.gelRim
                opacity: 0.55
                Rectangle {
                    x: 10; y: 2
                    width: parent.width - 20
                    height: 18
                    radius: 9
                    color: Qt.rgba(1, 1, 1, 0.45)
                }
            }

            Rectangle {
                id: bezel
                x: (root.bw - width) / 2
                y: 26
                width: 568
                height: 324
                radius: 26
                antialiasing: true
                color: "#05070c"
                border.width: 1
                border.color: "#40ffffff"
            }

            Rectangle {
                id: screen
                x: (root.bw - width) / 2
                y: 36
                width: 544
                height: 304
                radius: 14
                antialiasing: true
                clip: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.pal.wall0 }
                    GradientStop { position: 0.4; color: root.pal.wall1 }
                    GradientStop { position: 0.8; color: root.pal.wall2 }
                    GradientStop { position: 1.0; color: root.pal.wall3 }
                }

                Item {
                    id: content
                    anchors.fill: parent
                    transformOrigin: Item.Center
                    scale: 1
                    transform: Scale {
                        origin.x: screen.width / 2
                        origin.y: screen.height / 2
                        xScale: Math.min(1, 0.02 + root.power * 2.4)
                        yScale: Math.max(0.006, root.power)
                    }
                    opacity: root.power > 0.01 ? 1 : 0

                    Rectangle { x: -50 + root.sx * 20; y: 30; width: 220; height: 220; radius: 110; color: root.pal.blobA }
                    Rectangle { x: 360 + root.sx * 30; y: 120; width: 170; height: 170; radius: 85; color: root.pal.blobB }
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: root.pal.arc
                            strokeWidth: 2
                            fillColor: "transparent"
                            startX: -20; startY: 250
                            PathQuad { x: screen.width + 20; y: 170; controlX: screen.width * 0.5; controlY: 330 }
                        }
                    }

                    Rectangle {
                        id: bar
                        width: parent.width
                        height: 26
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.host.night ? 0.4 : 0.18) }
                            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.0) }
                        }

                        Row {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8
                            Rectangle {
                                width: 22; height: 15; radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: root.pal.status
                                Text { anchors.centerIn: parent; text: "L"; font.family: "Michroma"; font.pixelSize: 8; color: root.pal.status }
                            }
                            Repeater {
                                model: root.host.pageNames
                                delegate: Text {
                                    required property string modelData
                                    required property int index
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.toUpperCase()
                                    font.family: "Michroma"
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                    color: root.pal.status
                                    opacity: root.host.page === index ? 1 : 0.45
                                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: root.host.page = index }
                                }
                            }
                            Rectangle {
                                width: 22; height: 15; radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: root.pal.status
                                Text { anchors.centerIn: parent; text: "R"; font.family: "Michroma"; font.pixelSize: 8; color: root.pal.status }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: root.host.toastText.length > 0
                            text: root.host.toastText
                            font.family: "Exo 2"
                            font.weight: Font.Black
                            font.pixelSize: 12
                            color: "#ffffff"
                            style: Text.Outline
                            styleColor: root.pal.on2
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Text {
                                visible: !!(root.host.backend && root.host.backend.st.rec)
                                text: "●"
                                font.pixelSize: 10
                                color: "#ff4d5e"
                            }
                            Text {
                                text: root.host.backend && root.host.backend.st.wifi ? "\u{F05A9}" : "\u{F05AA}"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                color: root.pal.status
                            }
                            Text {
                                visible: !!(root.host.backend && root.host.backend.st.bat >= 0)
                                text: (root.host.backend && root.host.backend.st.charging ? "\u{F0084} " : "\u{F0079} ") + (root.host.backend ? root.host.backend.st.bat : 0)
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 11
                                color: root.pal.status
                            }
                            Text {
                                text: Qt.formatTime(root.host.now, "HH:mm")
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 11
                                color: root.pal.status
                            }
                        }
                    }

                    Pages {
                        id: pagesItem
                        host: root.host
                        anchors.top: bar.bottom
                        anchors.bottom: parent.bottom
                        width: parent.width
                        compact: true
                        reveal: root.power
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#ffffff"
                    opacity: root.flash * 0.85
                    visible: opacity > 0.01
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
                        x1: -screen.width + root.sweep * screen.width * 2.2; y1: 0
                        x2: x1 + screen.width * 0.6; y2: screen.height
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.4) }
                        GradientStop { position: 0.58; color: Qt.rgba(1, 1, 1, 0.0) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                    PathRectangle { x: 0; y: 0; width: screen.width; height: screen.height; radius: 14 }
                }
            }

            Item {
                id: dpad
                x: 58
                y: 96
                width: 132
                height: 132
                property string held: ""

                Repeater {
                    model: [
                        { d: "up", x: 44, y: 0, r: 0 }, { d: "down", x: 44, y: 88, r: 180 },
                        { d: "left", x: 0, y: 44, r: 270 }, { d: "right", x: 88, y: 44, r: 90 }
                    ]
                    delegate: Item {
                        required property var modelData
                        x: modelData.x
                        y: modelData.y + (dpad.held === modelData.d ? 2 : 0)
                        width: 44
                        height: 44
                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 3
                            radius: 12
                            color: root.dark ? "#000000" : "#558a99ad"
                        }
                        Rectangle {
                            width: parent.width
                            height: parent.height - 2
                            radius: 12
                            antialiasing: true
                            border.width: 1
                            border.color: root.gp.keyRim
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.gp.key0 }
                                GradientStop { position: 0.5; color: root.gp.key1 }
                                GradientStop { position: 0.52; color: root.gp.key2 }
                                GradientStop { position: 1.0; color: root.gp.key3 }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "\u{F0143}"
                                rotation: modelData.r
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 20
                                color: dpad.held === modelData.d ? root.pal.glow : root.gp.keyGlyph
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onPressed: dpad.held = modelData.d
                            onReleased: dpad.held = ""
                            onCanceled: dpad.held = ""
                            onClicked: root.host.keypad(modelData.d)
                        }
                    }
                }
                Rectangle {
                    x: 44; y: 44
                    width: 44; height: 44
                    radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.gp.key1 }
                        GradientStop { position: 1.0; color: root.gp.key2 }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 16; height: 16; radius: 8
                        color: "transparent"
                        border.width: 2
                        border.color: root.tint(root.pal.glow, 0.7)
                    }
                }
            }

            Item {
                id: orbs
                x: root.bw - 58 - 132
                y: 96
                width: 132
                height: 132

                Repeater {
                    model: [
                        { k: "softR", g: "⬡", x: 44, y: 0 },
                        { k: "ok", g: "◉", x: 88, y: 44 },
                        { k: "end", g: "✦", x: 44, y: 88 },
                        { k: "softL", g: "◢", x: 0, y: 44 }
                    ]
                    delegate: Item {
                        required property var modelData
                        x: modelData.x
                        y: modelData.y
                        width: 44
                        height: 44
                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 3
                            radius: 22
                            color: root.dark ? "#000000" : "#558a99ad"
                        }
                        Rectangle {
                            width: 44; height: 42
                            y: orbArea.pressed ? 2 : 0
                            radius: 22
                            antialiasing: true
                            border.width: 1.5
                            border.color: root.dark ? "#666fd3ff" : "#ffffffff"
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.tint(root.pal.on0, root.dark ? 0.55 : 0.75) }
                                GradientStop { position: 0.5; color: root.tint(root.pal.on1, root.dark ? 0.45 : 0.6) }
                                GradientStop { position: 1.0; color: root.tint(root.pal.on2, root.dark ? 0.7 : 0.8) }
                            }
                            Rectangle {
                                x: 8; y: 3
                                width: 28; height: 15
                                radius: 7.5
                                color: Qt.rgba(1, 1, 1, orbArea.containsMouse ? 0.75 : 0.55)
                            }
                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: 1
                                text: modelData.g
                                font.pixelSize: 18
                                font.weight: Font.Black
                                color: "#ffffff"
                                style: Text.Raised
                                styleColor: "#661446c2"
                            }
                        }
                        MouseArea {
                            id: orbArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.host.keypad(modelData.k)
                        }
                    }
                }
            }

            Repeater {
                model: [76, root.bw - 76 - 96]
                delegate: Grid {
                    required property var modelData
                    x: modelData
                    y: 262
                    columns: 8
                    spacing: 6
                    Repeater {
                        model: 24
                        delegate: Rectangle { width: 6; height: 6; radius: 3; color: root.gp.grille }
                    }
                }
            }

            Text {
                x: (root.bw - implicitWidth) / 2
                y: 356
                text: "NEXUS"
                font.family: "Michroma"
                font.pixelSize: 11
                font.letterSpacing: 6
                color: root.gp.ink
            }

            Repeater {
                model: [
                    { k: "night", g: "\u{F050E}", x: 306 }, { k: "vol-", g: "−", x: 360 }, { k: "vol+", g: "+", x: 406 },
                    { k: "home", g: "\u{F02DC}", x: 554 }, { k: "lock", g: "\u{F033E}", x: 600 }, { k: "end", g: "\u{F0425}", x: 646 }
                ]
                delegate: Rectangle {
                    required property var modelData
                    x: modelData.x
                    y: 357 + (keyArea.pressed ? 1 : 0)
                    width: 40
                    height: 14
                    radius: 7
                    antialiasing: true
                    border.width: 1
                    border.color: root.gp.keyRim
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.gp.key0 }
                        GradientStop { position: 1.0; color: root.gp.key2 }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.g
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 10
                        color: keyArea.containsMouse ? root.pal.glow : root.gp.keyGlyph
                    }
                    MouseArea {
                        id: keyArea
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.k === "night") root.host.act("night")
                            else if (modelData.k === "lock") root.host.act("lock")
                            else root.host.keypad(modelData.k)
                        }
                    }
                }
            }

            Rectangle {
                x: root.bw - 134
                y: 250
                width: 8; height: 8; radius: 4
                color: root.host.backend && root.host.backend.st.rec ? "#ff4d5e" : "#3ddc97"
                opacity: 0.4 + root.power * 0.6
                Rectangle { anchors.centerIn: parent; width: 16; height: 16; radius: 8; color: parent.color; opacity: 0.25 }
            }
        }
    }

    function tint(hex, a) { return host.tint(hex, a) }
}
