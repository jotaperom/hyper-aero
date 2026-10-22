import QtQuick
import "Tint.js" as Tint
import "Pal.js" as Pal
import "Lang.js" as L

Item {
    id: v
    property var api
    property bool open: true
    signal closed()
    readonly property var st: api ? api.st : ({})
    readonly property var ext: st && st.external ? st.external : null
    readonly property var lap: st && st.laptop ? st.laptop : null
    readonly property string mode: ext ? (st.mode || "extend") : "laptop"
    readonly property string busy: api ? api.busy : ""
    readonly property var pal: Pal.make(api ? api.night : false, api ? api.accent : "blue")
    readonly property real extScale: ext ? Number(st.scale || 1) : 1
    readonly property real lapScale: lap ? Number(lap.scale || 1) : 1
    readonly property var modes: [
        { mode: "laptop", title: L.t("Solo laptop"), hint: L.t("Apaga el monitor") },
        { mode: "duplicate", title: L.t("Duplicar"), hint: L.t("Lo mismo en las dos") },
        { mode: "extend", title: L.t("Extender"), hint: L.t("Una pantalla grande") },
        { mode: "external", title: L.t("Solo monitor"), hint: L.t("Apaga la laptop") }
    ]
    readonly property var scales: [1, 1.25, 1.5, 1.75, 2]
    readonly property var sides: [
        { side: "left", text: L.t("Izquierda"), glyph: "\u{F004D}" },
        { side: "above", text: L.t("Arriba"), glyph: "\u{F005D}" },
        { side: "below", text: L.t("Abajo"), glyph: "\u{F0045}" },
        { side: "right", text: L.t("Derecha"), glyph: "\u{F0054}" }
    ]
    focus: true

    function pick(m) {
        if (!ext && m !== "laptop") return
        if (m === mode || busy.length) return
        api.set(["mode", m])
    }

    function dismiss() {
        if (!open) return
        open = false
        closeTimer.restart()
    }

    Timer {
        id: closeTimer
        interval: 190
        onTriggered: v.closed()
    }

    Keys.onPressed: function(e) {
        if (e.key === Qt.Key_Escape) { v.dismiss(); e.accepted = true }
        else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_4) { v.pick(v.modes[e.key - Qt.Key_1].mode); e.accepted = true }
        else if (e.key === Qt.Key_P && ext) {
            var i = 0
            for (var j = 0; j < v.modes.length; j++) if (v.modes[j].mode === v.mode) i = j
            v.pick(v.modes[(i + 1) % v.modes.length].mode)
            e.accepted = true
        }
    }

    Rectangle {
        anchors.fill: parent
        color: v.pal.scrim
        opacity: v.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        MouseArea {
            anchors.fill: parent
            onClicked: v.dismiss()
        }
    }

    Item {
        id: card
        width: Math.min(parent.width - 40, 840)
        height: body.implicitHeight + 44
        anchors.centerIn: parent
        opacity: v.open ? 1 : 0
        scale: v.open ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.leftMargin: 4
            anchors.rightMargin: -4
            anchors.bottomMargin: -10
            radius: 26
            color: v.pal.shadow
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            antialiasing: true
            color: v.api && v.api.night ? "#0b1530" : "#eef4fb"
            opacity: 0.88
        }

        Rectangle {
            anchors.fill: parent
            radius: 24
            antialiasing: true
            border.width: 1
            border.color: v.pal.cardBorder
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: v.pal.card0 }
                GradientStop { position: 0.35; color: v.pal.card1 }
                GradientStop { position: 0.36; color: v.pal.card2 }
                GradientStop { position: 1.0; color: v.pal.card3 }
            }
            Rectangle {
                x: 14; y: 2
                width: parent.width - 28
                height: 60
                radius: 20
                color: v.pal.sheen
                opacity: 0.35
            }
        }

        Column {
            id: body
            x: 24
            y: 22
            width: card.width - 48
            spacing: 18

            Item {
                width: parent.width
                height: 46

                Rectangle {
                    id: badge
                    width: 46
                    height: 46
                    radius: 14
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: v.pal.fill0 }
                        GradientStop { position: 0.5; color: v.pal.fill1 }
                        GradientStop { position: 1.0; color: v.pal.fill2 }
                    }
                    border.width: 1
                    border.color: "#99ffffff"
                    Rectangle {
                        x: 4; y: 2
                        width: parent.width - 8
                        height: parent.height * 0.45
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.35)
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "\u{F037A}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 24
                        color: "#ffffff"
                    }
                }

                Column {
                    anchors.left: badge.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        text: L.t("◢ PANTALLAS")
                        font.family: "Exo 2"
                        font.weight: Font.Black
                        font.pixelSize: 20
                        font.letterSpacing: 1.5
                        color: v.pal.ink
                    }
                    Text {
                        text: v.ext ? L.t("Monitor: ") + v.ext.desc + "  ·  " + v.ext.w + "×" + v.ext.h + (v.st.extra > 0 ? "  ·  +" + v.st.extra + L.t(" más") : "")
                                    : L.t("Solo la pantalla de la laptop")
                        font.family: "Exo 2"
                        font.pixelSize: 12
                        color: v.pal.muted
                        width: card.width - 260
                        elide: Text.ElideRight
                    }
                }

                Pill {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    pal: v.pal
                    glyph: "\u{F0156}"
                    onClicked: v.dismiss()
                }
            }

            Row {
                id: cards
                spacing: 14
                readonly property real cw: (body.width - spacing * 3) / 4
                Repeater {
                    model: v.modes
                    ModeCard {
                        pal: v.pal
                        width: cards.cw
                        mode: modelData.mode
                        title: modelData.title
                        hint: modelData.hint
                        key: String(index + 1)
                        chosen: v.mode === modelData.mode
                        available: !!v.ext || modelData.mode === "laptop"
                        pending: v.busy === "mode:" + modelData.mode
                        onPicked: v.pick(modelData.mode)
                    }
                }
            }

            Rectangle {
                visible: !v.ext
                width: parent.width
                height: 64
                radius: 14
                color: v.pal.field
                border.width: 1
                border.color: v.pal.fieldBorder
                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{F0841}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        color: v.pal.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: L.t("Conectá un monitor por HDMI o USB-C: lo detecto solo y aparece este panel.")
                        font.family: "Exo 2"
                        font.pixelSize: 13
                        color: v.pal.ink
                    }
                }
            }

            Column {
                id: arrange
                visible: !!v.ext && v.mode === "extend"
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 20
                    Text {
                        text: L.t("POSICIÓN FÍSICA")
                        font.family: "Exo 2"
                        font.weight: Font.Black
                        font.pixelSize: 12
                        font.letterSpacing: 1.2
                        color: v.pal.accent
                    }
                    Text {
                        anchors.right: parent.right
                        text: L.t("Arrastrá la pantalla 2 hasta donde está tu laptop en el escritorio")
                        font.family: "Exo 2"
                        font.pixelSize: 12
                        color: v.pal.muted
                    }
                }

                Arrange {
                    id: board
                    width: parent.width
                    height: 230
                    pal: v.pal
                    ew: v.ext ? v.ext.w / v.extScale : 1920
                    eh: v.ext ? v.ext.h / v.extScale : 1080
                    lw: v.lap ? v.lap.w / v.lapScale : 1536
                    lh: v.lap ? v.lap.h / v.lapScale : 864
                    side: v.st.side || "right"
                    offset: v.st.offset === undefined ? 0.5 : Number(v.st.offset)
                    extName: v.ext ? v.ext.name : ""
                    lapName: "Laptop"
                    hudOnLaptop: v.st.hud === "laptop"
                    onMoved: function(s, o) { v.api.set(["side", s, "offset", String(Math.round(o * 1000) / 1000)]) }
                }

                Row {
                    spacing: 8
                    Repeater {
                        model: v.sides
                        Pill {
                            pal: v.pal
                            glyph: modelData.glyph
                            text: modelData.text
                            on: board.effSide === modelData.side
                            onClicked: if (board.effSide !== modelData.side) v.api.set(["side", modelData.side, "offset", "0.5"])
                        }
                    }
                }
            }

            Grid {
                visible: (!!v.lap && v.mode !== "external") || (!!v.ext && v.mode !== "laptop")
                columns: 2
                columnSpacing: 18
                rowSpacing: 12
                verticalItemAlignment: Grid.AlignVCenter

                Text {
                    visible: !!v.lap && v.mode !== "external"
                    text: L.t("TAMAÑO EN LA LAPTOP")
                    font.family: "Exo 2"
                    font.weight: Font.Black
                    font.pixelSize: 12
                    font.letterSpacing: 1.2
                    color: v.pal.accent
                }
                Row {
                    visible: !!v.lap && v.mode !== "external"
                    spacing: 8
                    Repeater {
                        model: v.scales
                        Pill {
                            pal: v.pal
                            text: Math.round(modelData * 100) + "%"
                            on: Math.abs(v.lapScale - modelData) < 0.01
                            onClicked: if (!on) v.api.set(["lapscale", String(modelData)])
                        }
                    }
                }

                Text {
                    visible: !!v.ext && v.mode !== "laptop"
                    text: L.t("TAMAÑO EN EL MONITOR")
                    font.family: "Exo 2"
                    font.weight: Font.Black
                    font.pixelSize: 12
                    font.letterSpacing: 1.2
                    color: v.pal.accent
                }
                Row {
                    visible: !!v.ext && v.mode !== "laptop"
                    spacing: 8
                    Repeater {
                        model: v.scales
                        Pill {
                            pal: v.pal
                            text: Math.round(modelData * 100) + "%"
                            on: Math.abs(v.extScale - modelData) < 0.01
                            onClicked: if (!on) v.api.set(["scale", String(modelData)])
                        }
                    }
                }

                Text {
                    visible: v.mode === "extend"
                    text: L.t("TELEMETRY EN")
                    font.family: "Exo 2"
                    font.weight: Font.Black
                    font.pixelSize: 12
                    font.letterSpacing: 1.2
                    color: v.pal.accent
                }
                Row {
                    visible: v.mode === "extend"
                    spacing: 8
                    Pill {
                        pal: v.pal
                        glyph: "\u{F0379}"
                        text: "Monitor (1)"
                        on: v.st.hud !== "laptop"
                        onClicked: if (!on) v.api.set(["hud", "primary"])
                    }
                    Pill {
                        pal: v.pal
                        glyph: "\u{F0322}"
                        text: "Laptop (2)"
                        on: v.st.hud === "laptop"
                        onClicked: if (!on) v.api.set(["hud", "laptop"])
                    }
                }
            }

            Item {
                width: parent.width
                height: 18
                Text {
                    text: L.t("1 – 4  elegir modo   ·   P  siguiente   ·   Esc  cerrar")
                    font.family: "Exo 2"
                    font.pixelSize: 11
                    color: v.pal.dim
                }
                Row {
                    anchors.right: parent.right
                    spacing: 8
                    visible: v.busy.length > 0
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        radius: 5
                        color: v.pal.sky
                        SequentialAnimation on opacity {
                            running: v.busy.length > 0
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.25; duration: 420 }
                            NumberAnimation { from: 0.25; to: 1; duration: 420 }
                        }
                    }
                    Text {
                        text: L.t("Acomodando pantallas…")
                        font.family: "Exo 2"
                        font.weight: Font.Bold
                        font.pixelSize: 11
                        color: v.pal.accent
                    }
                }
                Text {
                    anchors.right: parent.right
                    visible: v.busy.length === 0 && !!v.api && v.api.error.length > 0
                    text: v.api ? v.api.error : ""
                    font.family: "Exo 2"
                    font.pixelSize: 11
                    color: v.pal.bad
                }
            }
        }
    }
}
