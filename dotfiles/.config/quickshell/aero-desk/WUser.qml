import QtQuick
import Quickshell.Widgets

Card {
    id: w
    property var core
    readonly property var u: core ? core.user : ({})
    readonly property var s: core ? core.sys : ({})
    readonly property int hour: core ? core.now.getHours() : 12
    readonly property string greet: hour < 5 ? "GOOD NIGHT" : (hour < 12 ? "GOOD MORNING" : (hour < 19 ? "GOOD AFTERNOON" : "GOOD EVENING"))
    readonly property real av: Math.max(40, Math.min(body.height, 96))
    readonly property bool chips: body.height >= 92
    title: "PILOT"
    tag: (u.host || "").toUpperCase()

    Item {
        id: avatar
        width: w.av
        height: w.av
        y: w.chips ? 0 : (parent.height - height) / 2

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            antialiasing: true
            border.width: 2
            border.color: "#e6ffffff"
            gradient: Gradient {
                GradientStop { position: 0.0; color: w.pal.fill0 }
                GradientStop { position: 0.5; color: w.pal.fill1 }
                GradientStop { position: 1.0; color: w.pal.fill2 }
            }
            Text {
                anchors.centerIn: parent
                visible: face.status !== Image.Ready
                text: (w.u.full || w.u.name || "?").charAt(0).toUpperCase()
                font.family: "Michroma"
                font.pixelSize: w.av * 0.42
                color: "#ffffff"
            }
        }
        ClippingRectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: width / 2
            color: "transparent"
            visible: face.status === Image.Ready
            Image {
                id: face
                anchors.fill: parent
                source: w.u.face ? "file://" + w.u.face : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }
        Rectangle {
            x: 4; y: 2
            width: parent.width - 8
            height: parent.height * 0.42
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.3)
        }
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 2
            width: 14; height: 14; radius: 7
            color: "#3ddc97"
            border.width: 2
            border.color: "#ffffff"
        }
    }

    Column {
        anchors.left: avatar.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        y: w.chips ? 2 : (parent.height - height) / 2
        spacing: 2
        Text {
            text: w.greet
            font.family: "Michroma"
            font.pixelSize: 9
            color: w.pal.accent
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: w.u.full || w.u.name || ""
            font.family: "Exo 2"
            font.weight: Font.Black
            font.pixelSize: Math.max(16, Math.min(28, w.av * 0.3))
            color: w.pal.ink
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: (w.u.name || "") + "@" + (w.u.host || "") + "  ·  " + (w.u.shell || "")
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 9
            color: w.pal.muted
        }
    }

    Row {
        visible: w.chips
        anchors.bottom: parent.bottom
        anchors.left: avatar.right
        anchors.leftMargin: 14
        spacing: 6
        Repeater {
            model: [
                ["UPTIME", w.s.uptime || "--"],
                ["KERNEL", w.u.kernel || "--"],
                ["PKGS", String(w.u.pkgs || 0)],
                ["BAT", w.s.bat >= 0 ? w.s.bat + "%" : "AC"]
            ]
            delegate: Rectangle {
                required property var modelData
                required property int index
                visible: index < Math.floor((w.body.width - w.av - 14) / 78)
                width: 72
                height: 34
                radius: 10
                color: w.pal.field
                border.width: 1
                border.color: w.pal.fieldBorder
                Column {
                    anchors.centerIn: parent
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData[0]
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 7
                        color: w.pal.muted
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData[1]
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 11
                        color: w.pal.ink
                    }
                }
            }
        }
    }
}
