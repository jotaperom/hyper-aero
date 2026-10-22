import QtQuick
import "Tint.js" as Tint

Item {
    id: cc
    property var pal
    property var backend
    readonly property var st: backend ? backend.st : ({})
    property string sub: ""
    property bool live: false
    readonly property var accentNames: ({ blue: "AZUL", red: "ROJO", green: "VERDE", black: (cc.st.mode === "night" ? "NEGRO" : "BLANCO") })
    signal act(string name)
    signal pageRequested(int p)
    signal closeRequested

    function scrollBy(d) {
        scrollAnim.stop()
        scrollAnim.from = scroll.contentY
        scrollAnim.to = Math.max(0, Math.min(scroll.contentHeight - scroll.height, scroll.contentY + d))
        scrollAnim.start()
    }

    Item {
        id: main
        width: cc.width
        height: cc.height
        x: cc.sub.length ? -cc.width * 0.3 : 0
        opacity: cc.sub.length ? 0 : 1
        visible: opacity > 0.01
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }
        }

        Flickable {
            id: scroll
            anchors.fill: parent
            contentWidth: width
            contentHeight: content.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            NumberAnimation on contentY {
                id: scrollAnim
                running: false
                duration: 220
                easing.type: Easing.OutCubic
            }

            Item {
                id: content
                width: scroll.width
                height: powerRow.y + powerRow.height + 16

                Column {
                    id: head
                    x: 20
                    y: 6
                    width: parent.width - 40
                    spacing: 2
                    Text {
                        text: "CONTROL"
                        font.family: "Michroma"
                        font.pixelSize: 16
                        font.letterSpacing: 2
                        color: cc.pal.hero
                        style: Text.Raised
                        styleColor: cc.pal.heroShadow
                    }
                    Text {
                        text: (cc.accentNames[cc.st.accent || "blue"] || "PERSONAL") + "  ·  " + (cc.st.mode === "night" ? "CABINA NOCTURNA" : "CIELO DIURNO")
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        color: cc.pal.heroSub
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    y: 42
                    width: skinLabel.implicitWidth + 18
                    height: 18
                    radius: 9
                    color: skinArea.containsMouse ? cc.pal.badge : "transparent"
                    border.width: 1
                    border.color: cc.pal.tileBorder
                    Text {
                        id: skinLabel
                        anchors.centerIn: parent
                        text: "\u{F09A7}  PIEL  \u{F0142}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 9
                        color: cc.pal.heroSub
                    }
                    MouseArea {
                        id: skinArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cc.sub = "skin"
                    }
                }

                Rectangle {
                    id: themesPill
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    y: 12
                    width: themesRow.implicitWidth + 22
                    height: 24
                    radius: 12
                    antialiasing: true
                    border.width: 1
                    border.color: "#b3ffffff"
                    scale: themesArea.pressed ? 0.94 : (themesArea.containsMouse ? 1.05 : 1)
                    Behavior on scale { NumberAnimation { duration: 110 } }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(Tint.color("#3d9be9", cc.st.accent || "blue"), 1.35) }
                        GradientStop { position: 0.5; color: Tint.color("#3d9be9", cc.st.accent || "blue") }
                        GradientStop { position: 1.0; color: Tint.color("#1446c2", cc.st.accent || "blue") }
                    }
                    Rectangle {
                        x: 6; y: 2
                        width: parent.width - 12
                        height: parent.height * 0.42
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, 0.4)
                    }
                    Row {
                        id: themesRow
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{F03D8}"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: "#ffffff"
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "TEMAS"
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 10
                            font.letterSpacing: 1
                            color: "#ffffff"
                        }
                    }
                    MouseArea {
                        id: themesArea
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cc.act("themes")
                    }
                }

                Grid {
                    id: tiles
                    anchors.top: head.bottom
                    anchors.topMargin: 16
                    x: 14
                    width: parent.width - 28
                    columns: width > 440 ? 3 : 2
                    spacing: 10
                    property real cell: (width - spacing * (columns - 1)) / columns

                    Tile {
                        width: tiles.cell
                        pal: cc.pal
                        glyph: cc.st.wifi ? "\u{F05A9}" : "\u{F05AA}"
                        label: "Wi-Fi"
                        sub: cc.st.wifi ? (cc.st.ssid || "Sin conexión") : "Apagado"
                        on: !!cc.st.wifi
                        more: true
                        onClicked: cc.act("wifi")
                        onMoreClicked: cc.sub = "wifi"
                    }
                    Tile {
                        width: tiles.cell
                        pal: cc.pal
                        glyph: cc.st.bt ? "\u{F00AF}" : "\u{F00B2}"
                        label: "Bluetooth"
                        sub: cc.st.btAvail === false ? "No disponible" : (cc.st.bt ? (cc.st.btDev || "Encendido") : "Apagado")
                        on: !!cc.st.bt
                        available: cc.st.btAvail !== false
                        more: true
                        onClicked: cc.act("bt")
                        onMoreClicked: cc.sub = "bt"
                    }
                    Tile {
                        width: tiles.cell
                        pal: cc.pal
                        glyph: cc.st.mode === "night" ? "\u{F0594}" : "\u{F0599}"
                        label: "Night Deck"
                        sub: cc.st.mode === "night" ? "Modo oscuro" : "Modo claro"
                        on: cc.st.mode === "night"
                        onClicked: cc.act("night")
                    }
                    Tile {
                        width: tiles.cell
                        pal: cc.pal
                        glyph: "\u{F0335}"
                        label: "Luz cálida"
                        sub: cc.st.warm ? (cc.st.kelvin + " K") : "Apagada"
                        on: !!cc.st.warm
                        onClicked: cc.act("warm")
                    }
                    Tile {
                        width: tiles.cell
                        pal: cc.pal
                        glyph: cc.st.dnd ? "\u{F009B}" : "\u{F009A}"
                        label: "No molestar"
                        sub: cc.st.dnd ? "Activado" : "Desactivado"
                        on: !!cc.st.dnd
                        onClicked: cc.act("dnd")
                    }
                    CaptureTile {
                        width: tiles.cell
                        pal: cc.pal
                        rec: !!cc.st.rec
                        since: cc.st.recSince || 0
                        live: cc.live
                        onShot: cc.act("shot")
                        onRecord: cc.act("rec")
                        onRecordRegion: cc.act("rec-region")
                    }
                }

                Column {
                    id: sliders
                    anchors.top: tiles.bottom
                    anchors.topMargin: 16
                    x: 14
                    width: parent.width - 28
                    spacing: 10

                    GlassSlider {
                        width: parent.width
                        pal: cc.pal
                        glyph: cc.backend && cc.backend.muted ? "\u{F075F}" : "\u{F057E}"
                        label: "Volumen"
                        dim: cc.backend ? cc.backend.muted : false
                        value: cc.backend ? cc.backend.volume : 0
                        onMoved: function (v) {
                            if (cc.backend)
                                cc.backend.setVolume(v);
                        }
                        onGlyphClicked: if (cc.backend)
                            cc.backend.toggleMute()
                    }
                    GlassSlider {
                        width: parent.width
                        pal: cc.pal
                        glyph: "\u{F00E0}"
                        label: "Brillo"
                        value: Math.max(0, cc.st.bri || 0) / 100
                        onMoved: function (v) {
                            if (cc.backend)
                                cc.backend.setBrightness(v);
                        }
                    }
                }

                MediaCard {
                    id: media
                    anchors.top: sliders.bottom
                    anchors.topMargin: 12
                    x: 14
                    width: parent.width - 28
                    pal: cc.pal
                    media: cc.backend ? cc.backend.media : ({})
                    onCmd: function (c) {
                        if (cc.backend)
                            cc.backend.mediaCmd(c);
                    }
                }

                Row {
                    id: powerRow
                    anchors.top: media.bottom
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    PowerButton {
                        pal: cc.pal
                        glyph: "\u{F033E}"
                        label: "Bloquear"
                        onTriggered: cc.act("lock")
                    }
                    PowerButton {
                        pal: cc.pal
                        glyph: "\u{F04B2}"
                        label: "Suspender"
                        onTriggered: cc.act("suspend")
                    }
                    PowerButton {
                        pal: cc.pal
                        glyph: "\u{F0709}"
                        label: "Reiniciar"
                        confirm: true
                        onTriggered: cc.act("reboot")
                    }
                    PowerButton {
                        pal: cc.pal
                        glyph: "\u{F0425}"
                        label: "Apagar"
                        confirm: true
                        onTriggered: cc.act("poweroff")
                    }
                }
            }
        }
    }

    WifiPanel {
        width: cc.width
        height: cc.height
        x: cc.sub === "wifi" ? 0 : cc.width
        visible: x < cc.width - 1
        pal: cc.pal
        backend: cc.backend
        live: cc.sub === "wifi" && cc.live
        onBack: cc.sub = ""
        onAct: function (n) {
            cc.act(n);
        }
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
    }

    BtPanel {
        width: cc.width
        height: cc.height
        x: cc.sub === "bt" ? 0 : cc.width
        visible: x < cc.width - 1
        pal: cc.pal
        backend: cc.backend
        live: cc.sub === "bt" && cc.live
        onBack: cc.sub = ""
        onAct: function (n) {
            cc.act(n);
        }
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
    }

    SkinPanel {
        width: cc.width
        height: cc.height
        x: cc.sub === "skin" ? 0 : cc.width
        visible: x < cc.width - 1
        pal: cc.pal
        backend: cc.backend
        onBack: cc.sub = ""
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
    }
}
