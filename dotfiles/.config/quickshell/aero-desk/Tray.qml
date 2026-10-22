import QtQuick
import "Registry.js" as Reg
import "Lang.js" as L

Item {
    id: tray
    property var ed
    readonly property var pal: ed.pal
    height: 152

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 6
        anchors.bottomMargin: -8
        radius: 26
        color: tray.pal.shadow
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: 24
        antialiasing: true
        border.width: 1
        border.color: tray.pal.trayBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: tray.pal.tray0 }
            GradientStop { position: 0.46; color: tray.pal.tray1 }
            GradientStop { position: 0.54; color: tray.pal.tray2 }
            GradientStop { position: 1.0; color: tray.pal.tray3 }
        }
        Rectangle { x: 20; y: 1; width: parent.width - 40; height: 1; color: tray.pal.sheen }
        MouseArea { anchors.fill: parent }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -16
        width: 92
        height: 22
        radius: 11
        border.width: 1
        border.color: tray.pal.trayBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: tray.pal.tray0 }
            GradientStop { position: 1.0; color: tray.pal.tray2 }
        }
        Text {
            anchors.centerIn: parent
            text: tray.ed.trayOpen ? "\u{F0140}  " + L.t("OCULTAR") : "\u{F0143}  " + L.t("BANDEJA")
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 9
            color: tray.pal.accent
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: tray.ed.trayOpen = !tray.ed.trayOpen
        }
    }

    Column {
        id: info
        x: 22
        y: 16
        width: 210
        spacing: 5

        Text {
            text: L.t("◢ EDITAR ESCRITORIO")
            font.family: "Michroma"
            font.pixelSize: 10
            font.letterSpacing: 1
            color: tray.pal.ink
        }
        Text {
            text: tray.ed.cols + " × " + tray.ed.rows + L.t(" CELDAS  ·  ") + tray.ed.cell + " PX"
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 8
            color: tray.pal.muted
        }
        Repeater {
            model: [
                [L.t("ARRASTRAR"), L.t("mover o agregar")],
                [L.t("ESQUINA") + " \u{F045D}", L.t("cambiar tamaño")],
                [L.t("CLIC DER."), L.t("quitar widget")],
                ["ESC", L.t("cancelar")]
            ]
            delegate: Row {
                required property var modelData
                spacing: 7
                Rectangle {
                    width: 82
                    height: 16
                    radius: 8
                    color: tray.pal.hover
                    border.width: 1
                    border.color: tray.pal.sep
                    Text {
                        anchors.centerIn: parent
                        text: modelData[0]
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 8
                        color: tray.pal.accent
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData[1]
                    font.family: "Exo 2"
                    font.weight: Font.DemiBold
                    font.pixelSize: 11
                    color: tray.pal.muted
                }
            }
        }
    }

    function scrollBy(d) {
        var max = Math.max(0, list.contentWidth - list.width)
        slide.stop()
        slide.from = list.contentX
        slide.to = Math.max(0, Math.min(max, list.contentX + d))
        slide.start()
    }

    NumberAnimation {
        id: slide
        target: list
        property: "contentX"
        duration: 260
        easing.type: Easing.OutCubic
    }

    ListView {
        id: list
        readonly property bool scrollable: contentWidth > width + 1
        readonly property bool atStart: contentX <= 1
        readonly property bool atEnd: contentX >= contentWidth - width - 1
        anchors.left: info.right
        anchors.leftMargin: 44
        anchors.right: actions.left
        anchors.rightMargin: 46
        y: 16
        height: 112
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Reg.LIST
        interactive: scrollable

        delegate: Item {
            id: cardItem
            required property var modelData
            readonly property bool on: {
                tray.ed.rev
                return tray.ed.indexOf(modelData.id) >= 0
            }
            width: 100
            height: 112

            Rectangle {
                id: face
                anchors.fill: parent
                anchors.topMargin: 6
                radius: 16
                antialiasing: true
                border.width: cardItem.on ? 2 : 1
                border.color: cardItem.on ? tray.pal.select : tray.pal.cardBorder
                scale: area.pressed ? 0.95 : (area.containsMouse ? 1.04 : 1)
                Behavior on scale { NumberAnimation { duration: 120 } }
                gradient: Gradient {
                    GradientStop { position: 0.0; color: tray.pal.card0 }
                    GradientStop { position: 0.46; color: tray.pal.card1 }
                    GradientStop { position: 0.54; color: tray.pal.card2 }
                    GradientStop { position: 1.0; color: tray.pal.card3 }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 12
                    width: 44
                    height: 44
                    radius: 14
                    antialiasing: true
                    border.width: 1
                    border.color: "#b3ffffff"
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: cardItem.on ? tray.pal.fill0 : tray.pal.btn0 }
                        GradientStop { position: 0.5; color: cardItem.on ? tray.pal.fill1 : tray.pal.btn1 }
                        GradientStop { position: 0.52; color: cardItem.on ? tray.pal.fill2 : tray.pal.btn2 }
                        GradientStop { position: 1.0; color: cardItem.on ? tray.pal.fill1 : tray.pal.btn3 }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cardItem.modelData.glyph
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        color: cardItem.on ? "#ffffff" : tray.pal.btnText
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 64
                    text: cardItem.modelData.name
                    font.family: "Michroma"
                    font.pixelSize: 8
                    color: tray.pal.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 80
                    text: cardItem.modelData.desc
                    font.family: "Exo 2"
                    font.pixelSize: 10
                    color: tray.pal.muted
                }
            }

            Rectangle {
                visible: cardItem.on
                x: parent.width - 18
                y: 0
                width: 20
                height: 20
                radius: 10
                color: tray.pal.select
                border.width: 1
                border.color: "#ffffff"
                Text {
                    anchors.centerIn: parent
                    text: "\u{F012C}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: "#ffffff"
                }
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                property bool moved: false
                property point start
                onPressed: function(m) {
                    moved = false
                    start = mapToItem(tray.ed, m.x, m.y)
                }
                onPositionChanged: function(m) {
                    if (!pressed) return
                    var p = mapToItem(tray.ed, m.x, m.y)
                    if (!moved && !cardItem.on && Math.abs(p.x - start.x) + Math.abs(p.y - start.y) > 10) {
                        moved = true
                        tray.ed.startCarry(cardItem.modelData.id, p)
                    }
                    if (moved) tray.ed.moveCarry(p)
                }
                onReleased: {
                    if (moved) {
                        tray.ed.endCarry()
                    } else if (cardItem.on) {
                        tray.ed.removeAt(tray.ed.indexOf(cardItem.modelData.id))
                    } else {
                        tray.ed.addWidget(cardItem.modelData.id)
                    }
                    moved = false
                }
            }
        }
    }

    MouseArea {
        anchors.fill: list
        acceptedButtons: Qt.NoButton
        onWheel: function(e) {
            var d = Math.abs(e.angleDelta.y) >= Math.abs(e.angleDelta.x) ? e.angleDelta.y : e.angleDelta.x
            if (d === 0) d = -e.pixelDelta.y
            tray.scrollBy(-d * 1.2)
            e.accepted = true
        }
    }

    Rectangle {
        anchors.left: list.left
        y: list.y + 6
        width: 26
        height: list.height - 6
        visible: list.scrollable && !list.atStart
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: tray.pal.tray1 }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.right: list.right
        y: list.y + 6
        width: 26
        height: list.height - 6
        visible: list.scrollable && !list.atEnd
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: tray.pal.tray1 }
        }
    }

    Repeater {
        model: [-1, 1]
        delegate: Rectangle {
            required property int modelData
            readonly property bool off: modelData < 0 ? list.atStart : list.atEnd
            x: modelData < 0 ? list.x - 38 : list.x + list.width + 8
            y: list.y + 6 + (list.height - 6 - height) / 2
            width: 30
            height: 30
            radius: 15
            visible: list.scrollable
            opacity: off ? 0.35 : 1
            antialiasing: true
            border.width: 1
            border.color: tray.pal.btnBorder
            scale: arrow.pressed ? 0.9 : (arrow.containsMouse && !off ? 1.08 : 1)
            Behavior on scale { NumberAnimation { duration: 110 } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: tray.pal.btn0 }
                GradientStop { position: 0.48; color: tray.pal.btn1 }
                GradientStop { position: 0.52; color: tray.pal.btn2 }
                GradientStop { position: 1.0; color: tray.pal.btn3 }
            }
            Text {
                anchors.centerIn: parent
                text: modelData < 0 ? "\u{F0141}" : "\u{F0142}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: tray.pal.btnText
            }
            MouseArea {
                id: arrow
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tray.scrollBy(modelData * list.width * 0.8)
            }
        }
    }

    Row {
        anchors.horizontalCenter: list.horizontalCenter
        y: list.y + list.height + 2
        spacing: 5
        visible: list.scrollable
        Repeater {
            model: Math.max(1, Math.ceil(list.contentWidth / Math.max(1, list.width)))
            delegate: Rectangle {
                required property int index
                readonly property real pos: list.contentWidth > list.width ? list.contentX / (list.contentWidth - list.width) : 0
                readonly property int cur: Math.round(pos * (Math.ceil(list.contentWidth / Math.max(1, list.width)) - 1))
                width: cur === index ? 14 : 5
                height: 5
                radius: 2.5
                color: cur === index ? tray.pal.select : tray.pal.sep
                Behavior on width { NumberAnimation { duration: 160 } }
            }
        }
    }

    Column {
        id: actions
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        TrayButton {
            pal: tray.pal
            glyph: "\u{F012C}"
            text: L.t("LISTO")
            primary: true
            onClicked: tray.ed.done()
        }
        TrayButton {
            pal: tray.pal
            glyph: "\u{F099B}"
            text: "ORIGINAL"
            onClicked: tray.ed.reset()
        }
        TrayButton {
            pal: tray.pal
            glyph: "\u{F0156}"
            text: L.t("CANCELAR")
            onClicked: tray.ed.cancel()
        }
    }
}
