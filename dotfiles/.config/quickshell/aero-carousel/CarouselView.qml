import QtQuick
import QtQuick.Effects
import "Pal.js" as Pal

Item {
    id: v
    property var api
    property bool open: false
    signal closed()
    readonly property var themes: api ? api.themes : []
    readonly property bool night: !!api && api.mode === "night"
    readonly property var cur: themes.length ? themes[Math.max(0, Math.min(themes.length - 1, pv.currentIndex))] : null
    readonly property var pal: Pal.make(night, cur ? cur.accent : "blue")
    readonly property real cardW: Math.min(width * 0.44, 780)
    readonly property real cardH: cardW * 9 / 16 + 78
    property bool leaving: false
    focus: true

    function file(p) {
        return p && p.length ? (p.indexOf("file://") === 0 ? p : "file://" + p) : ""
    }

    function startAt() {
        for (var i = 0; i < themes.length; i++) {
            if (themes[i].current) return i
        }
        return 0
    }

    function go(step) {
        if (!themes.length || leaving) return
        if (step > 0) pv.incrementCurrentIndex()
        else pv.decrementCurrentIndex()
    }

    function choose() {
        if (!cur || leaving) return
        if (cur.current) {
            dismiss()
            return
        }
        leaving = true
        if (api) api.apply(cur)
    }

    function dismiss() {
        open = false
        bye.restart()
    }

    Timer {
        id: bye
        interval: 220
        onTriggered: v.closed()
    }

    onThemesChanged: if (themes.length) pv.positionViewAtIndex(startAt(), PathView.Center)

    Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Escape) v.dismiss()
        else if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_L) v.go(1)
        else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_H) v.go(-1)
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) v.choose()
        else if (e.key === Qt.Key_Home) pv.currentIndex = 0
        else if (e.key === Qt.Key_End) pv.currentIndex = v.themes.length - 1
        else return
        e.accepted = true
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: v.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Item {
            id: bg
            anchors.fill: parent
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                color: v.night ? "#050a14" : "#0b1a33"
            }

            Repeater {
                model: v.themes
                delegate: Image {
                    required property var modelData
                    required property int index
                    anchors.fill: parent
                    source: v.file(v.night ? modelData.night : modelData.day)
                    sourceSize.width: 960
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: index === pv.currentIndex ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                }
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: bg
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            brightness: -0.12
            saturation: 0.15
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#c0050a14" }
                GradientStop { position: 0.3; color: "#40050a14" }
                GradientStop { position: 0.7; color: "#40050a14" }
                GradientStop { position: 1.0; color: "#d0050a14" }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: v.dismiss()
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(30, parent.height * 0.08)
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "◢ TEMAS"
                font.family: "Michroma"
                font.pixelSize: 28
                font.letterSpacing: 8
                color: "#ffffff"
                style: Text.Raised
                styleColor: "#990b0d12"
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 220
                height: 3
                radius: 1.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#00ffffff" }
                    GradientStop { position: 0.5; color: v.cur ? v.cur.hex : "#3d9be9" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Deslizá, usá ← → o la rueda del mouse  ·  Enter aplica  ·  Esc cierra"
                font.family: "Exo 2"
                font.pixelSize: 14
                color: Qt.rgba(1, 1, 1, 0.8)
            }
        }

        PathView {
            id: pv
            anchors.fill: parent
            model: v.themes
            pathItemCount: Math.min(7, Math.max(3, v.themes.length + (v.themes.length % 2 === 0 ? 1 : 0)))
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            snapMode: PathView.SnapOneItem
            highlightMoveDuration: 420
            flickDeceleration: 900
            maximumFlickVelocity: 2600
            dragMargin: v.cardH / 2
            interactive: !v.leaving
            readonly property real cy: v.height * 0.5

            path: Path {
                startX: -v.cardW * 0.35
                startY: pv.cy
                PathAttribute { name: "itemScale"; value: 0.58 }
                PathAttribute { name: "itemFade"; value: 0.25 }
                PathAttribute { name: "itemZ"; value: 0 }
                PathAttribute { name: "itemAngle"; value: 42 }
                PathLine { x: v.width / 2; y: pv.cy }
                PathAttribute { name: "itemScale"; value: 1.0 }
                PathAttribute { name: "itemFade"; value: 1.0 }
                PathAttribute { name: "itemZ"; value: 10 }
                PathAttribute { name: "itemAngle"; value: 0 }
                PathLine { x: v.width + v.cardW * 0.35; y: pv.cy }
                PathAttribute { name: "itemScale"; value: 0.58 }
                PathAttribute { name: "itemFade"; value: 0.25 }
                PathAttribute { name: "itemZ"; value: 0 }
                PathAttribute { name: "itemAngle"; value: -42 }
            }

            delegate: Item {
                id: card
                required property var modelData
                required property int index
                readonly property bool centered: PathView.isCurrentItem
                width: v.cardW
                height: v.cardH
                scale: PathView.itemScale
                opacity: PathView.itemFade
                z: PathView.itemZ
                transform: Rotation {
                    origin.x: card.width / 2
                    origin.y: card.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: card.PathView.itemAngle
                }

                Rectangle {
                    anchors.fill: frame
                    anchors.margins: -12
                    radius: 34
                    color: "transparent"
                    border.width: 3
                    border.color: card.modelData.hex
                    opacity: card.centered ? 0.75 : 0
                    Behavior on opacity { NumberAnimation { duration: 260 } }
                }

                Rectangle {
                    anchors.fill: frame
                    anchors.topMargin: 18
                    anchors.leftMargin: 10
                    anchors.rightMargin: -10
                    anchors.bottomMargin: -22
                    radius: 26
                    color: "#66000000"
                }

                Rectangle {
                    id: frame
                    anchors.fill: parent
                    radius: 24
                    clip: true
                    color: "#000000"
                    border.width: 2
                    border.color: card.centered ? "#e6ffffff" : "#66ffffff"

                    Image {
                        x: 2
                        y: 2
                        width: parent.width - 4
                        height: parent.height - 4 - 74
                        source: v.file(v.night ? card.modelData.night : card.modelData.day)
                        sourceSize.width: 900
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Rectangle {
                        x: 2
                        y: 2
                        width: parent.width - 4
                        height: (parent.height - 78) * 0.42
                        radius: 22
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#40ffffff" }
                            GradientStop { position: 1.0; color: "#00ffffff" }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 76
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(0.04, 0.07, 0.14, 0.92) }
                            GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.04, 0.09, 0.98) }
                        }
                        Rectangle {
                            width: parent.width
                            height: 2
                            color: card.modelData.hex
                            opacity: 0.85
                        }

                        Rectangle {
                            id: orb
                            x: 20
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 40
                            radius: 20
                            border.width: 2
                            border.color: "#ffffff"
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.lighter(card.modelData.hex, 1.5) }
                                GradientStop { position: 0.5; color: card.modelData.hex }
                                GradientStop { position: 1.0; color: Qt.darker(card.modelData.hex, 1.6) }
                            }
                            Rectangle {
                                x: 7; y: 3
                                width: 26; height: 14
                                radius: 7
                                color: "#a6ffffff"
                            }
                        }

                        Column {
                            anchors.left: orb.right
                            anchors.leftMargin: 14
                            anchors.right: badge.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: card.modelData.name.toUpperCase()
                                font.family: "Michroma"
                                font.pixelSize: 17
                                font.letterSpacing: 2
                                color: "#ffffff"
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: "Fondo: " + card.modelData.wallName
                                font.family: "Exo 2"
                                font.pixelSize: 13
                                color: Qt.rgba(1, 1, 1, 0.72)
                            }
                        }

                        Rectangle {
                            id: badge
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: badgeText.implicitWidth + 24
                            height: 28
                            radius: 14
                            visible: card.modelData.current || card.centered
                            color: card.modelData.current ? "#2e3ddc97" : Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1
                            border.color: card.modelData.current ? "#3ddc97" : Qt.rgba(1, 1, 1, 0.5)
                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: card.modelData.current ? "●  ACTUAL" : "ENTER ⏎"
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 11
                                color: card.modelData.current ? "#3ddc97" : "#ffffff"
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (card.centered) v.choose()
                        else pv.currentIndex = card.index
                    }
                }
            }

            WheelHandler {
                property real acc: 0
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: function(e) {
                    acc += (Math.abs(e.angleDelta.x) > Math.abs(e.angleDelta.y) ? e.angleDelta.x : e.angleDelta.y)
                    if (acc <= -100) { acc = 0; v.go(1) }
                    else if (acc >= 100) { acc = 0; v.go(-1) }
                }
            }
        }

        Row {
            id: dots
            anchors.horizontalCenter: parent.horizontalCenter
            y: pv.cy + v.cardH / 2 + 40
            spacing: 8
            Repeater {
                model: v.themes
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    anchors.verticalCenter: parent.verticalCenter
                    width: index === pv.currentIndex ? 30 : 10
                    height: 10
                    radius: 5
                    color: modelData.hex
                    border.width: 1
                    border.color: "#ccffffff"
                    opacity: index === pv.currentIndex ? 1 : 0.6
                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -5
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pv.currentIndex = parent.index
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dots.bottom
            anchors.topMargin: 26
            spacing: 12
            Pill {
                pal: v.pal
                primary: true
                glyph: "\u{F012C}"
                text: v.cur && v.cur.current ? "Ya está aplicado" : "Aplicar " + (v.cur ? v.cur.name : "")
                enabled2: !!v.cur && !v.cur.current && !v.leaving
                onClicked: v.choose()
            }
            Pill {
                pal: v.pal
                glyph: "\u{F03D8}"
                text: "Estudio de temas"
                enabled2: !v.leaving
                onClicked: if (v.api) v.api.studio()
            }
            Pill {
                pal: v.pal
                glyph: "\u{F0156}"
                text: "Cerrar"
                onClicked: v.dismiss()
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !v.themes.length
            text: "Cargando temas…"
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 18
            color: "#ffffff"
        }
    }
}
