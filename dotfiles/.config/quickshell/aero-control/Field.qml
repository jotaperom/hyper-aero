import QtQuick

Rectangle {
    id: f
    property var pal
    property alias text: input.text
    property string hint: ""
    signal accepted()
    implicitWidth: 160
    implicitHeight: 34
    radius: 10
    color: f.pal.field
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? f.pal.select : f.pal.fieldBorder

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        font.family: "Exo 2"
        font.pixelSize: 14
        color: f.pal.ink
        selectByMouse: true
        clip: true
        onAccepted: f.accepted()
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !input.text.length
            text: f.hint
            font: input.font
            color: f.pal.dim
        }
    }
}
