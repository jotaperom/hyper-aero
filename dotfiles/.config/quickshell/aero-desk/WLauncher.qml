import QtQuick
import "Lang.js" as L

Card {
    id: w
    property var core
    property bool editing: false
    readonly property var apps: core ? core.favorites : []
    readonly property var shown: apps.slice(0, Math.max(0, w.perRow * w.rowsFit - (editing || apps.length === 0 ? 1 : 0)))
    readonly property var tiles: editing || apps.length === 0 ? shown.concat([{ key: "", add: true }]) : shown
    readonly property real icon: Math.max(30, Math.min(56, body.height * (body.height > 110 ? 0.42 : 0.8)))
    readonly property int perRow: Math.max(1, Math.floor((body.width + 10) / (icon + 10)))
    readonly property int rowsFit: Math.max(1, Math.floor((body.height + 8) / (icon + (showNames ? 22 : 8))))
    readonly property bool showNames: body.height >= icon + 18
    title: "DOCK"
    tag: editing ? L.t("EDITANDO") : apps.length + " APPS"

    function keys() {
        return apps.map(function(a) { return a.key })
    }

    function remove(key) {
        if (!core) return
        core.setPins(keys().filter(function(k) { return k !== key }))
    }

    function shift(key, dir) {
        var l = keys()
        var i = l.indexOf(key)
        var j = i + dir
        if (i < 0 || j < 0 || j >= l.length) return
        l.splice(i, 1)
        l.splice(j, 0, key)
        core.setPins(l)
    }

    Timer {
        running: w.editing
        interval: 12000
        onTriggered: w.editing = false
    }

    Grid {
        anchors.centerIn: parent
        columns: w.perRow
        columnSpacing: (w.body.width - w.perRow * w.icon) / Math.max(1, w.perRow - 1 + 0.0001) > 22 ? 22 : 10
        rowSpacing: 6

        Repeater {
            model: w.tiles
            delegate: Item {
                id: cellRoot
                required property var modelData
                required property int index
                readonly property bool add: !!modelData.add
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
                    opacity: cellRoot.add ? 0.75 : 1
                    scale: hot.pressed ? 0.92 : (hot.containsMouse ? 1.08 : 1)
                    rotation: w.editing && !cellRoot.add ? (cellRoot.index % 2 ? 1.6 : -1.6) * wobble.v : 0
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
                        source: cellRoot.add ? "" : cellRoot.modelData.icon
                        smooth: true
                        mipmap: true
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: img.status !== Image.Ready
                        text: cellRoot.add ? "\u{F0415}" : cellRoot.modelData.name.charAt(0).toUpperCase()
                        font.family: cellRoot.add ? "JetBrainsMono Nerd Font" : "Michroma"
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

                Rectangle {
                    visible: w.editing && !cellRoot.add
                    x: tile.width - width / 2 - 4
                    y: -height / 2 + 4
                    width: Math.max(18, w.icon * 0.36)
                    height: width
                    radius: width / 2
                    color: delArea.containsMouse ? "#ff5a6b" : "#e63a4a"
                    border.width: 1
                    border.color: "#ffffff"
                    Text {
                        anchors.centerIn: parent
                        text: "\u{F0156}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: parent.width * 0.62
                        color: "#ffffff"
                    }
                    MouseArea {
                        id: delArea
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: w.remove(cellRoot.modelData.key)
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
                    text: cellRoot.add ? L.t("Agregar") : cellRoot.modelData.name
                    font.family: "Exo 2"
                    font.weight: Font.DemiBold
                    font.pixelSize: 10
                    color: w.pal.muted
                }

                MouseArea {
                    id: hot
                    anchors.fill: tile
                    z: -1
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(m) {
                        if (cellRoot.add) {
                            w.editing = false
                            w.core.openDockPicker()
                        } else if (m.button === Qt.RightButton) {
                            w.editing = !w.editing
                        } else if (w.editing) {
                            w.shift(cellRoot.modelData.key, m.x < tile.width / 2 ? -1 : 1)
                        } else {
                            w.core.launch(cellRoot.modelData.key)
                        }
                    }
                }
            }
        }
    }

    Item {
        id: wobble
        visible: false
        property real v: 0
        SequentialAnimation on v {
            running: w.editing
            loops: Animation.Infinite
            NumberAnimation { from: -1; to: 1; duration: 140; easing.type: Easing.InOutSine }
            NumberAnimation { from: 1; to: -1; duration: 140; easing.type: Easing.InOutSine }
        }
    }

    Text {
        visible: w.editing
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: -4
        text: L.t("Clic a un lado del ícono para moverlo · clic derecho para terminar")
        font.family: "Exo 2"
        font.pixelSize: 9
        color: w.pal.muted
        opacity: w.body.height > w.icon + 30 ? 1 : 0
    }
}
