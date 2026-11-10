import QtQuick
import "Lang.js" as L

Item {
    id: cp
    property var pal
    property var backend
    property bool live: false
    property string query: ""
    readonly property var items: backend ? backend.clips : []
    readonly property var shown: items.filter(function(c) { return !cp.query.length || c.text.toLowerCase().indexOf(cp.query.toLowerCase()) >= 0 })
    signal back()
    signal done()

    onLiveChanged: if (live && backend) {
        query = ""
        search.text = ""
        backend.clipRefresh()
    }

    PanelHeader {
        id: header
        x: 14
        y: 4
        width: parent.width - 28
        pal: cp.pal
        title: L.t("Portapapeles")
        on: true
        switchEnabled: false
        showSwitch: false
        spinning: false
        onBack: cp.back()
        onRefresh: if (cp.backend) cp.backend.clipRefresh()
    }

    Rectangle {
        id: field
        anchors.top: header.bottom
        anchors.topMargin: 6
        x: 14
        width: parent.width - 28
        height: 36
        radius: 18
        color: cp.pal.field
        border.width: search.activeFocus ? 2 : 1
        border.color: search.activeFocus ? cp.pal.glow : cp.pal.tileBorder
        Text {
            id: lens
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0349}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: cp.pal.accent
        }
        TextInput {
            id: search
            anchors.left: lens.right
            anchors.leftMargin: 8
            anchors.right: wipe.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Exo 2"
            font.pixelSize: 14
            color: cp.pal.text
            clip: true
            onTextChanged: cp.query = text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !search.text.length
                text: L.t("Buscar en el historial")
                font: search.font
                color: cp.pal.muted
            }
        }
        Text {
            id: wipe
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: L.t("Borrar todo")
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 11
            color: cp.pal.muted
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: if (cp.backend) cp.backend.clipWipe()
            }
        }
    }

    ListView {
        id: list
        anchors.top: field.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        x: 14
        width: parent.width - 28
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        model: cp.shown
        delegate: Rectangle {
            id: row
            required property var modelData
            width: list.width
            height: Math.min(78, body.implicitHeight + 20)
            radius: 14
            color: area.containsMouse ? cp.pal.badge : cp.pal.track
            border.width: 1
            border.color: cp.pal.tileBorder
            Text {
                id: kind
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.image ? "\u{F02E9}" : "\u{F0219}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: cp.pal.accent
            }
            Text {
                id: body
                anchors.left: kind.right
                anchors.leftMargin: 10
                anchors.right: del.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.image ? L.t("Imagen") + "  ·  " + row.modelData.text.replace(/^\[\[\s*binary data\s*/, "").replace(/\s*\]\]$/, "") : row.modelData.text
                maximumLineCount: 3
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                font.family: "Exo 2"
                font.pixelSize: 12
                color: cp.pal.text
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!cp.backend) return
                    cp.backend.clipCopy(row.modelData.line)
                    cp.done()
                }
            }
            Text {
                id: del
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F01B4}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: delArea.containsMouse ? "#e63a4a" : cp.pal.muted
                MouseArea {
                    id: delArea
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (cp.backend) cp.backend.clipDelete(row.modelData.line)
                }
            }
        }
    }

    Column {
        anchors.centerIn: list
        spacing: 8
        visible: cp.shown.length === 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{F014C}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 40
            color: cp.pal.heroSub
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: cp.backend && cp.backend.clipAvail === false ? L.t("INSTALÁ CLIPHIST") : L.t("NADA COPIADO TODAVÍA")
            font.family: "Michroma"
            font.pixelSize: 10
            color: cp.pal.heroSub
        }
    }
}
