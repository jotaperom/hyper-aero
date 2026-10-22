import QtQuick

Item {
    id: pad
    property var pal
    property real light: 0
    property bool night: false
    readonly property color lit: pal ? pal.keyLit : "#1e6fd9"
    signal key(string k)

    readonly property var digits: [
        { d: "1", g: "\u{F05A9}", s: "WI-FI" }, { d: "2", g: "\u{F00AF}", s: "BT" }, { d: "3", g: "\u{F0594}", s: "NOCHE" },
        { d: "4", g: "\u{F0E51}", s: "FOTO" }, { d: "5", g: "\u{F044A}", s: "GRABAR" }, { d: "6", g: "\u{F040E}", s: "MÚSICA" },
        { d: "7", g: "\u{F0335}", s: "CÁLIDA" }, { d: "8", g: "\u{F009B}", s: "NO MOL." }, { d: "9", g: "\u{F03D8}", s: "TEMA" },
        { d: "*", g: "\u{F0581}", s: "MUTE" }, { d: "0", g: "\u{F02DC}", s: "INICIO" }, { d: "#", g: "\u{F033E}", s: "BLOQ." }
    ]

    GelKey {
        x: 24; y: 44
        width: 86; height: 34
        pal: pad.pal; light: pad.light; night: pad.night
        glyph: "—"
        onTapped: pad.key("softL")
    }

    GelKey {
        x: pad.width - 24 - 86; y: 44
        width: 86; height: 34
        pal: pad.pal; light: pad.light; night: pad.night
        glyph: "—"
        onTapped: pad.key("softR")
    }

    GelKey {
        x: 24; y: 92
        width: 86; height: 34
        pal: pad.pal; light: pad.light; night: pad.night
        glyph: "\u{F03F2}"
        tone: "#25b066"
        onTapped: pad.key("call")
    }

    GelKey {
        x: pad.width - 24 - 86; y: 92
        width: 86; height: 34
        pal: pad.pal; light: pad.light; night: pad.night
        glyph: "\u{F03F5}"
        tone: "#e0434f"
        onTapped: pad.key("end")
    }

    Item {
        id: dpad
        width: 116; height: 116
        x: (pad.width - width) / 2
        y: 28
        property string dir: ""

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            radius: width / 2
            antialiasing: true
            color: pad.pal.keyEdge
            opacity: 0.55
        }

        Rectangle {
            id: ringFace
            width: parent.width
            height: parent.height - 3
            radius: width / 2
            antialiasing: true
            border.width: 1
            border.color: pad.pal.keyRim
            gradient: Gradient {
                GradientStop { position: 0.0; color: pad.pal.key0 }
                GradientStop { position: 0.48; color: pad.pal.key1 }
                GradientStop { position: 0.52; color: pad.pal.key2 }
                GradientStop { position: 1.0; color: pad.pal.key3 }
            }

            Rectangle {
                x: 10; y: 3
                width: parent.width - 20
                height: parent.height * 0.42
                radius: height / 2
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, pad.night ? 0.2 : 0.8) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            Repeater {
                model: [
                    { d: "up", r: 0, x: 0, y: -1 }, { d: "right", r: 90, x: 1, y: 0 },
                    { d: "down", r: 180, x: 0, y: 1 }, { d: "left", r: 270, x: -1, y: 0 }
                ]
                delegate: Text {
                    required property var modelData
                    text: "\u{F0143}"
                    rotation: modelData.r
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                    x: ringFace.width / 2 - width / 2 + modelData.x * 41
                    y: ringFace.height / 2 - height / 2 + modelData.y * 41
                    color: dpad.dir === modelData.d ? pad.pal.keyLit
                         : Qt.tint(pad.pal.keySub, Qt.rgba(pad.lit.r, pad.lit.g, pad.lit.b, pad.light * 0.8))
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function which(mx, my) {
                var dx = mx - width / 2
                var dy = my - height / 2
                if (Math.abs(dx) > Math.abs(dy)) return dx > 0 ? "right" : "left"
                return dy > 0 ? "down" : "up"
            }
            onPressed: function (m) { dpad.dir = which(m.x, m.y) }
            onReleased: dpad.dir = ""
            onCanceled: dpad.dir = ""
            onClicked: function (m) { pad.key(which(m.x, m.y)) }
        }

        Item {
            width: 50; height: 50
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -1

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                radius: width / 2
                antialiasing: true
                color: pad.pal.keyEdge
            }
            Rectangle {
                width: parent.width
                height: parent.height - 2
                y: okArea.pressed ? 1.5 : 0
                radius: width / 2
                antialiasing: true
                border.width: 1
                border.color: "#b3ffffff"
                gradient: Gradient {
                    GradientStop { position: 0.0; color: pad.pal.on0 }
                    GradientStop { position: 0.48; color: pad.pal.on1 }
                    GradientStop { position: 0.52; color: pad.pal.on2 }
                    GradientStop { position: 1.0; color: pad.pal.on3 }
                }
                Rectangle {
                    x: 6; y: 2
                    width: parent.width - 12
                    height: parent.height * 0.44
                    radius: height / 2
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.75) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    font.family: "Michroma"
                    font.pixelSize: 11
                    color: "#ffffff"
                    style: Text.Raised
                    styleColor: "#661446c2"
                }
            }
            MouseArea {
                id: okArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: pad.key("ok")
            }
        }
    }

    Grid {
        x: (pad.width - width) / 2
        y: 160
        columns: 3
        columnSpacing: 8
        rowSpacing: 8

        Repeater {
            model: pad.digits
            delegate: GelKey {
                required property var modelData
                required property int index
                width: 92; height: 46
                pal: pad.pal
                night: pad.night
                light: Math.max(0, Math.min(1, pad.light * 2.2 - index * 0.09))
                digit: modelData.d
                glyph: modelData.g
                sub: modelData.s
                onTapped: pad.key(modelData.d)
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 392
        spacing: 4
        Repeater {
            model: 5
            delegate: Rectangle {
                width: 4; height: 4; radius: 2
                color: pad.pal.keyEdge
                opacity: 0.8
            }
        }
    }
}
