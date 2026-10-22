import QtQuick

Item {
    id: tile
    property var pal
    property string glyph: ""
    property string label: ""
    property string sub: ""
    property bool on: false
    property bool available: true
    property bool more: false
    signal clicked()
    signal moreClicked()

    implicitHeight: 64
    opacity: available ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: 20
        antialiasing: true
        border.width: 1
        border.color: tile.on ? tile.pal.onBorder : tile.pal.tileBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: tile.on ? tile.pal.on0 : tile.pal.tile0 }
            GradientStop { position: 0.48; color: tile.on ? tile.pal.on1 : tile.pal.tile1 }
            GradientStop { position: 0.52; color: tile.on ? tile.pal.on2 : tile.pal.tile2 }
            GradientStop { position: 1.0; color: tile.on ? tile.pal.on3 : tile.pal.tile3 }
        }
        Behavior on border.color { ColorAnimation { duration: 180 } }
    }

    Rectangle {
        x: 1; y: 1
        width: parent.width - 2
        height: parent.height * 0.46
        radius: 19
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, tile.on ? 0.42 : tile.pal.glossTop) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    Rectangle {
        id: badge
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 32; height: 32; radius: 16
        antialiasing: true
        color: tile.on ? Qt.rgba(1, 1, 1, 0.24) : tile.pal.badge
        border.width: 1
        border.color: tile.on ? Qt.rgba(1, 1, 1, 0.55) : tile.pal.tileBorder
        Text {
            anchors.centerIn: parent
            text: tile.glyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: tile.on ? "#ffffff" : tile.pal.accent
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 8
        anchors.right: tile.more ? chevron.left : parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
            width: parent.width
            text: tile.label
            elide: Text.ElideRight
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: tile.on ? "#ffffff" : tile.pal.text
        }
        Text {
            width: parent.width
            text: tile.sub
            elide: Text.ElideRight
            font.family: "Exo 2"
            font.pixelSize: 11
            color: tile.on ? Qt.rgba(1, 1, 1, 0.82) : tile.pal.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: tile.available
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }

    Rectangle {
        id: chevron
        visible: tile.more
        width: 20; height: parent.height - 16
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        radius: 12
        color: chevronArea.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
        Text {
            anchors.centerIn: parent
            text: "\u{F0142}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: tile.on ? "#ffffff" : tile.pal.muted
        }
        MouseArea {
            id: chevronArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.moreClicked()
        }
    }
}
