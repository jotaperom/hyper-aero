import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint

Item {
    id: root
    property var host
    property string variant: "holo"
    readonly property alias pages: pagesItem
    readonly property var hp: Tint.palette(holoBase, host.accent)
    readonly property var pal: Object.assign({}, host.pal, hp)
    readonly property var holoBase: ({
        beam: "#6fd3ff", beamDeep: "#1e6fd9",
        text: "#e8f8ff", muted: "#9fd4f2", accent: "#8fe3ff", glow: "#6fd3ff", ring: "#bdf0ff",
        tile0: "#406fd3ff", tile1: "#2a3d9be9", tile2: "#1f1e6fd9", tile3: "#2a3d9be9",
        tileBorder: "#996fd3ff", onBorder: "#e6bdf0ff",
        on0: "#b36fd3ff", on1: "#993d9be9", on2: "#8c1e6fd9", on3: "#993d9be9",
        glossTop: 0.18, badge: "#333d9be9", track: "#401e6fd9",
        icon0: "#4d6fd3ff", icon1: "#333d9be9", icon2: "#261e6fd9", iconBorder: "#b36fd3ff", iconGloss: 0.2,
        field: "#331e6fd9", shelf: "#261e6fd9", accentFill: "#3d9be9",
        hero: "#e8f8ff", heroShadow: "#991e6fd9", heroSub: "#bfe9ff",
        label: "#e8f8ff", labelShadow: "#cc0a2a66", status: "#e8f8ff",
        bubble: "#401e6fd9", bar0: "#993d9be9", bar1: "#991446c2",
        blobA: "#1a6fd3ff", blobB: "#146fd3ff", blobC: "#106fd3ff", arc: "#666fd3ff",
        paper0: "#cfeeff", paper1: "#8cc6f5"
    })
    readonly property real pw: 344
    readonly property real ph: 600
    readonly property real fit: Math.min(1, height / 864)
    property real shown: 0
    property real base: 0
    property real beam: 0
    property real form: 0
    property real flick: 1
    property real scan: 0

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
    Behavior on sx { SmoothedAnimation { velocity: 0.6 } }
    Behavior on sy { SmoothedAnimation { velocity: 0.6 } }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 300 }
        NumberAnimation { target: root; property: "base"; from: 0; to: 1; duration: 420; easing.type: Easing.OutBack }
        SequentialAnimation {
            PropertyAction { target: root; property: "form"; value: 0 }
            PauseAnimation { duration: 260 }
            NumberAnimation { target: root; property: "beam"; from: 0; to: 1; duration: 320; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "form"; from: 0; to: 1; duration: 620; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 600 }
            NumberAnimation { target: root; property: "flick"; to: 0.35; duration: 60 }
            NumberAnimation { target: root; property: "flick"; to: 1; duration: 60 }
            PauseAnimation { duration: 120 }
            NumberAnimation { target: root; property: "flick"; to: 0.5; duration: 50 }
            NumberAnimation { target: root; property: "flick"; to: 1; duration: 80 }
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: root; property: "form"; to: 0; duration: 300; easing.type: Easing.InCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "beam"; to: 0; duration: 180 }
            NumberAnimation { target: root; property: "base"; to: 0; duration: 260; easing.type: Easing.InBack }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 260 }
        }
        onFinished: if (root.host) root.host.closed()
    }

    NumberAnimation on scan {
        running: root.form > 0.99 && root.host.active
        from: 0
        to: 1
        duration: 4200
        loops: Animation.Infinite
    }

    Timer {
        interval: 2600
        repeat: true
        running: root.form > 0.99 && root.host.active
        onTriggered: glitch.restart()
    }

    SequentialAnimation {
        id: glitch
        NumberAnimation { target: root; property: "flick"; to: 0.82; duration: 40 }
        NumberAnimation { target: root; property: "flick"; to: 1; duration: 90 }
    }

    Item {
        id: rig
        width: 420
        height: 820
        x: 40 * root.fit
        y: root.height - height * root.fit
        transformOrigin: Item.TopLeft
        scale: root.fit
        opacity: Math.max(0, Math.min(1, root.shown * 2))

        Item {
            id: emitter
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 92 + (1 - root.base) * 120
            width: 300
            height: 80

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 34
                width: 300; height: 46
                radius: 23
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#3a4560" }
                    GradientStop { position: 1.0; color: "#0b0f1a" }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 10
                width: 300; height: 52
                radius: 26
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#c9d6e8" }
                    GradientStop { position: 0.5; color: "#6d7d98" }
                    GradientStop { position: 1.0; color: "#2a3448" }
                }
                border.width: 1
                border.color: "#e6ffffff"
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 16
                width: 236; height: 38
                radius: 19
                color: "#0b1426"
                border.width: 3
                border.color: root.tint(root.hp.beam, 0.4 + 0.6 * root.beam)
                Rectangle {
                    anchors.centerIn: parent
                    width: 90; height: 16; radius: 8
                    color: root.tint(root.hp.beam, 0.3 + 0.7 * root.beam)
                }
            }
        }

        Shape {
            id: cone
            anchors.fill: parent
            opacity: root.beam * 0.55 * root.flick
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: 0; y1: emitter.y + 30
                    x2: 0; y2: panel.y + panel.height
                    GradientStop { position: 0.0; color: root.tint(root.hp.beam, 0.75) }
                    GradientStop { position: 1.0; color: root.tint(root.hp.beam, 0.0) }
                }
                startX: rig.width / 2 - 46; startY: emitter.y + 34
                PathLine { x: rig.width / 2 + 46; y: emitter.y + 34 }
                PathLine { x: panel.x + panel.width - 8; y: panel.y + panel.height - 4 }
                PathLine { x: panel.x + 8; y: panel.y + panel.height - 4 }
            }
        }

        Item {
            id: panel
            x: (rig.width - root.pw) / 2
            y: 20
            width: root.pw
            height: root.ph
            opacity: root.flick
            transform: Rotation {
                origin.x: root.pw / 2
                origin.y: root.ph / 2
                axis.x: 6 - root.sy * 10
                axis.y: 10 + root.sx * 14
                axis.z: 0
                angle: 16
            }

            Item {
                id: reveal
                width: parent.width
                height: parent.height * root.form
                y: parent.height - height
                clip: true

                Item {
                    y: -(root.ph - reveal.height)
                    width: root.pw
                    height: root.ph

                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: root.tint(root.hp.beamDeep, root.host.night ? 0.18 : 0.42)
                        border.width: 1.5
                        border.color: root.tint(root.hp.beam, 0.85)
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 16
                        color: "transparent"
                        border.width: 1
                        border.color: root.tint(root.hp.beam, 0.3)
                    }

                    Item {
                        id: status
                        x: 16
                        width: parent.width - 32
                        height: 30
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "◢ HOLO·LINK"
                            font.family: "Michroma"
                            font.pixelSize: 9
                            font.letterSpacing: 2
                            color: root.hp.text
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatTime(root.host.now, "HH:mm:ss")
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 11
                            color: root.hp.text
                        }
                    }

                    Pages {
                        id: pagesItem
                        host: root.host
                        pal: root.pal
                        x: 6
                        anchors.top: status.bottom
                        anchors.bottom: tabs.top
                        width: parent.width - 12
                        compact: true
                        reveal: root.form
                    }

                    Row {
                        id: tabs
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 10
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Repeater {
                            model: root.host.pageNames
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                width: 92
                                height: 24
                                radius: 12
                                color: root.host.page === index ? root.tint(root.hp.beam, 0.35) : "transparent"
                                border.width: 1
                                border.color: root.tint(root.hp.beam, root.host.page === index ? 0.9 : 0.4)
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.toUpperCase()
                                    font.family: "Michroma"
                                    font.pixelSize: 8
                                    font.letterSpacing: 1
                                    color: root.hp.text
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.host.page = index
                                }
                            }
                        }
                    }

                    Repeater {
                        model: Math.floor(root.ph / 3)
                        delegate: Rectangle {
                            required property int index
                            y: index * 3
                            width: root.pw
                            height: 1
                            color: root.tint(root.hp.beam, 0.06)
                        }
                    }

                    Rectangle {
                        y: root.scan * (root.ph + 60) - 60
                        width: root.pw
                        height: 60
                        visible: root.form > 0.99
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.8; color: root.tint(root.hp.beam, 0.08) }
                            GradientStop { position: 1.0; color: root.tint(root.hp.beam, 0.22) }
                        }
                    }

                    Repeater {
                        model: [[0, 0, 1, 1], [1, 0, -1, 1], [0, 1, 1, -1], [1, 1, -1, -1]]
                        delegate: Shape {
                            required property var modelData
                            x: modelData[0] * root.pw
                            y: modelData[1] * root.ph
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: root.hp.ring
                                strokeWidth: 2.5
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                startX: modelData[2] * 26; startY: 0
                                PathLine { x: 0; y: 0 }
                                PathLine { x: 0; y: modelData[3] * 26 }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width + 20
                x: -10
                height: 3
                radius: 1.5
                y: parent.height * (1 - root.form) - 1
                visible: root.form > 0.01 && root.form < 0.99
                color: root.hp.ring
                Rectangle { anchors.centerIn: parent; width: parent.width; height: 14; radius: 7; color: root.tint(root.hp.beam, 0.35) }
            }
        }
    }
}
