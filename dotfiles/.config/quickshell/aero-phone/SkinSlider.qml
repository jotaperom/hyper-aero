import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint

Item {
    id: root
    property var host
    property string variant: "slider"
    readonly property alias pages: pagesItem
    readonly property var pal: host.pal
    readonly property var sp: Tint.palette(host.night ? sNight : sDay, host.accent)
    readonly property var sDay: ({
        f0: "#fbfdff", f1: "#dbe6f2", f2: "#f1f6fb", f3: "#a9b8ca", stripe0: "#8cc6f5", stripe1: "#1e6fd9",
        d0: "#e9eff6", d1: "#c3d0de", edge0: "#6f7f94", edge1: "#b3c0cf", rim: "#ffffff"
    })
    readonly property var sNight: ({
        f0: "#3f4f72", f1: "#18223a", f2: "#2a3a5c", f3: "#0b1120", stripe0: "#6fd3ff", stripe1: "#1e6fd9",
        d0: "#26324d", d1: "#121a2c", edge0: "#03060c", edge1: "#18223a", rim: "#806fd3ff"
    })
    readonly property real pw: 340
    readonly property real fh: 584
    readonly property real travel: 226
    readonly property real fit: Math.min(1, height / 864)
    property real shown: 0
    property real rise: 0
    property real twist: 1
    property real slide: 0
    property real glow: 0
    property real keyLight: 0
    property real sweep: 0
    readonly property real assemblyH: fh + travel

    function tint(hex, a) { return host.tint(hex, a) }

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
    readonly property real tiltY: 12 + sx * 9 + twist * 30
    readonly property real tiltX: 6 - sy * 6 + twist * 18
    readonly property real ang: Math.sqrt(tiltX * tiltX + tiltY * tiltY)
    readonly property real axX: ang > 0.001 ? tiltX / ang : 1
    readonly property real axY: ang > 0.001 ? tiltY / ang : 0

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 360; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "rise"; from: 0; to: 1; duration: 620; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        NumberAnimation { target: root; property: "twist"; from: 1; to: 0; duration: 1250; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.75 }
        SequentialAnimation {
            PropertyAction { target: root; property: "slide"; value: 0 }
            PauseAnimation { duration: 420 }
            NumberAnimation { target: root; property: "slide"; to: 1; duration: 560; easing.type: Easing.OutBack; easing.overshoot: 1.9 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 260 }
            NumberAnimation { target: root; property: "glow"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 700 }
            NumberAnimation { target: root; property: "keyLight"; from: 0; to: 1; duration: 600 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 900 }
            NumberAnimation { target: root; property: "sweep"; from: 0; to: 1; duration: 900; easing.type: Easing.InOutSine }
        }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "keyLight"; to: 0; duration: 140 }
            NumberAnimation { target: root; property: "slide"; to: 0; duration: 260; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "glow"; to: 0; duration: 260 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "rise"; to: 0; duration: 320; easing.type: Easing.InBack; easing.overshoot: 1.5 }
            NumberAnimation { target: root; property: "twist"; to: -0.4; duration: 320 }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 320 }
        }
        onFinished: if (root.host) root.host.closed()
    }

    Item {
        id: rig
        width: root.pw
        height: root.assemblyH
        x: 74 * root.fit
        y: root.height - 18 * root.fit - root.assemblyH * root.fit
        transformOrigin: Item.TopLeft
        scale: root.fit
        opacity: Math.max(0, Math.min(1, root.shown * 2))
        transform: [
            Rotation { origin.x: root.pw / 2; origin.y: root.assemblyH; angle: 3 - root.twist * 14 },
            Translate { y: (1 - root.rise) * 900 }
        ]

        Item {
            id: deck
            y: root.travel
            width: root.pw
            height: root.fh

            Repeater {
                model: 12
                delegate: Rectangle {
                    required property int index
                    width: root.pw
                    height: root.fh
                    radius: 44
                    antialiasing: true
                    color: Qt.tint(root.sp.edge0, root.tint(root.sp.edge1, index / 11))
                    transform: Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.assemblyH / 2 - root.travel
                        origin.z: (12 - index) * 0.55 + 7
                        axis.x: root.axX; axis.y: root.axY; axis.z: 0
                        angle: root.ang
                    }
                }
            }

            Item {
                width: root.pw
                height: root.fh
                transform: Rotation {
                    origin.x: root.pw / 2
                    origin.y: root.assemblyH / 2 - root.travel
                    origin.z: 7
                    axis.x: root.axX; axis.y: root.axY; axis.z: 0
                    angle: root.ang
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 44
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.sp.d0 }
                        GradientStop { position: 1.0; color: root.sp.d1 }
                    }
                    border.width: 1
                    border.color: root.sp.rim
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: root.fh - root.travel - 4
                    text: "◢  SLIDER"
                    font.family: "Michroma"
                    font.pixelSize: 8
                    font.letterSpacing: 3
                    color: root.pal.muted
                    opacity: 0.7
                }

                Column {
                    x: 12
                    y: root.fh - root.travel + 14
                    spacing: 5

                    Repeater {
                        model: [
                            "qwertyuiop".split(""),
                            "asdfghjkl".split(""),
                            ["⇧"].concat("zxcvbnm".split("")).concat(["⌫"]),
                            ["◀", ",", "␣", ".", "↵"]
                        ]
                        delegate: Row {
                            id: rowItem
                            required property var modelData
                            required property int index
                            x: [0, 16, 6, 18][index]
                            spacing: 4
                            Repeater {
                                model: rowItem.modelData
                                delegate: GelKey {
                                    required property string modelData
                                    readonly property bool wideKey: modelData === "␣"
                                    readonly property bool midKey: modelData === "⇧" || modelData === "⌫" || modelData === "◀" || modelData === "↵"
                                    width: wideKey ? 132 : (midKey ? 38 : 28)
                                    height: 36
                                    round: 9
                                    pal: root.pal
                                    night: root.host.night
                                    light: Math.max(0, Math.min(1, root.keyLight * 2 - rowItem.index * 0.25))
                                    glyph: modelData === "␣" ? "space" : modelData
                                    tone: midKey ? root.pal.keyLit : "transparent"
                                    onTapped: {
                                        if (modelData === "⌫") root.host.typeKey("\b")
                                        else if (modelData === "↵") root.host.typeKey("\n")
                                        else if (modelData === "␣") root.host.typeKey(" ")
                                        else if (modelData === "◀") root.host.keypad("softL")
                                        else if (modelData === "⇧") root.host.keypad("softR")
                                        else root.host.typeKey(modelData)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: front
            y: root.travel * (1 - root.slide)
            width: root.pw
            height: root.fh

            Repeater {
                model: 14
                delegate: Rectangle {
                    required property int index
                    width: root.pw
                    height: root.fh
                    radius: 44
                    antialiasing: true
                    color: Qt.tint(root.sp.edge0, root.tint(root.sp.edge1, index / 13))
                    transform: Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.assemblyH / 2 - front.y
                        origin.z: (14 - index) * 0.5
                        axis.x: root.axX; axis.y: root.axY; axis.z: 0
                        angle: root.ang
                    }
                }
            }

            Item {
                width: root.pw
                height: root.fh
                transform: Rotation {
                    origin.x: root.pw / 2
                    origin.y: root.assemblyH / 2 - front.y
                    axis.x: root.axX; axis.y: root.axY; axis.z: 0
                    angle: root.ang
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 44
                    antialiasing: true
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.sp.f3 }
                        GradientStop { position: 0.05; color: root.sp.f0 }
                        GradientStop { position: 0.3; color: root.sp.f1 }
                        GradientStop { position: 0.7; color: root.sp.f2 }
                        GradientStop { position: 0.95; color: root.sp.f0 }
                        GradientStop { position: 1.0; color: root.sp.f3 }
                    }
                }
                Rectangle {
                    x: 3; y: 3
                    width: parent.width - 6
                    height: 140
                    topLeftRadius: 41; topRightRadius: 41
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.host.night ? 0.16 : 0.6) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }

                Repeater {
                    model: [6, root.pw - 10]
                    delegate: Rectangle {
                        required property var modelData
                        x: modelData
                        y: 90
                        width: 4
                        height: root.fh - 180
                        radius: 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: root.sp.stripe0 }
                            GradientStop { position: 1.0; color: root.sp.stripe1 }
                        }
                        opacity: 0.5 + root.glow * 0.5
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 16
                    width: 66; height: 6; radius: 3
                    color: root.pal.bezel
                }

                Rectangle {
                    x: 14; y: 32
                    width: root.pw - 28
                    height: 492
                    radius: 22
                    color: root.pal.bezel
                }

                Rectangle {
                    id: screen
                    x: 20; y: 38
                    width: root.pw - 40
                    height: 480
                    radius: 17
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.pal.wall0 }
                        GradientStop { position: 0.35; color: root.pal.wall1 }
                        GradientStop { position: 0.75; color: root.pal.wall2 }
                        GradientStop { position: 1.0; color: root.pal.wall3 }
                    }

                    Rectangle { x: -60 + root.sx * 18; y: 50; width: 220; height: 220; radius: 110; color: root.pal.blobA }
                    Rectangle { x: 150 + root.sx * 26; y: 230; width: 160; height: 160; radius: 80; color: root.pal.blobB }
                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeColor: root.pal.arc
                            strokeWidth: 2
                            fillColor: "transparent"
                            startX: -20; startY: 330
                            PathQuad { x: screen.width + 20; y: 250; controlX: screen.width * 0.45; controlY: 450 }
                        }
                    }

                    Item {
                        id: status
                        width: parent.width
                        height: 26
                        Text {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatTime(root.host.now, "HH:mm")
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 12
                            color: root.pal.status
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    required property int index
                                    width: root.host.page === index ? 14 : 5
                                    height: 5
                                    radius: 2.5
                                    color: root.host.page === index ? root.pal.home : Qt.rgba(1, 1, 1, 0.4)
                                    Behavior on width { NumberAnimation { duration: 200 } }
                                }
                            }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.host.backend && root.host.backend.st.wifi ? "\u{F05A9} " : "\u{F05AA} ") + (root.host.backend ? root.host.backend.st.bat : 0)
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 11
                            color: root.pal.status
                        }
                    }

                    Pages {
                        id: pagesItem
                        host: root.host
                        anchors.top: status.bottom
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        width: parent.width
                        compact: true
                        reveal: root.glow
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        visible: root.host.toastText.length > 0
                        width: toastText.implicitWidth + 24
                        height: 24
                        radius: 12
                        color: "#cc0b1426"
                        Text {
                            id: toastText
                            anchors.centerIn: parent
                            text: root.host.toastText
                            font.family: "Exo 2"
                            font.weight: Font.Bold
                            font.pixelSize: 11
                            color: "#ffffff"
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: root.pal.bezel
                        opacity: 1 - root.glow
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
                            x1: -screen.width * 1.4 + root.sweep * screen.width * 2.8; y1: 0
                            x2: x1 + screen.width * 0.9; y2: screen.height * 0.55
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.0) }
                            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.0) }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, root.host.night ? 0.3 : 0.48) }
                            GradientStop { position: 0.58; color: Qt.rgba(1, 1, 1, 0.0) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        }
                        PathRectangle { x: 0; y: 0; width: screen.width; height: screen.height; radius: 17 }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 534
                    spacing: 14
                    Repeater {
                        model: [["softL", "\u{F0141}"], ["home", "\u{F02DC}"], ["softR", "\u{F0142}"]]
                        delegate: Rectangle {
                            required property var modelData
                            width: modelData[0] === "home" ? 74 : 46
                            height: 30
                            radius: 15
                            antialiasing: true
                            border.width: 1
                            border.color: root.sp.rim
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: navArea.pressed ? root.sp.f1 : root.sp.f0 }
                                GradientStop { position: 1.0; color: root.sp.f1 }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: modelData[1]
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: navArea.containsMouse ? root.pal.glow : root.pal.muted
                            }
                            MouseArea {
                                id: navArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.host.keypad(modelData[0])
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 44
                    color: "transparent"
                    border.width: 1.5
                    border.color: root.sp.rim
                    opacity: 0.85
                }
            }
        }
    }
}
