import QtQuick

Rectangle {
    id: r
    property var pal
    property string glyph: ""
    property string title: ""
    property string sub: ""
    default property alias side: holder.data
    width: parent ? parent.width : 400
    height: Math.max(58, texts.implicitHeight + 22)
    radius: 12
    color: r.pal.card1
    border.width: 1
    border.color: r.pal.sep

    Text {
        id: icon
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        text: r.glyph
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 20
        color: r.pal.accent
        visible: r.glyph.length > 0
    }

    Column {
        id: texts
        anchors.left: icon.visible ? icon.right : parent.left
        anchors.leftMargin: icon.visible ? 14 : 16
        anchors.right: holder.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
            width: parent.width
            text: r.title
            elide: Text.ElideRight
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 14
            color: r.pal.ink
        }
        Text {
            width: parent.width
            visible: r.sub.length > 0
            text: r.sub
            wrapMode: Text.WordWrap
            font.family: "Exo 2"
            font.pixelSize: 12
            color: r.pal.muted
        }
    }

    Row {
        id: holder
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}
