import QtQuick

Item {
    id: menu
    property var pal
    property var items: []
    property size bounds: Qt.size(1920, 1080)
    property bool open: false
    signal picked(string key)
    width: 236
    height: col.implicitHeight + 16
    visible: opacity > 0.01
    opacity: open ? 1 : 0
    scale: open ? 1 : 0.92
    transformOrigin: Item.TopLeft
    Behavior on opacity { NumberAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

    function openAt(px, py) {
        x = Math.min(px, bounds.width - width - 8)
        y = Math.min(py, bounds.height - height - 8)
        open = true
    }

    function close() {
        open = false
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -6
        radius: 18
        color: menu.pal.shadow
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        antialiasing: true
        border.width: 1
        border.color: menu.pal.cardBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: menu.pal.tray0 }
            GradientStop { position: 0.46; color: menu.pal.tray1 }
            GradientStop { position: 0.54; color: menu.pal.tray2 }
            GradientStop { position: 1.0; color: menu.pal.tray3 }
        }
        Rectangle { x: 14; y: 1; width: parent.width - 28; height: 1; color: menu.pal.sheen }
    }

    Column {
        id: col
        x: 8
        y: 8
        width: parent.width - 16
        spacing: 2

        Text {
            x: 8
            height: 20
            verticalAlignment: Text.AlignVCenter
            text: "◢ DESKTOP"
            font.family: "Michroma"
            font.pixelSize: 8
            font.letterSpacing: 1
            color: menu.pal.muted
        }

        Repeater {
            model: menu.items
            delegate: Rectangle {
                required property var modelData
                width: col.width
                height: 34
                radius: 10
                color: area.containsMouse ? menu.pal.hover : "transparent"
                border.width: area.containsMouse ? 1 : 0
                border.color: menu.pal.sep

                Text {
                    id: ic
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.glyph
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    color: menu.pal.accent
                }
                Text {
                    anchors.left: ic.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.text
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    color: menu.pal.ink
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.hint
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: 8
                    color: menu.pal.dim
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        menu.close()
                        menu.picked(modelData.key)
                    }
                }
            }
        }
    }
}
