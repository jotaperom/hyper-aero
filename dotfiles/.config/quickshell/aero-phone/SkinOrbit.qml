import QtQuick
import QtQuick.Shapes
import "Tint.js" as Tint
import "Lang.js" as L

Item {
    id: root
    property var host
    property string variant: "orbit"
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
        blobA: "#106fd3ff", blobB: "#0c6fd3ff", blobC: "#086fd3ff", arc: "#666fd3ff",
        paper0: "#cfeeff", paper1: "#8cc6f5"
    })
    readonly property real fit: Math.min(1, height / 864)
    property int frameSize: 320
    readonly property real cx: 300 * fit
    readonly property real cy: height - 272 * fit
    readonly property real gr: 150 * fit
    readonly property real rx: 270 * fit
    readonly property real ry: 74 * fit
    readonly property real tilt: -12 * Math.PI / 180
    property real shown: 0
    property real form: 0
    property real ringDraw: 0
    property real spread: 0
    property real spin: 0
    property bool hoverRing: false
    readonly property var allApps: host.backend && host.backend.apps ? host.backend.apps : []
    readonly property var usage: host.backend && host.backend.usage ? host.backend.usage : ({})
    readonly property bool searching: !!(pagesItem.apps.query && pagesItem.apps.query.length)
    readonly property var orbitApps: {
        if (searching) return pagesItem.apps.results.slice(0, 12)
        var list = allApps.slice()
        var u = usage
        list.sort(function(a, b) { return (u[b.key] || 0) - (u[a.key] || 0) || (a.sortName < b.sortName ? -1 : 1) })
        return list.slice(0, 10)
    }

    function tint(hex, a) { return host.tint(hex, a) }

    function open() {
        closeAnim.stop()
        openAnim.restart()
    }

    function close() {
        openAnim.stop()
        closeAnim.restart()
    }

    function pos(i, n) {
        var t = root.spin + i * Math.PI * 2 / Math.max(1, n)
        var ex = Math.cos(t) * root.rx * root.spread
        var ey = Math.sin(t) * root.ry * root.spread
        return {
            x: root.cx + ex * Math.cos(root.tilt) - ey * Math.sin(root.tilt),
            y: root.cy + ex * Math.sin(root.tilt) + ey * Math.cos(root.tilt),
            depth: Math.sin(t)
        }
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "shown"; to: 1; duration: 300 }
        NumberAnimation { target: root; property: "form"; from: 0; to: 1; duration: 700; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        SequentialAnimation {
            PauseAnimation { duration: 260 }
            NumberAnimation { target: root; property: "ringDraw"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 420 }
            NumberAnimation { target: root; property: "spread"; from: 0; to: 1; duration: 760; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "spread"; to: 0; duration: 260; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "ringDraw"; to: 0; duration: 260 }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "form"; to: 0; duration: 260; easing.type: Easing.InBack }
            NumberAnimation { target: root; property: "shown"; to: 0; duration: 260 }
        }
        onFinished: if (root.host) root.host.closed()
    }

    NumberAnimation on spin {
        running: root.host.active && !root.hoverRing
        from: root.spin
        to: root.spin + Math.PI * 2
        duration: 48000
        loops: Animation.Infinite
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: Math.max(0, Math.min(1, root.shown * 1.5))

        Rectangle {
            x: root.cx - width / 2
            y: root.cy - height / 2
            width: root.gr * 3.4
            height: width
            radius: width / 2
            opacity: 0.55 * root.form
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.tint(root.hp.beam, 0.14) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Shape {
            id: ringBack
            anchors.fill: parent
            z: 1
            preferredRendererType: Shape.CurveRenderer
            opacity: 0.6
            ShapePath {
                strokeColor: root.hp.beam
                strokeWidth: 1.5
                strokeStyle: ShapePath.DashLine
                dashPattern: [2, 4]
                fillColor: "transparent"
                PathAngleArc {
                    centerX: 0; centerY: 0
                    radiusX: root.rx; radiusY: root.ry
                    startAngle: 180; sweepAngle: 180 * root.ringDraw
                }
            }
            transform: [
                Rotation { angle: root.tilt * 180 / Math.PI },
                Translate { x: root.cx; y: root.cy }
            ]
        }

        AnimatedSprite {
            id: globe
            z: 2
            x: root.cx - width / 2
            y: root.cy - height / 2
            width: root.gr * 2 * 320 / 284
            height: width
            source: "globe/globe-" + Tint.nearestPreset(root.host.accent) + ".png"
            frameWidth: root.frameSize
            frameHeight: root.frameSize
            frameCount: 60
            frameDuration: 110
            loops: AnimatedSprite.Infinite
            running: root.host.active
            interpolate: true
            scale: root.form
            opacity: Math.min(1, root.form * 1.4)
        }

        Shape {
            id: ringFront
            anchors.fill: parent
            z: 3
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: root.hp.ring
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: 0; centerY: 0
                    radiusX: root.rx; radiusY: root.ry
                    startAngle: 0; sweepAngle: 180 * root.ringDraw
                }
            }
            transform: [
                Rotation { angle: root.tilt * 180 / Math.PI },
                Translate { x: root.cx; y: root.cy }
            ]
        }

        Column {
            z: 4
            x: root.cx - width / 2
            y: root.cy - root.gr - 104 * root.fit
            opacity: root.form
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(root.host.now, "HH:mm")
                font.family: "Michroma"
                font.pixelSize: 44 * root.fit
                color: root.hp.text
                style: Text.Outline
                styleColor: root.tint(root.hp.beamDeep, 0.6)
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.locale(L.LOCALE).toString(root.host.now, L.t("dddd d MMMM")).toUpperCase()
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
                font.pixelSize: 11 * root.fit
                font.letterSpacing: 2
                color: root.hp.muted
            }
        }

        Repeater {
            model: root.orbitApps
            delegate: Item {
                id: node
                required property var modelData
                required property int index
                readonly property var p: root.pos(index, root.orbitApps.length)
                readonly property real s: (0.72 + 0.28 * (p.depth + 1) / 2) * root.fit
                z: p.depth > 0 ? 5 : 1.5
                x: p.x - width / 2
                y: p.y - height / 2
                width: 58 * s
                height: 58 * s
                opacity: (0.45 + 0.55 * (p.depth + 1) / 2) * Math.min(1, root.spread * 1.5)

                Rectangle {
                    anchors.fill: parent
                    radius: width * 0.3
                    color: root.tint(root.hp.beamDeep, 0.35)
                    border.width: 1.5
                    border.color: hot.containsMouse ? "#ffffff" : root.tint(root.hp.beam, 0.85)
                    scale: hot.containsMouse ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Image {
                        id: ic
                        anchors.centerIn: parent
                        width: parent.width * 0.68
                        height: width
                        source: node.modelData.icon
                        sourceSize.width: 96
                        sourceSize.height: 96
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: ic.status !== Image.Ready
                        text: node.modelData.name.charAt(0).toUpperCase()
                        font.family: "Michroma"
                        font.pixelSize: parent.width * 0.4
                        color: root.hp.text
                    }
                }
                Text {
                    anchors.top: parent.bottom
                    anchors.topMargin: 3
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: node.p.depth > 0.35 || hot.containsMouse
                    text: node.modelData.name
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 11 * root.fit
                    color: root.hp.text
                    style: Text.Outline
                    styleColor: root.tint(root.hp.beamDeep, 0.7)
                }
                MouseArea {
                    id: hot
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: root.hoverRing = containsMouse
                    onClicked: {
                        if (root.host.backend) root.host.backend.launch(node.modelData.key)
                        root.host.requestClose()
                    }
                }
            }
        }

        Repeater {
            model: [
                { p: 1, g: "\u{F0493}", t: "CONTROL", a: -2.35 },
                { p: 2, g: "\u{F00F6}", t: L.t("HOY"), a: -0.79 }
            ]
            delegate: Item {
                id: sat
                required property var modelData
                readonly property real ax: root.cx + Math.cos(modelData.a) * (root.gr + 96 * root.fit)
                readonly property real ay: root.cy + Math.sin(modelData.a) * (root.gr + 96 * root.fit)
                readonly property bool on: root.host.page === modelData.p
                z: 6
                x: ax - width / 2
                y: ay - height / 2
                width: 64 * root.fit
                height: 64 * root.fit
                scale: root.spread
                Shape {
                    x: sat.width / 2
                    y: sat.height / 2
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: root.tint(root.hp.beam, 0.5)
                        strokeWidth: 1
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [2, 3]
                        startX: 0; startY: 0
                        PathLine { x: root.cx - sat.ax; y: root.cy - sat.ay }
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.tint(root.hp.beamDeep, sat.on ? 0.7 : 0.35)
                    border.width: 2
                    border.color: sat.on ? "#ffffff" : root.hp.beam
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 14
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 1
                        border.color: root.tint(root.hp.beam, satArea.containsMouse || sat.on ? 0.8 : 0.3)
                    }
                    Text {
                        anchors.centerIn: parent
                        text: sat.modelData.g
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 26 * root.fit
                        color: root.hp.text
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 9
                    text: sat.modelData.t
                    font.family: "Michroma"
                    font.pixelSize: 9 * root.fit
                    font.letterSpacing: 2
                    color: root.hp.text
                }
                MouseArea {
                    id: satArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.host.page = sat.on ? 0 : sat.modelData.p
                }
            }
        }

        Rectangle {
            id: search
            z: 6
            x: root.cx - width / 2
            y: root.cy + root.gr + 48 * root.fit
            width: 340 * root.fit
            height: 40 * root.fit
            radius: height / 2
            opacity: root.spread
            color: root.tint(root.hp.beamDeep, 0.35)
            border.width: 1.5
            border.color: root.hp.beam
            Text {
                id: lens
                x: 14 * root.fit
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F0349}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16 * root.fit
                color: root.hp.text
            }
            Text {
                anchors.left: lens.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: root.searching ? pagesItem.apps.query + "▏" : L.t("Escribí para buscar en la órbita…")
                font.family: "Exo 2"
                font.pixelSize: 14 * root.fit
                color: root.searching ? root.hp.text : root.hp.muted
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                visible: root.searching
                text: pagesItem.apps.results.length + "  ↵"
                font.family: "JetBrainsMono Nerd Font"
                font.weight: Font.Bold
                font.pixelSize: 11 * root.fit
                color: root.hp.muted
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: {
                    root.host.page = 0
                    root.host.focusPage()
                }
            }
        }

        Item {
            id: panel
            z: 7
            readonly property bool open: root.host.page !== 0
            x: open ? root.cx + root.rx + 40 * root.fit : -4000
            y: root.height - 40 * root.fit - height
            width: 360 * root.fit
            height: 640 * root.fit
            opacity: open ? root.spread : 0

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: root.tint(root.hp.beamDeep, root.host.night ? 0.2 : 0.42)
                border.width: 1.5
                border.color: root.tint(root.hp.beam, 0.85)
            }

            Item {
                id: phead
                x: 16
                width: parent.width - 32
                height: 34
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "◢ ORBIT·LINK  ·  " + root.host.pageNames[root.host.page].toUpperCase()
                    font.family: "Michroma"
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    color: root.hp.text
                }
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0156}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: root.hp.text
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.host.page = 0
                    }
                }
            }

            Pages {
                id: pagesItem
                host: root.host
                pal: root.pal
                x: 6
                anchors.top: phead.bottom
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                width: parent.width - 12
                compact: true
                reveal: root.spread
            }

            Repeater {
                model: Math.floor(panel.height / 3)
                delegate: Rectangle {
                    required property int index
                    y: index * 3
                    width: panel.width
                    height: 1
                    color: root.tint(root.hp.beam, 0.05)
                }
            }
        }
    }
}
