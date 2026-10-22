import QtQuick

Item {
    id: ct
    property var pal
    property bool rec: false
    property real since: 0
    property bool live: false
    property real now: Date.now() / 1000
    property real pulse: 0
    readonly property int elapsed: Math.max(0, Math.floor(now - since))
    signal shot()
    signal record()
    signal recordRegion()

    implicitHeight: 64

    function clock(t) {
        var h = Math.floor(t / 3600)
        var m = Math.floor(t % 3600 / 60)
        var s = t % 60
        var mm = (m < 10 ? "0" : "") + m
        var ss = (s < 10 ? "0" : "") + s
        return h > 0 ? h + ":" + mm + ":" + ss : mm + ":" + ss
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: ct.rec && ct.live
        onTriggered: ct.now = Date.now() / 1000
    }

    SequentialAnimation on pulse {
        running: ct.rec && ct.live
        loops: Animation.Infinite
        NumberAnimation { from: 0; to: 1; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { from: 1; to: 0; duration: 700; easing.type: Easing.InOutSine }
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        antialiasing: true
        border.width: 1
        border.color: ct.pal.tileBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: ct.pal.tile0 }
            GradientStop { position: 0.48; color: ct.pal.tile1 }
            GradientStop { position: 0.52; color: ct.pal.tile2 }
            GradientStop { position: 1.0; color: ct.pal.tile3 }
        }
    }

    Rectangle {
        x: 1; y: 1
        width: parent.width - 2
        height: parent.height * 0.46
        radius: 19
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, ct.pal.glossTop) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    Rectangle {
        x: ct.width / 2
        y: 14
        width: 1
        height: ct.height - 28
        color: ct.pal.tileBorder
        opacity: ct.rec ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }

    Rectangle {
        x: 4; y: 4
        width: ct.width / 2 - 6
        height: ct.height - 8
        radius: 16
        antialiasing: true
        color: Qt.rgba(1, 1, 1, shotArea.pressed ? 0.26 : 0.16)
        opacity: shotArea.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    Rectangle {
        x: ct.width / 2 + 2; y: 4
        width: ct.width / 2 - 6
        height: ct.height - 8
        radius: 16
        antialiasing: true
        color: Qt.rgba(1, 1, 1, recArea.pressed ? 0.26 : 0.16)
        opacity: recArea.containsMouse && !ct.rec ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    Rectangle {
        id: redPill
        x: ct.width / 2 + 2; y: 4
        width: ct.width / 2 - 6
        height: ct.height - 8
        radius: 16
        antialiasing: true
        border.width: 1
        border.color: "#e6ffb3bb"
        opacity: ct.rec ? 1 : 0
        scale: ct.rec ? (recArea.pressed ? 0.96 : 1) : 0.85
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ff8d98" }
            GradientStop { position: 0.48; color: "#ec4a5f" }
            GradientStop { position: 0.52; color: "#d6304a" }
            GradientStop { position: 1.0; color: "#e34a60" }
        }
        Rectangle {
            x: 1; y: 1
            width: parent.width - 2
            height: parent.height * 0.46
            radius: 15
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.45) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }

    Column {
        x: 0
        width: ct.width / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 28; height: 28; radius: 14
            antialiasing: true
            color: ct.pal.badge
            border.width: 1
            border.color: ct.pal.tileBorder
            Text {
                anchors.centerIn: parent
                text: "\u{F0E51}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                color: ct.pal.accent
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Captura"
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 11
            color: ct.pal.text
        }
    }

    Column {
        x: ct.width / 2
        width: ct.width / 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 28; height: 28

            Rectangle {
                anchors.centerIn: parent
                width: 28 + ct.pulse * 8
                height: width
                radius: width / 2
                antialiasing: true
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(1, 1, 1, 0.7 * (1 - ct.pulse))
                visible: ct.rec
            }
            Rectangle {
                anchors.fill: parent
                radius: 14
                antialiasing: true
                color: ct.rec ? Qt.rgba(1, 1, 1, 0.24) : ct.pal.badge
                border.width: 1
                border.color: ct.rec ? Qt.rgba(1, 1, 1, 0.6) : ct.pal.tileBorder
                Text {
                    anchors.centerIn: parent
                    text: ct.rec ? "\u{F04DB}" : "\u{F044A}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    color: ct.rec ? "#ffffff" : "#d6304a"
                }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ct.rec ? ct.clock(ct.elapsed) : "Grabar"
            font.family: ct.rec ? "JetBrainsMono Nerd Font" : "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 11
            color: ct.rec ? "#ffffff" : ct.pal.text
        }
    }

    MouseArea {
        id: shotArea
        x: 0
        width: ct.width / 2
        height: ct.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ct.shot()
    }

    MouseArea {
        id: recArea
        x: ct.width / 2
        width: ct.width / 2
        height: ct.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton && !ct.rec) ct.recordRegion()
            else ct.record()
        }
        onPressAndHold: if (!ct.rec) ct.recordRegion()
    }
}
