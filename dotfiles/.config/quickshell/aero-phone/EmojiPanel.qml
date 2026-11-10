import QtQuick
import Quickshell.Io
import "Lang.js" as L

Item {
    id: ep
    property var pal
    property var backend
    property bool live: false
    property string query: ""
    property string cat: "recent"
    property var emojis: []
    readonly property var cats: [
        { id: "recent", glyph: "\u{F02DA}" }, { id: "caras", glyph: "\u{F01F5}" }, { id: "gente", glyph: "\u{F0849}" },
        { id: "naturaleza", glyph: "\u{F0405}" }, { id: "comida", glyph: "\u{F025A}" }, { id: "actividades", glyph: "\u{F0A36}" },
        { id: "viajes", glyph: "\u{F00F9}" }, { id: "objetos", glyph: "\u{F0335}" }, { id: "simbolos", glyph: "\u{F04CE}" }, { id: "banderas", glyph: "\u{F023B}" }
    ]
    readonly property var recent: backend ? backend.emojiRecent : []
    readonly property var shown: {
        var q = query.toLowerCase().trim()
        if (q.length) {
            var out = []
            for (var i = 0; i < emojis.length && out.length < 240; i++) {
                var d = emojis[i]
                if (d.n.indexOf(q) >= 0 || d.s.indexOf(q) >= 0) out.push(d.e)
            }
            return out
        }
        if (cat === "recent") return recent
        return emojis.filter(function(d) { return d.c === ep.cat }).map(function(d) { return d.e })
    }
    signal back()
    signal done()

    onLiveChanged: if (live) {
        query = ""
        search.text = ""
        cat = recent.length ? "recent" : "caras"
        if (!emojis.length) file.reload()
    }

    FileView {
        id: file
        path: Qt.resolvedUrl("emoji.json").toString().replace("file://", "")
        printErrors: false
        onLoaded: {
            try {
                ep.emojis = JSON.parse(text())
            } catch (err) {
                ep.emojis = []
            }
        }
    }

    PanelHeader {
        id: header
        x: 14
        y: 4
        width: parent.width - 28
        pal: ep.pal
        title: "Emojis"
        on: true
        switchEnabled: false
        showSwitch: false
        showRefresh: false
        onBack: ep.back()
    }

    Rectangle {
        id: field
        anchors.top: header.bottom
        anchors.topMargin: 6
        x: 14
        width: parent.width - 28
        height: 36
        radius: 18
        color: ep.pal.field
        border.width: search.activeFocus ? 2 : 1
        border.color: search.activeFocus ? ep.pal.glow : ep.pal.tileBorder
        Text {
            id: lens
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0349}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: ep.pal.accent
        }
        TextInput {
            id: search
            anchors.left: lens.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Exo 2"
            font.pixelSize: 14
            color: ep.pal.text
            clip: true
            onTextChanged: ep.query = text
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !search.text.length
                text: L.t("Buscar emoji (español o inglés)")
                font: search.font
                color: ep.pal.muted
            }
        }
    }

    ListView {
        id: tabs
        anchors.top: field.bottom
        anchors.topMargin: 8
        x: 14
        width: parent.width - 28
        height: 32
        orientation: ListView.Horizontal
        spacing: 4
        clip: true
        visible: !ep.query.length
        model: ep.cats
        delegate: Rectangle {
            required property var modelData
            width: 32
            height: 32
            radius: 16
            color: ep.cat === modelData.id ? ep.pal.accentFill : (tabArea.containsMouse ? ep.pal.badge : "transparent")
            Text {
                anchors.centerIn: parent
                text: modelData.glyph
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: ep.cat === modelData.id ? "#ffffff" : ep.pal.accent
            }
            MouseArea {
                id: tabArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    ep.cat = modelData.id
                    grid.positionViewAtBeginning()
                }
            }
        }
    }

    GridView {
        id: grid
        anchors.top: ep.query.length ? field.bottom : tabs.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        x: 10
        width: parent.width - 20
        cellWidth: width / Math.max(6, Math.floor(width / 46))
        cellHeight: 44
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: ep.shown
        delegate: Rectangle {
            required property var modelData
            width: grid.cellWidth
            height: grid.cellHeight
            radius: 10
            color: cellArea.containsMouse ? ep.pal.badge : "transparent"
            Text {
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 24
                scale: cellArea.containsMouse ? 1.2 : 1
                Behavior on scale { NumberAnimation { duration: 110 } }
            }
            MouseArea {
                id: cellArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (ep.backend) ep.backend.emojiCopy(modelData)
                    ep.done()
                }
            }
        }
    }

    Text {
        anchors.centerIn: grid
        visible: ep.shown.length === 0
        text: ep.cat === "recent" && !ep.query.length ? L.t("TODAVÍA NO USASTE NINGUNO") : L.t("SIN COINCIDENCIAS")
        font.family: "Michroma"
        font.pixelSize: 10
        color: ep.pal.heroSub
    }
}
