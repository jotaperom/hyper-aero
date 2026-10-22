import QtQuick
import Quickshell.Widgets
import "Lang.js" as L

Item {
    id: w
    property var core
    property var pal
    readonly property var g: core ? core.gif : null
    readonly property string file: g && g.file ? g.file : ""
    readonly property bool contain: !!(g && g.fit === "contain")
    readonly property bool paused: !!(g && g.paused)
    readonly property bool ready: anim.status === AnimatedImage.Ready
    readonly property bool hot: hover.hovered || drop.containsDrag

    HoverHandler { id: hover }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.leftMargin: 2
        anchors.rightMargin: -2
        anchors.bottomMargin: -5
        radius: 22
        color: w.pal.shadow
    }

    ClippingRectangle {
        id: frame
        anchors.fill: parent
        radius: 20
        color: "transparent"
        border.width: 0

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: w.pal.card0 }
                GradientStop { position: 0.46; color: w.pal.card1 }
                GradientStop { position: 0.54; color: w.pal.card2 }
                GradientStop { position: 1.0; color: w.pal.card3 }
            }
        }

        AnimatedImage {
            id: anim
            anchors.fill: parent
            source: w.file ? "file://" + w.file : ""
            fillMode: w.contain ? Image.PreserveAspectFit : Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            smooth: true
            playing: !w.paused && !!w.core && !w.core.hidden && !w.core.editing && w.visible
            opacity: w.ready ? 1 : 0
            scale: w.ready ? 1 : 1.04
            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            width: parent.width
            height: parent.height * 0.34
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, w.core && w.core.night ? 0.1 : 0.22) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 58
            opacity: w.hot && w.file ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0) }
                GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.05, 0.12, 0.45) }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "transparent"
        border.width: drop.containsDrag ? 2 : 1
        border.color: drop.containsDrag ? w.pal.glow : w.pal.cardBorder
        Behavior on border.color { ColorAnimation { duration: 200 } }
    }
    Rectangle {
        x: 16; y: 1
        width: parent.width - 32
        height: 1
        color: w.pal.sheen
    }

    Column {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 6
        visible: !w.file || anim.status === AnimatedImage.Error
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{F0D78}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: Math.min(40, w.height * 0.22)
            color: w.pal.accent
            scale: drop.containsDrag ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: anim.status === AnimatedImage.Error ? L.t("No pude abrir ese archivo") : (drop.containsDrag ? L.t("Soltalo aquí") : L.t("Tocá para elegir un GIF"))
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 13
            color: w.pal.ink
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: w.height > 140
            text: L.t("o arrastralo desde Archivos")
            font.family: "Exo 2"
            font.pixelSize: 11
            color: w.pal.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !w.file || anim.status === AnimatedImage.Error
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: w.core.gifPick()
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        spacing: 6
        visible: opacity > 0.01
        opacity: w.hot && w.file ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        transform: Translate {
            y: w.hot && w.file ? 0 : 8
            Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        }

        OrbButton {
            pal: w.pal
            gloss: w.core && w.core.night ? 0.45 : 1
            size: 30
            glyph: w.paused ? "\u{F040A}" : "\u{F03E4}"
            onClicked: w.core.gifUpdate({ paused: !w.paused })
        }
        OrbButton {
            pal: w.pal
            gloss: w.core && w.core.night ? 0.45 : 1
            size: 30
            glyph: w.contain ? "\u{F019E}" : "\u{F0A24}"
            onClicked: w.core.gifUpdate({ fit: w.contain ? "cover" : "contain" })
        }
        OrbButton {
            pal: w.pal
            gloss: w.core && w.core.night ? 0.45 : 1
            size: 30
            glyph: "\u{F024B}"
            onClicked: w.core.gifPick()
        }
    }

    DropArea {
        id: drop
        anchors.fill: parent
        onDropped: function(d) {
            if (d.hasUrls && d.urls.length) {
                w.core.gifSet(String(d.urls[0]))
                d.acceptProposedAction()
            }
        }
    }
}
