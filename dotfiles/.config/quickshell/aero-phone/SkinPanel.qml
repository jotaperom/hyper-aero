import QtQuick

Item {
    id: sp
    property var pal
    property var backend
    readonly property string current: backend && backend.skin ? backend.skin : "iphone"
    readonly property var list: [
        { id: "iphone", name: "NEXUS One", desc: "Pantalla completa" },
        { id: "flip", name: "Keitai", desc: "Flip con teclado" },
        { id: "slider", name: "Slider", desc: "Teclado deslizable" },
        { id: "holo", name: "Holo", desc: "Comunicador holográfico" },
        { id: "pda", name: "Cristal", desc: "PDA transparente" },
        { id: "orbit", name: "Órbita", desc: "Planeta con apps" },
        { id: "aqua", name: "Acuario", desc: "Pecera de cristal" },
        { id: "visor", name: "Visor", desc: "HUD táctico" }
    ]
    signal back()

    Item {
        id: head
        x: 14
        y: 6
        width: parent.width - 28
        height: 44

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 34; height: 34; radius: 17
            antialiasing: true
            color: backArea.containsMouse ? sp.pal.badge : "transparent"
            border.width: 1
            border.color: sp.pal.tileBorder
            Text {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -1
                text: "\u{F0141}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: sp.pal.hero
            }
            MouseArea {
                id: backArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sp.back()
            }
        }
        Text {
            x: 46
            anchors.verticalCenter: parent.verticalCenter
            text: "PIELES"
            font.family: "Michroma"
            font.pixelSize: 18
            font.letterSpacing: 2
            color: sp.pal.hero
            style: Text.Raised
            styleColor: sp.pal.heroShadow
        }
    }

    Flickable {
        anchors.top: head.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        x: 14
        width: parent.width - 28
        contentHeight: grid.height + 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Grid {
            id: grid
            width: parent.width
            columns: width > 440 ? 4 : 2
            spacing: 10
            readonly property real cell: (width - spacing * (columns - 1)) / columns

            Repeater {
                model: sp.list
                delegate: Item {
                    id: card
                    required property var modelData
                    readonly property bool on: sp.current === modelData.id
                    width: grid.cell
                    height: 124

                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        antialiasing: true
                        border.width: card.on ? 2 : 1
                        border.color: card.on ? sp.pal.onBorder : sp.pal.tileBorder
                        scale: area.pressed ? 0.96 : (area.containsMouse ? 1.02 : 1)
                        Behavior on scale { NumberAnimation { duration: 120 } }
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: card.on ? sp.pal.on0 : sp.pal.tile0 }
                            GradientStop { position: 0.48; color: card.on ? sp.pal.on1 : sp.pal.tile1 }
                            GradientStop { position: 0.52; color: card.on ? sp.pal.on2 : sp.pal.tile2 }
                            GradientStop { position: 1.0; color: card.on ? sp.pal.on3 : sp.pal.tile3 }
                        }
                        Rectangle {
                            x: 1; y: 1
                            width: parent.width - 2
                            height: parent.height * 0.42
                            radius: 19
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, card.on ? 0.4 : sp.pal.glossTop * 0.8) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                            }
                        }
                    }

                    SkinGlyph {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 10
                        kind: card.modelData.id
                        ink: card.on ? "#ffffff" : sp.pal.accent
                        fill: card.on ? Qt.rgba(1, 1, 1, 0.25) : sp.pal.badge
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 80
                        text: card.modelData.name
                        font.family: "Exo 2"
                        font.weight: Font.Bold
                        font.pixelSize: 12
                        color: card.on ? "#ffffff" : sp.pal.text
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 97
                        width: parent.width - 10
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: card.modelData.desc
                        font.family: "Exo 2"
                        font.pixelSize: 10
                        color: card.on ? Qt.rgba(1, 1, 1, 0.85) : sp.pal.muted
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (sp.backend && !card.on) sp.backend.setSkin(card.modelData.id)
                    }
                }
            }
        }
    }
}
