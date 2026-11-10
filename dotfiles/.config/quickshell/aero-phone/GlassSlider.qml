import QtQuick

Item {
    id: slider
    property var pal
    property real value: 0
    property string glyph: ""
    property string label: ""
    property bool dim: false
    property bool more: false
    property string hint: ""
    property real live: drag.pressed ? dragValue : value
    property real dragValue: 0
    signal moved(real v)
    signal glyphClicked()
    signal moreClicked()

    implicitHeight: 46

    function setFrom(x) {
        dragValue = Math.max(0, Math.min(1, (x - 4) / (width - 8)))
        moved(dragValue)
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        antialiasing: true
        color: slider.pal.track
        border.width: 1
        border.color: slider.pal.tileBorder
    }

    Rectangle {
        x: 3; y: 3
        height: parent.height - 6
        width: Math.max(height, (parent.width - 6) * slider.live)
        radius: height / 2
        antialiasing: true
        opacity: slider.dim ? 0.45 : 1
        border.width: 1
        border.color: slider.pal.onBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: slider.pal.on0 }
            GradientStop { position: 0.48; color: slider.pal.on1 }
            GradientStop { position: 0.52; color: slider.pal.on2 }
            GradientStop { position: 1.0; color: slider.pal.on3 }
        }
        Rectangle {
            x: 2; y: 1
            width: parent.width - 4
            height: parent.height * 0.45
            radius: height / 2
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.45) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
        Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: function(m) { slider.setFrom(m.x) }
        onPositionChanged: function(m) { if (pressed) slider.setFrom(m.x) }
        onWheel: function(w) {
            var step = w.angleDelta.y > 0 || w.angleDelta.x < 0 ? 0.05 : -0.05
            slider.moved(Math.max(0, Math.min(1, slider.value + step)))
        }
    }

    Text {
        id: icon
        x: 16
        anchors.verticalCenter: parent.verticalCenter
        text: slider.glyph
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 18
        color: "#ffffff"
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.25)
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: slider.glyphClicked()
        }
    }

    Text {
        id: labelText
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: hintText.visible ? -7 : 0
        width: Math.min(implicitWidth, pct.x - x - 10)
        elide: Text.ElideRight
        text: slider.label
        font.family: "Exo 2"
        font.weight: Font.Bold
        font.pixelSize: 12
        color: slider.live > 0.32 ? "#ffffff" : slider.pal.text
    }

    Text {
        id: hintText
        anchors.left: labelText.left
        anchors.top: labelText.bottom
        anchors.topMargin: -1
        width: Math.max(0, pct.x - x - 10)
        visible: slider.hint.length > 0 && slider.height >= 36
        elide: Text.ElideRight
        text: slider.hint
        font.family: "Exo 2"
        font.weight: Font.DemiBold
        font.pixelSize: 10
        color: slider.live > 0.45 ? Qt.rgba(1, 1, 1, 0.82) : slider.pal.muted
    }

    Rectangle {
        id: moreBtn
        visible: slider.more
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: parent.height - 12
        height: width
        radius: width / 2
        antialiasing: true
        color: moreArea.containsMouse ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.16)
        border.width: 1
        border.color: slider.pal.tileBorder
        Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 1
            text: "\u{F0142}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: slider.live > 0.85 ? "#ffffff" : slider.pal.text
        }
        MouseArea {
            id: moreArea
            anchors.fill: parent
            anchors.margins: -3
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: slider.moreClicked()
        }
    }

    Text {
        id: pct
        anchors.right: slider.more ? moreBtn.left : parent.right
        anchors.rightMargin: slider.more ? 10 : 16
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(slider.live * 100) + "%"
        font.family: "JetBrainsMono Nerd Font"
        font.weight: Font.Bold
        font.pixelSize: 12
        color: slider.live > 0.78 ? "#ffffff" : slider.pal.muted
    }
}
