import QtQuick

Item {
    id: hd
    property var pal
    property string title: ""
    property bool on: false
    property bool switchEnabled: true
    property bool spinning: false
    property bool showRefresh: true
    signal back()
    signal refresh()
    signal toggled(bool value)

    implicitHeight: 44

    Rectangle {
        id: backBtn
        x: 0
        anchors.verticalCenter: parent.verticalCenter
        width: 34; height: 34; radius: 17
        antialiasing: true
        color: backArea.containsMouse ? hd.pal.badge : "transparent"
        border.width: 1
        border.color: hd.pal.tileBorder
        Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -1
            text: "\u{F0141}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            color: hd.pal.hero
        }
        MouseArea {
            id: backArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hd.back()
        }
    }

    Text {
        anchors.left: backBtn.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: hd.title
        font.family: "Michroma"
        font.pixelSize: 17
        color: hd.pal.hero
        style: Text.Raised
        styleColor: hd.pal.heroShadow
    }

    Rectangle {
        id: refreshBtn
        visible: hd.showRefresh
        anchors.right: toggle.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 34; height: 34; radius: 17
        antialiasing: true
        color: refreshArea.containsMouse ? hd.pal.badge : "transparent"
        border.width: 1
        border.color: hd.pal.tileBorder
        opacity: hd.on ? 1 : 0.4
        Text {
            id: spinner
            anchors.centerIn: parent
            text: "\u{F0450}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
            color: hd.pal.hero
            RotationAnimator on rotation {
                running: hd.spinning
                from: 0
                to: 360
                duration: 900
                loops: Animation.Infinite
            }
            onRotationChanged: if (!hd.spinning && rotation !== 0) rotation = 0
        }
        MouseArea {
            id: refreshArea
            anchors.fill: parent
            enabled: hd.on && !hd.spinning
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hd.refresh()
        }
    }

    AeroSwitch {
        id: toggle
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        pal: hd.pal
        on: hd.on
        enabledSwitch: hd.switchEnabled
        onToggled: function(v) { hd.toggled(v) }
    }
}
