import QtQuick
import QtQuick.Shapes

Item {
    id: card
    property var pal
    property string title: ""
    property string tag: ""
    property bool head: title.length > 0
    property real pad: 14
    property bool glass: true
    default property alias content: body.data
    readonly property alias body: body

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.leftMargin: 2
        anchors.rightMargin: -2
        anchors.bottomMargin: -5
        radius: 22
        color: card.pal.shadow
        visible: card.glass
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        antialiasing: true
        visible: card.glass
        border.width: 1
        border.color: card.pal.cardBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: card.pal.card0 }
            GradientStop { position: 0.46; color: card.pal.card1 }
            GradientStop { position: 0.54; color: card.pal.card2 }
            GradientStop { position: 1.0; color: card.pal.card3 }
        }
        Rectangle {
            x: 16; y: 1
            width: parent.width - 32
            height: 1
            color: card.pal.sheen
        }
    }

    Item {
        id: header
        visible: card.head
        x: card.pad
        y: 11
        width: card.width - card.pad * 2
        height: card.head ? 20 : 0

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            text: card.title
            font.family: "Michroma"
            font.pixelSize: 9
            color: card.pal.ink
        }
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 1
            width: Math.min(implicitWidth, parent.width * 0.62)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            text: card.tag
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 9
            color: card.pal.muted
        }
        DashLine {
            anchors.bottom: parent.bottom
            width: parent.width
            color: card.pal.sep
        }
    }

    Item {
        id: body
        x: card.pad
        y: card.head ? header.y + header.height + 6 : card.pad
        width: card.width - card.pad * 2
        height: card.height - y - (card.head ? 12 : card.pad)
    }
}
