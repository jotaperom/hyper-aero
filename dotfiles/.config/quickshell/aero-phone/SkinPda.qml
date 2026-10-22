import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint

Item {
    id: root
    property var host
    property string variant: "pda"
    readonly property alias pages: pagesItem
    readonly property var pal: host.pal
    readonly property var cp: Tint.palette(host.night ? cNight : cDay, host.accent)
    readonly property var cDay: ({
        glass0: "#b3cfeaff", glass1: "#8c7fbdf3", glass2: "#993d9be9", glass3: "#b35aa8ee",
        rim: "#e6ffffff", trace: "#661446c2", chip: "#40123a7a", label: "#1446c2", btn0: "#f2ffffff", btn1: "#cc9fd0f7"
    })
    readonly property var cNight: ({
        glass0: "#b3305a96", glass1: "#99173462", glass2: "#a60e2450", glass3: "#b31b3a6e",
        rim: "#996fd3ff", trace: "#806fd3ff", chip: "#4d000000", label: "#6fd3ff", btn0: "#cc3c5a8c", btn1: "#cc16284a"
    })
    readonly property real pw: 388
    readonly property real ph: 590
    readonly property real fit: Math.min(1, height / 864)
    property real shown: 0
    property real pop: 0
    property real stylus: 0
    property real pixels: 0
    property real twist: 1

    function tint(hex, a) { return host.tint(hex, a) }

    function open() {
        closeAnim.stop()
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
    readonly property real tiltY: 10 + sx * 9 + twist * 24
    readonly property real tiltX: 6 - sy * 6 + twist * 16
    readonly property real ang: Math.sqrt(tiltX * tiltX + tiltY * tiltY)
    readonly property real axX: ang > 0.001 ? tiltX / ang : 1
    readonly property real axY: ang > 0.001 ? tiltY / ang : 0

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 320 }
        NumberAnimation { target: root; property: "pop"; from: 0; to: 1; duration: 640; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
        NumberAnimation { target: root; property: "twist"; from: 1; to: 0; duration: 1200; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.8 }
        SequentialAnimation {
            PauseAnimation { duration: 380 }
            NumberAnimation { target: root; property: "pixels"; from: 0; to: 1; duration: 700 }
        }
        SequentialAnimation {
            PauseAnimation { duration: 600 }
            NumberAnimation { target: root; property: "stylus"; from: 0; to: 1; duration: 520; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
        }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "stylus"; to: 0; duration: 200 }
            NumberAnimation { target: root; property: "pixels"; to: 0; duration: 260 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "pop"; to: 0; duration: 280; easing.type: Easing.InBack; easing.overshoot: 1.4 }
            NumberAnimation { target: root; property: "twist"; to: -0.4; duration: 280 }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 280 }
        }
        onFinished: if (root.host) root.host.closed()
    }

    Item {
        id: rig
        width: root.pw + 40
        height: root.ph + 120
        x: 66 * root.fit
        y: root.height - 30 * root.fit - root.ph * root.fit
        transformOrigin: Item.TopLeft
        scale: root.fit
        opacity: Math.max(0, Math.min(1, root.shown * 2))

        Item {
            id: dev
            width: root.pw
            height: root.ph
            transformOrigin: Item.Bottom
            scale: 0.6 + 0.4 * root.pop
            transform: Translate { y: (1 - root.pop) * 260 }

            Item {
                id: stylusItem
                x: root.pw - 12
                y: 60 - root.stylus * 150
                width: 12
                height: 420
                transform: Rotation {
                    origin.x: root.pw / 2 - stylusItem.x
                    origin.y: root.ph / 2 - stylusItem.y
                    origin.z: 10
                    axis.x: root.axX; axis.y: root.axY; axis.z: 0
                    angle: root.ang
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#8794a8" }
                        GradientStop { position: 0.4; color: "#f6f9fc" }
                        GradientStop { position: 1.0; color: "#6b788c" }
                    }
                }
                Rectangle {
                    y: 0
                    width: parent.width
                    height: 34
                    radius: 6
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.pal.on2 }
                        GradientStop { position: 0.5; color: root.pal.on0 }
                        GradientStop { position: 1.0; color: root.pal.on2 }
                    }
                }
            }

            Repeater {
                model: 12
                delegate: Rectangle {
                    required property int index
                    width: root.pw
                    height: root.ph
                    radius: 50
                    antialiasing: true
                    color: root.tint(root.pal.glow, 0.06 + index * 0.012)
                    transform: Rotation {
                        origin.x: root.pw / 2
                        origin.y: root.ph / 2
                        origin.z: (12 - index) * 0.7
                        axis.x: root.axX; axis.y: root.axY; axis.z: 0
                        angle: root.ang
                    }
                }
            }

            Item {
                width: root.pw
                height: root.ph
                transform: Rotation {
                    origin.x: root.pw / 2
                    origin.y: root.ph / 2
                    axis.x: root.axX; axis.y: root.axY; axis.z: 0
                    angle: root.ang
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 50
                    antialiasing: true
                    border.width: 2
                    border.color: root.cp.rim
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.cp.glass0 }
                        GradientStop { position: 0.45; color: root.cp.glass1 }
                        GradientStop { position: 0.55; color: root.cp.glass2 }
                        GradientStop { position: 1.0; color: root.cp.glass3 }
                    }
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    opacity: 0.7
                    ShapePath {
                        strokeColor: root.cp.trace
                        strokeWidth: 1.4
                        fillColor: "transparent"
                        startX: 30; startY: 470
                        PathLine { x: 70; y: 470 }
                        PathLine { x: 90; y: 500 }
                        PathLine { x: 160; y: 500 }
                        PathMove { x: 360; y: 120 }
                        PathLine { x: 360; y: 300 }
                        PathLine { x: 372; y: 312 }
                        PathLine { x: 372; y: 430 }
                        PathMove { x: 20; y: 140 }
                        PathLine { x: 20; y: 360 }
                        PathMove { x: 220; y: 560 }
                        PathLine { x: 260; y: 520 }
                        PathLine { x: 340; y: 520 }
                    }
                }
                Repeater {
                    model: [[64, 528, 34, 18], [292, 538, 46, 22], [356, 450, 14, 30]]
                    delegate: Rectangle {
                        required property var modelData
                        x: modelData[0]; y: modelData[1]
                        width: modelData[2]; height: modelData[3]
                        radius: 3
                        color: root.cp.chip
                        border.width: 1
                        border.color: root.cp.trace
                    }
                }

                Rectangle {
                    x: 3; y: 3
                    width: parent.width - 6
                    height: 160
                    topLeftRadius: 47; topRightRadius: 47
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.host.night ? 0.2 : 0.55) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }

                Rectangle {
                    x: root.pw / 2 - 30
                    y: 16
                    width: 60; height: 12; radius: 6
                    color: "#a6200a1a"
                    border.width: 1
                    border.color: "#66ffffff"
                }

                Rectangle {
                    x: 22; y: 38
                    width: root.pw - 44
                    height: 392
                    radius: 20
                    color: root.pal.bezel
                    border.width: 1
                    border.color: "#66ffffff"
                }

                Rectangle {
                    id: screen
                    x: 30; y: 46
                    width: root.pw - 60
                    height: 376
                    radius: 14
                    clip: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.pal.wall0 }
                        GradientStop { position: 0.4; color: root.pal.wall1 }
                        GradientStop { position: 0.8; color: root.pal.wall2 }
                        GradientStop { position: 1.0; color: root.pal.wall3 }
                    }

                    Rectangle { x: -50 + root.sx * 18; y: 40; width: 200; height: 200; radius: 100; color: root.pal.blobA }
                    Rectangle { x: 170 + root.sx * 24; y: 190; width: 150; height: 150; radius: 75; color: root.pal.blobB }

                    Item {
                        id: status
                        width: parent.width
                        height: 26
                        Text {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: "◢ " + root.host.pageNames[root.host.page].toUpperCase()
                            font.family: "Michroma"
                            font.pixelSize: 9
                            font.letterSpacing: 1
                            color: root.pal.status
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: (root.host.backend && root.host.backend.st.wifi ? "\u{F05A9}  " : "\u{F05AA}  ") + Qt.formatTime(root.host.now, "HH:mm")
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
                        width: parent.width
                        compact: true
                        reveal: root.pixels
                    }

                    Grid {
                        anchors.fill: parent
                        columns: 10
                        Repeater {
                            model: 120
                            delegate: Rectangle {
                                required property int index
                                readonly property real seed: Math.abs(Math.sin(index * 12.9898) * 43758.5453) % 1
                                width: screen.width / 10
                                height: screen.height / 12
                                color: root.pal.bezel
                                opacity: Math.max(0, Math.min(1, (seed - root.pixels * 1.25 + 0.25) * 6))
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 432
                    text: "CRISTAL"
                    font.family: "Michroma"
                    font.pixelSize: 9
                    font.letterSpacing: 5
                    color: root.cp.label
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 462
                    spacing: 14

                    Repeater {
                        model: [
                            { k: "p0", g: "\u{F003B}" }, { k: "p1", g: "\u{F0493}" }, { k: "rocker", g: "" },
                            { k: "p2", g: "\u{F00F6}" }, { k: "end", g: "\u{F0425}" }
                        ]
                        delegate: Item {
                            required property var modelData
                            width: modelData.k === "rocker" ? 66 : 48
                            height: 66

                            Rectangle {
                                visible: modelData.k !== "rocker"
                                anchors.centerIn: parent
                                width: 48; height: 48; radius: 24
                                antialiasing: true
                                y: btnArea.pressed ? 2 : 0
                                border.width: 1.5
                                border.color: root.cp.rim
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: root.cp.btn0 }
                                    GradientStop { position: 1.0; color: root.cp.btn1 }
                                }
                                Rectangle {
                                    x: 9; y: 3
                                    width: 30; height: 16; radius: 8
                                    color: Qt.rgba(1, 1, 1, btnArea.containsMouse ? 0.7 : 0.45)
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.g
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 19
                                    color: (modelData.k === "p0" && root.host.page === 0) || (modelData.k === "p1" && root.host.page === 1) || (modelData.k === "p2" && root.host.page === 2) ? root.pal.glow : root.cp.label
                                }
                                MouseArea {
                                    id: btnArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.k === "p0") root.host.page = 0
                                        else if (modelData.k === "p1") root.host.page = 1
                                        else if (modelData.k === "p2") root.host.page = 2
                                        else root.host.keypad("end")
                                    }
                                }
                            }

                            Rectangle {
                                visible: modelData.k === "rocker"
                                anchors.centerIn: parent
                                width: 56; height: 66; radius: 20
                                antialiasing: true
                                border.width: 1.5
                                border.color: root.cp.rim
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: root.cp.btn0 }
                                    GradientStop { position: 0.5; color: root.cp.btn1 }
                                    GradientStop { position: 1.0; color: root.cp.btn0 }
                                }
                                Column {
                                    anchors.fill: parent
                                    Repeater {
                                        model: [["up", "\u{F0143}"], ["down", "\u{F0140}"]]
                                        delegate: Item {
                                            required property var modelData
                                            width: 56; height: 33
                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData[1]
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 20
                                                color: rk.pressed ? root.pal.glow : root.cp.label
                                            }
                                            MouseArea {
                                                id: rk
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.host.keypad(modelData[0])
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 50
                    color: "transparent"
                    border.width: 1
                    border.color: "#66ffffff"
                    anchors.margins: 5
                }
            }
        }
    }
}
