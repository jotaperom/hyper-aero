import QtQuick

Card {
    id: w
    property var core
    readonly property var apps: core ? core.favorites : []
    readonly property real icon: Math.max(30, Math.min(56, body.height * (body.height > 110 ? 0.42 : 0.8)))
    readonly property int perRow: Math.max(1, Math.floor((body.width + 10) / (icon + 10)))
    readonly property int rowsFit: Math.max(1, Math.floor((body.height + 8) / (icon + (showNames ? 22 : 8))))
    readonly property bool showNames: body.height >= icon + 18
    title: "DOCK"
    tag: apps.length + " APPS"

    Grid {
        anchors.centerIn: parent
        columns: w.perRow
        columnSpacing: (w.body.width - w.perRow * w.icon) / Math.max(1, w.perRow - 1 + 0.0001) > 22 ? 22 : 10
        rowSpacing: 6

        Repeater {
            model: w.apps.slice(0, w.perRow * w.rowsFit)
            delegate: Item {
                required property var modelData
                width: w.icon
                height: w.icon + (w.showNames ? 16 : 0)

                Rectangle {
                    id: tile
                    width: w.icon
                    height: w.icon
                    radius: w.icon * 0.28
                    antialiasing: true
                    border.width: 1
                    border.color: hot.containsMouse ? w.pal.glow : "#ccffffff"
                    scale: hot.pressed ? 0.92 : (hot.containsMouse ? 1.08 : 1)
                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: w.pal.btn0 }
                        GradientStop { position: 0.5; color: w.pal.btn1 }
                        GradientStop { position: 1.0; color: w.pal.btn2 }
                    }
                    Image {
                        id: img
                        anchors.centerIn: parent
                        width: w.icon * 0.7
                        height: width
                        sourceSize.width: 128
                        sourceSize.height: 128
                        source: modelData.icon
                        smooth: true
                        mipmap: true
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: img.status !== Image.Ready
                        text: modelData.name.charAt(0).toUpperCase()
                        font.family: "Michroma"
                        font.pixelSize: w.icon * 0.38
                        color: w.pal.accent
                    }
                    Rectangle {
                        x: 2; y: 1
                        width: parent.width - 4
                        height: parent.height * 0.46
                        radius: parent.radius - 1
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, w.core && w.core.night ? 0.22 : 0.7) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                        }
                    }
                }
                Text {
                    visible: w.showNames
                    anchors.top: tile.bottom
                    anchors.topMargin: 3
                    anchors.horizontalCenter: tile.horizontalCenter
                    width: w.icon + 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: modelData.name
                    font.family: "Exo 2"
                    font.weight: Font.DemiBold
                    font.pixelSize: 10
                    color: w.pal.muted
                }
                MouseArea {
                    id: hot
                    anchors.fill: tile
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: w.core.launch(modelData.key)
                }
            }
        }
    }
}
