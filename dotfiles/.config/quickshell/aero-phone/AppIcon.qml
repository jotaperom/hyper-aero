import QtQuick

Item {
    id: ai
    property var pal
    property string source: ""
    property string name: ""
    property real size: 54
    property bool lit: false
    property bool hot: false

    width: size
    height: size

    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: ai.size * 0.32
        antialiasing: true
        color: "transparent"
        border.width: 3
        border.color: ai.pal.ring
        opacity: ai.lit ? 0.95 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: ai.size * 0.28
        antialiasing: true
        border.width: 1
        border.color: ai.hot ? ai.pal.glow : ai.pal.iconBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: ai.pal.icon0 }
            GradientStop { position: 0.5; color: ai.pal.icon1 }
            GradientStop { position: 1.0; color: ai.pal.icon2 }
        }
    }

    Image {
        id: img
        anchors.centerIn: parent
        width: ai.size * 0.70
        height: width
        sourceSize.width: 128
        sourceSize.height: 128
        source: ai.source
        smooth: true
        mipmap: true
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: ai.name.length ? ai.name.charAt(0).toUpperCase() : "?"
        font.family: "Michroma"
        font.pixelSize: ai.size * 0.38
        color: ai.pal.accent
    }

    Rectangle {
        x: 2; y: 1
        width: parent.width - 4
        height: parent.height * 0.48
        radius: ai.size * 0.26
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, ai.pal.iconGloss) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    scale: ai.hot ? 1.06 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
}
