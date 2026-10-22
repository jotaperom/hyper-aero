import QtQuick

Card {
    id: w
    property var core
    readonly property var list: core ? core.tasks : []
    readonly property int pending: {
        var n = 0
        for (var i = 0; i < list.length; i++) if (!list[i].done) n++
        return n
    }
    readonly property bool anyDone: pending < list.length
    title: "TASKS"
    tag: pending + (pending === 1 ? " PENDIENTE" : " PENDIENTES")

    ListView {
        id: lv
        width: parent.width
        height: parent.height - entry.height - 8
        clip: true
        spacing: 2
        model: w.list
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            required property var modelData
            width: lv.width
            height: Math.max(26, txt.implicitHeight + 10)
            radius: 10
            color: rowArea.containsMouse ? w.pal.hover : "transparent"

            Text {
                id: box
                x: 6
                y: 5
                text: modelData.done ? "\u{F0135}" : "\u{F0131}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: modelData.done ? w.pal.ok : w.pal.accent
            }
            Text {
                id: txt
                anchors.left: box.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 6
                y: 5
                text: modelData.text
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: "Exo 2"
                font.pixelSize: 12
                font.strikeout: modelData.done
                color: modelData.done ? w.pal.dim : w.pal.ink
            }
            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: w.core.taskToggle(modelData.line)
            }
        }

        Text {
            visible: lv.count === 0
            anchors.centerIn: parent
            text: "Sin tareas · escribí una abajo"
            font.family: "Exo 2"
            font.pixelSize: 11
            color: w.pal.muted
        }
    }

    Item {
        id: entry
        anchors.bottom: parent.bottom
        width: parent.width
        height: 30

        Rectangle {
            anchors.left: parent.left
            anchors.right: clearBtn.visible ? clearBtn.left : parent.right
            anchors.rightMargin: clearBtn.visible ? 6 : 0
            height: parent.height
            radius: 15
            color: w.pal.field
            border.width: input.activeFocus ? 2 : 1
            border.color: input.activeFocus ? w.pal.glow : w.pal.fieldBorder

            Text {
                id: plus
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F0415}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: w.pal.accent
            }
            TextInput {
                id: input
                anchors.left: plus.right
                anchors.leftMargin: 6
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                font.family: "Exo 2"
                font.pixelSize: 12
                color: w.pal.ink
                selectByMouse: true
                onAccepted: {
                    w.core.taskAdd(text)
                    text = ""
                }
                Keys.onEscapePressed: {
                    text = ""
                    focus = false
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !input.text.length
                    text: "Nueva tarea…"
                    font: input.font
                    color: w.pal.muted
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: input.forceActiveFocus()
                z: -1
            }
        }

        Rectangle {
            id: clearBtn
            visible: w.anyDone
            anchors.right: parent.right
            width: 30
            height: 30
            radius: 15
            color: clearArea.containsMouse ? w.pal.hover : w.pal.field
            border.width: 1
            border.color: w.pal.fieldBorder
            Text {
                anchors.centerIn: parent
                text: "\u{F00E2}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: w.pal.accent
            }
            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: w.core.taskClear()
            }
        }
    }
}
