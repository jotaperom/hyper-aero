import QtQuick
import "Lang.js" as L

Card {
    id: w
    property var core
    title: "NOTES"
    tag: edit.activeFocus ? L.t("EDITANDO") : "AUTO-SAVE"

    Connections {
        target: w.core
        function onNotesChanged() {
            if (!edit.activeFocus && edit.text !== w.core.notes) edit.text = w.core.notes
        }
    }

    Repeater {
        model: Math.max(0, Math.floor(w.body.height / 20))
        delegate: Rectangle {
            required property int index
            y: 19 + index * 20
            width: w.body.width
            height: 1
            color: w.pal.sep
            opacity: 0.6
        }
    }

    Flickable {
        id: fl
        anchors.fill: parent
        contentWidth: width
        contentHeight: edit.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        TextEdit {
            id: edit
            width: fl.width
            text: w.core ? w.core.notes : ""
            wrapMode: TextEdit.Wrap
            font.family: "Exo 2"
            font.pixelSize: 13
            color: w.pal.ink
            selectByMouse: true
            selectionColor: w.pal.blue
            onTextChanged: if (activeFocus && w.core) w.core.saveNotes(text)
            onCursorRectangleChanged: {
                if (cursorRectangle.y + cursorRectangle.height > fl.contentY + fl.height)
                    fl.contentY = cursorRectangle.y + cursorRectangle.height - fl.height
                else if (cursorRectangle.y < fl.contentY)
                    fl.contentY = cursorRectangle.y
            }
            Keys.onEscapePressed: focus = false
            Text {
                visible: !edit.text.length && !edit.activeFocus
                text: L.t("Escribí algo aquí…")
                font: edit.font
                color: w.pal.muted
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !edit.activeFocus
        cursorShape: Qt.IBeamCursor
        onClicked: function(m) {
            edit.forceActiveFocus()
            edit.cursorPosition = edit.positionAt(m.x, m.y + fl.contentY)
        }
    }
}
