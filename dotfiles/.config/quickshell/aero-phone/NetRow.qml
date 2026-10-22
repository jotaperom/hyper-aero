import QtQuick

Item {
    id: row
    property var pal
    property string glyph: ""
    property string title: ""
    property string sub: ""
    property bool active: false
    property bool busy: false
    property bool expanded: false
    property bool showMore: false
    property string mode: "actions"
    property var actions: []
    property string note: ""
    signal tapped()
    signal more()
    signal action(string id)
    signal submit(string password)
    signal cancel()

    readonly property real extra: 50 + (note.length ? 32 : 0) + (mode === "pass" ? 44 : 0)
    implicitHeight: 54 + (expanded ? extra : 0)
    clip: true
    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    onExpandedChanged: {
        if (expanded && mode === "pass") {
            pass.text = ""
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 120
        onTriggered: pass.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        anchors.bottomMargin: 2
        radius: 18
        antialiasing: true
        border.width: 1
        border.color: row.active ? row.pal.onBorder : row.pal.tileBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: row.active ? row.pal.on0 : row.pal.tile0 }
            GradientStop { position: 0.48 * 54 / Math.max(54, row.height); color: row.active ? row.pal.on1 : row.pal.tile1 }
            GradientStop { position: 0.52 * 54 / Math.max(54, row.height); color: row.active ? row.pal.on2 : row.pal.tile2 }
            GradientStop { position: 1.0; color: row.active ? row.pal.on3 : row.pal.tile3 }
        }
    }

    Item {
        id: head
        width: parent.width
        height: 52

        Text {
            id: icon
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text: row.glyph
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 20
            color: row.active ? "#ffffff" : row.pal.accent
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: 10
            anchors.right: tail.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                width: parent.width
                text: row.title
                elide: Text.ElideRight
                font.family: "Exo 2"
                font.weight: Font.Bold
                font.pixelSize: 13
                color: row.active ? "#ffffff" : row.pal.text
            }
            Text {
                width: parent.width
                text: row.sub
                elide: Text.ElideRight
                font.family: "Exo 2"
                font.pixelSize: 11
                color: row.active ? Qt.rgba(1, 1, 1, 0.85) : row.pal.muted
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: !row.busy
            onClicked: row.tapped()
        }

        Item {
            id: tail
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30

            Text {
                anchors.centerIn: parent
                visible: row.busy
                text: "\u{F0772}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: row.active ? "#ffffff" : row.pal.accent
                RotationAnimator on rotation {
                    running: row.busy
                    from: 0
                    to: 360
                    duration: 800
                    loops: Animation.Infinite
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: !row.busy && row.showMore
                radius: 15
                antialiasing: true
                color: moreArea.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: row.expanded ? "\u{F0143}" : "\u{F01D8}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 17
                    color: row.active ? "#ffffff" : row.pal.muted
                }
                MouseArea {
                    id: moreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.more()
                }
            }
        }
    }

    Column {
        anchors.top: head.bottom
        x: 12
        width: parent.width - 24
        spacing: 8
        visible: row.expanded

        Text {
            width: parent.width
            visible: row.note.length > 0
            text: row.note
            wrapMode: Text.WordWrap
            font.family: "Exo 2"
            font.pixelSize: 11
            color: row.active ? "#ffffff" : row.pal.muted
        }

        Rectangle {
            visible: row.mode === "pass"
            width: parent.width
            height: 36
            radius: 18
            antialiasing: true
            color: row.pal.field
            border.width: pass.activeFocus ? 2 : 1
            border.color: pass.activeFocus ? row.pal.glow : row.pal.tileBorder

            TextInput {
                id: pass
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: eye.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                echoMode: eye.reveal ? TextInput.Normal : TextInput.Password
                passwordCharacter: "●"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: row.pal.text
                selectionColor: row.pal.accentFill
                selectedTextColor: "#ffffff"
                clip: true
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !pass.text.length
                    text: "Contraseña"
                    font.family: "Exo 2"
                    font.pixelSize: 13
                    color: row.pal.muted
                }
                Keys.onPressed: function(e) {
                    if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                        if (pass.text.length) row.submit(pass.text)
                        e.accepted = true
                    } else if (e.key === Qt.Key_Escape) {
                        row.cancel()
                        e.accepted = true
                    }
                }
            }

            Text {
                id: eye
                property bool reveal: false
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: reveal ? "\u{F0209}" : "\u{F0208}"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 16
                color: row.pal.muted
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: eye.reveal = !eye.reveal
                }
            }
        }

        Row {
            spacing: 8
            anchors.right: parent.right
            Repeater {
                model: row.mode === "pass" ? [{ id: "cancel", label: "Cancelar" }, { id: "submit", label: "Conectar", primary: true }] : row.actions
                delegate: Rectangle {
                    height: 32
                    width: lbl.implicitWidth + 28
                    radius: 16
                    antialiasing: true
                    border.width: 1
                    border.color: modelData.danger ? "#ff5d6c" : (modelData.primary ? row.pal.onBorder : row.pal.tileBorder)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: modelData.primary ? row.pal.on0 : row.pal.tile0 }
                        GradientStop { position: 0.48; color: modelData.primary ? row.pal.on1 : row.pal.tile1 }
                        GradientStop { position: 0.52; color: modelData.primary ? row.pal.on2 : row.pal.tile2 }
                        GradientStop { position: 1.0; color: modelData.primary ? row.pal.on3 : row.pal.tile3 }
                    }
                    Text {
                        id: lbl
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: "Exo 2"
                        font.weight: Font.Bold
                        font.pixelSize: 12
                        color: modelData.primary ? "#ffffff" : (modelData.danger ? "#ff5d6c" : row.pal.text)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.id === "submit") {
                                if (pass.text.length) row.submit(pass.text)
                            } else if (modelData.id === "cancel") {
                                row.cancel()
                            } else {
                                row.action(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
