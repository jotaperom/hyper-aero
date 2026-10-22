import QtQuick

Rectangle {
    id: card
    property var pal
    property var media: ({})
    signal cmd(string c)

    implicitHeight: 76
    radius: 22
    antialiasing: true
    color: pal.shelf
    border.width: 1
    border.color: pal.tileBorder

    Rectangle {
        x: 2; y: 1
        width: parent.width - 4
        height: parent.height * 0.42
        radius: 21
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, card.pal.glossTop) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    Rectangle {
        id: art
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 52; height: 52
        radius: 14
        antialiasing: true
        border.width: 1
        border.color: card.pal.iconBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: card.pal.on0 }
            GradientStop { position: 0.45; color: card.pal.on1 }
            GradientStop { position: 0.55; color: card.pal.on2 }
            GradientStop { position: 1.0; color: card.pal.on3 }
        }
        Text {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: "\u{F075A}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 24
            color: "#ffffff"
        }
        Image {
            id: cover
            anchors.fill: parent
            anchors.margins: 1
            source: card.media.art || ""
            sourceSize.width: 128
            sourceSize.height: 128
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            asynchronous: true
            visible: status === Image.Ready
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 11
        anchors.right: controls.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: card.media.has ? (card.media.title || "Sin título") : "Nada sonando"
            elide: Text.ElideRight
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 13
            color: card.pal.text
        }
        Text {
            width: parent.width
            text: card.media.has ? (card.media.artist || card.media.app || "") : "Spotify, Brave, mpv…"
            elide: Text.ElideRight
            font.family: "Exo 2"
            font.pixelSize: 11
            color: card.pal.muted
        }
    }

    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        opacity: card.media.has ? 1 : 0.4

        Repeater {
            model: [
                { c: "prev", g: "\u{F04AE}" },
                { c: "toggle", g: card.media.playing ? "\u{F03E4}" : "\u{F040A}" },
                { c: "next", g: "\u{F04AD}" }
            ]
            delegate: Rectangle {
                width: modelData.c === "toggle" ? 38 : 30
                height: 38
                radius: 19
                antialiasing: true
                color: modelData.c === "toggle" ? card.pal.accentFill : (btn.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent")
                Text {
                    anchors.centerIn: parent
                    text: modelData.g
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: modelData.c === "toggle" ? 19 : 17
                    color: modelData.c === "toggle" ? "#ffffff" : card.pal.accent
                }
                MouseArea {
                    id: btn
                    anchors.fill: parent
                    enabled: !!card.media.has
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.cmd(modelData.c)
                }
            }
        }
    }
}
