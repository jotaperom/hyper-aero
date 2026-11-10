import QtQuick

Item {
    id: row
    property var pal
    property var node
    property string glyph: ""
    property string badge: ""
    property string icon: ""
    property string label: ""
    property string hint: ""
    property bool selectable: false
    property bool selected: false
    signal pick()
    signal moved(real v)
    signal glyphClicked()

    implicitHeight: 42
    height: implicitHeight

    Rectangle {
        id: knob
        width: 34
        height: 34
        anchors.verticalCenter: parent.verticalCenter
        radius: 17
        antialiasing: true
        color: row.selected ? row.pal.accentFill : (knobArea.containsMouse && row.selectable ? row.pal.badge : row.pal.track)
        border.width: row.selected ? 2 : 1
        border.color: row.selected ? row.pal.glow : row.pal.tileBorder
        Behavior on color { ColorAnimation { duration: 160 } }

        Image {
            id: img
            anchors.centerIn: parent
            width: 22
            height: 22
            sourceSize.width: 64
            sourceSize.height: 64
            source: row.icon
            smooth: true
            mipmap: true
            asynchronous: true
            visible: row.icon.length > 0 && status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: !img.visible
            text: row.badge
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: row.selected ? "#ffffff" : row.pal.text
        }

        Rectangle {
            visible: row.selected
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -3
            width: 15
            height: 15
            radius: 7.5
            color: row.pal.glow
            border.width: 1
            border.color: "#ffffff"
            Text {
                anchors.centerIn: parent
                text: "\u{F012C}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: "#ffffff"
            }
        }

        MouseArea {
            id: knobArea
            anchors.fill: parent
            anchors.margins: -3
            enabled: row.selectable
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.pick()
        }
    }

    GlassSlider {
        anchors.left: knob.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 38
        pal: row.pal
        glyph: row.glyph
        label: row.label
        hint: row.hint
        dim: !!(row.node && row.node.audio && row.node.audio.muted)
        value: row.node && row.node.audio ? row.node.audio.volume : 0
        onMoved: function(v) { row.moved(v) }
        onGlyphClicked: row.glyphClicked()
    }
}
