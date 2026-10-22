import QtQuick

Item {
    id: c
    property var pal
    property string mode: "extend"
    property string title: ""
    property string hint: ""
    property string key: ""
    property bool chosen: false
    property bool available: true
    property bool pending: false
    signal picked()
    implicitWidth: 176
    implicitHeight: 150
    opacity: available ? 1 : 0.4
    scale: area.pressed ? 0.97 : (area.containsMouse && available ? 1.02 : 1)
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: 20
        color: "transparent"
        border.width: 3
        border.color: c.pal.select
        opacity: c.chosen ? 0.55 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        antialiasing: true
        border.width: c.chosen ? 2 : 1
        border.color: c.chosen ? c.pal.select : c.pal.cardBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: c.chosen ? Qt.lighter(c.pal.fill0, 1.1) : c.pal.btn0 }
            GradientStop { position: 0.5; color: c.chosen ? c.pal.fill1 : c.pal.btn1 }
            GradientStop { position: 0.52; color: c.chosen ? c.pal.fill2 : c.pal.btn2 }
            GradientStop { position: 1.0; color: c.chosen ? c.pal.fill1 : c.pal.btn3 }
        }
        Rectangle {
            x: 10; y: 3
            width: parent.width - 20
            height: parent.height * 0.4
            radius: 12
            color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.42 : 0.3)
        }
    }

    Item {
        id: art
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        width: 140
        height: 62
        readonly property color on: c.chosen ? Qt.lighter(c.pal.sky, 1.45) : c.pal.sky

        MiniScreen {
            id: mon
            pal: c.pal
            glow: art.on
            width: c.mode === "extend" ? 62 : 70
            height: 50
            x: c.mode === "extend" ? 4 : c.mode === "laptop" ? 4 : 4
            y: 4
            lit: c.mode !== "laptop"
            label: c.mode === "extend" ? "1" : c.mode === "duplicate" ? "1" : ""
        }
        MiniScreen {
            pal: c.pal
            glow: art.on
            laptop: true
            width: 50
            height: 38
            x: c.mode === "extend" ? 82 : 84
            y: 16
            lit: c.mode !== "external"
            label: c.mode === "extend" ? "2" : c.mode === "duplicate" ? "1" : ""
        }
        Text {
            visible: c.mode === "duplicate"
            x: 73
            y: 22
            text: "="
            font.family: "Exo 2"
            font.weight: Font.Black
            font.pixelSize: 16
            color: c.chosen ? "#ffffff" : c.pal.accent
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 92
        text: c.title
        font.family: "Exo 2"
        font.weight: Font.Bold
        font.pixelSize: 15
        color: c.chosen ? "#ffffff" : c.pal.ink
        style: c.chosen ? Text.Raised : Text.Normal
        styleColor: "#550b0d12"
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 114
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
        text: c.pending ? "Aplicando…" : c.hint
        elide: Text.ElideRight
        font.family: "Exo 2"
        font.pixelSize: 11
        color: c.chosen ? "#e6f4ff" : c.pal.muted
    }

    Rectangle {
        x: parent.width - 30
        y: 8
        width: 22
        height: 22
        radius: 6
        color: c.chosen ? "#33ffffff" : c.pal.field
        border.width: 1
        border.color: c.chosen ? "#80ffffff" : c.pal.fieldBorder
        Text {
            anchors.centerIn: parent
            text: c.key
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
            font.bold: true
            color: c.chosen ? "#ffffff" : c.pal.muted
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        enabled: c.available
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: c.picked()
    }
}
