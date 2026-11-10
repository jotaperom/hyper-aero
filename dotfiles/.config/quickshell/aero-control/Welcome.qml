import QtQuick
import "Lang.js" as L
import "Tint.js" as Tint

Item {
    id: w
    property var pal
    property var api
    property int step: 0
    readonly property var st: api ? api.st : ({})
    readonly property int steps: 5
    signal finished()

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: w.pal.shell0 }
            GradientStop { position: 0.55; color: w.pal.shell2 }
            GradientStop { position: 1.0; color: w.pal.shell4 }
        }
    }

    Repeater {
        model: 14
        delegate: Rectangle {
            required property int index
            readonly property real s: 18 + (index * 37) % 70
            x: (index * 173) % Math.max(1, w.width)
            y: w.height - ((index * 97 + bob.t * (40 + index * 6)) % (w.height + 120))
            width: s
            height: s
            radius: s / 2
            color: Qt.rgba(1, 1, 1, 0.06)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.35)
            Rectangle {
                x: parent.width * 0.2
                y: parent.height * 0.12
                width: parent.width * 0.35
                height: width * 0.6
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.5)
            }
        }
    }

    Item {
        id: bob
        property real t: 0
        NumberAnimation on t {
            from: 0
            to: 1000
            duration: 1000000
            loops: Animation.Infinite
            running: w.visible
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 760)
        height: Math.min(parent.height - 80, 500)
        radius: 22
        color: w.pal.tray0
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.9)
        Rectangle {
            x: 2
            y: 2
            width: parent.width - 4
            height: 90
            radius: 20
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.45) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
        }

        Row {
            anchors.top: parent.top
            anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Repeater {
                model: w.steps
                delegate: Rectangle {
                    required property int index
                    width: index === w.step ? 26 : 9
                    height: 9
                    radius: 4.5
                    color: index <= w.step ? w.pal.select : w.pal.track
                    Behavior on width { NumberAnimation { duration: 200 } }
                }
            }
        }

        Item {
            id: pageArea
            anchors.fill: parent
            anchors.margins: 40
            anchors.topMargin: 50
            anchors.bottomMargin: 76

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 14
                visible: w.step === 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "◢ HYPER·AERO"
                    font.family: "Michroma"
                    font.pixelSize: 34
                    color: w.pal.accent
                    style: Text.Raised
                    styleColor: Qt.rgba(1, 1, 1, 0.6)
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: L.t("¡Bienvenido! Configuremos tu escritorio en un minuto.")
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 20
                    color: w.pal.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !w.st.features || w.st.features.lang !== false
                    text: L.t("Idioma / Language")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: w.pal.muted
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !w.st.features || w.st.features.lang !== false
                    spacing: 10
                    Pill { pal: w.pal; text: "Español"; on: w.st.lang === "es"; onClicked: w.api.exec(["aero-lang", "es"], true) }
                    Pill { pal: w.pal; text: "English"; on: w.st.lang === "en"; onClicked: w.api.exec(["aero-lang", "en"], true) }
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 16
                visible: w.step === 1
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: L.t("Elegí tu color")
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 22
                    color: w.pal.ink
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 18
                    Repeater {
                        model: ["blue", "red", "green", "black"]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool on: w.st.accent === modelData
                            width: 72
                            height: 72
                            radius: 36
                            border.width: on ? 3 : 1
                            border.color: on ? w.pal.select : "#ccffffff"
                            scale: on ? 1.08 : 1
                            Behavior on scale { NumberAnimation { duration: 160 } }
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Tint.SWATCH[modelData][0] }
                                GradientStop { position: 0.55; color: Tint.SWATCH[modelData][1] }
                                GradientStop { position: 1.0; color: Tint.SWATCH[modelData][2] }
                            }
                            Rectangle {
                                x: 10; y: 4
                                width: parent.width - 20
                                height: parent.height * 0.42
                                radius: height / 2
                                color: Qt.rgba(1, 1, 1, 0.45)
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: w.api.exec(["night-deck.py", "accent", modelData], true)
                            }
                        }
                    }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Pill { pal: w.pal; glyph: "\u{F0599}"; text: L.t("Día"); on: w.st.manual && w.st.mode === "day"; onClicked: w.api.exec(["night-deck.py", "day"], true) }
                    Pill { pal: w.pal; glyph: "\u{F0594}"; text: L.t("Noche"); on: w.st.manual && w.st.mode === "night"; onClicked: w.api.exec(["night-deck.py", "night"], true) }
                    Pill { pal: w.pal; glyph: "\u{F0D3E}"; text: L.t("Automático"); on: !w.st.manual; onClicked: w.api.exec(["night-deck.py", "auto"], true) }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: L.t("Automático sigue el amanecer y el atardecer de tu ciudad.")
                    font.family: "Exo 2"
                    font.pixelSize: 13
                    color: w.pal.muted
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 14
                visible: w.step === 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: L.t("¿Dónde estás?")
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 22
                    color: w.pal.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: L.t("Para el ciclo día / noche y el clima. Solo se guarda en tu compu.")
                    font.family: "Exo 2"
                    font.pixelSize: 13
                    color: w.pal.muted
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Field { id: lat; pal: w.pal; width: 120; hint: L.t("Latitud"); text: w.st.lat !== undefined && w.st.lat !== null ? String(w.st.lat) : "" }
                    Field { id: lon; pal: w.pal; width: 120; hint: L.t("Longitud"); text: w.st.lon !== undefined && w.st.lon !== null ? String(w.st.lon) : "" }
                    Pill { pal: w.pal; glyph: "\u{F01A4}"; text: L.t("Detectar"); onClicked: w.api.detect(function(d) { lat.text = String(d.lat); lon.text = String(d.lon); city.text = d.city }) }
                }
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    Field { id: city; pal: w.pal; width: 256; hint: L.t("Ciudad del clima"); text: w.st.city || "" }
                    Pill {
                        pal: w.pal
                        text: L.t("Guardar")
                        primary: true
                        onClicked: {
                            if (lat.text.length && lon.text.length) w.api.exec(["aero-control.py", "location", lat.text, lon.text], false)
                            w.api.exec(["aero-control.py", "city", city.text], true)
                            w.step = 3
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 10
                visible: w.step === 3
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: L.t("Los atajos que vas a usar siempre")
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 22
                    color: w.pal.ink
                }
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    columnSpacing: 14
                    rowSpacing: 10
                    Repeater {
                        model: [
                            ["SUPER + R", L.t("Apps (teléfono NEXUS)")],
                            ["SUPER + X", L.t("Controles rápidos")],
                            ["SUPER + Z", L.t("Menú radial")],
                            ["SUPER + O", L.t("Panel de control")],
                            ["SUPER + G", L.t("Temas")],
                            ["SUPER + ALT + D", L.t("Editar widgets")],
                            ["SUPER + P", L.t("Pantallas")],
                            ["SUPER + F1", L.t("Todos los atajos")]
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 300
                            height: 40
                            radius: 10
                            color: w.pal.card1
                            border.width: 1
                            border.color: w.pal.sep
                            Text {
                                x: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData[0]
                                font.family: "JetBrainsMono Nerd Font"
                                font.weight: Font.Bold
                                font.pixelSize: 12
                                color: w.pal.accent
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData[1]
                                font.family: "Exo 2"
                                font.pixelSize: 13
                                color: w.pal.ink
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: 14
                visible: w.step === 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "\u{F012C}"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 56
                    color: w.pal.ok
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: L.t("¡Todo listo!")
                    font.family: "Exo 2"
                    font.weight: Font.Bold
                    font.pixelSize: 24
                    color: w.pal.ink
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: L.t("Todo esto se puede cambiar después en el Panel de control (SUPER + O).")
                    font.family: "Exo 2"
                    font.pixelSize: 14
                    color: w.pal.muted
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 22
            anchors.right: parent.right
            anchors.rightMargin: 28
            spacing: 10
            Pill { pal: w.pal; text: L.t("Atrás"); visible: w.step > 0 && w.step < w.steps - 1; onClicked: w.step -= 1 }
            Pill {
                pal: w.pal
                primary: true
                text: w.step === w.steps - 1 ? L.t("Empezar") : L.t("Siguiente")
                onClicked: {
                    if (w.step < w.steps - 1) w.step += 1
                    else w.finished()
                }
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 30
            x: 30
            visible: w.step < w.steps - 1
            text: L.t("Saltar")
            font.family: "Exo 2"
            font.weight: Font.DemiBold
            font.pixelSize: 13
            color: w.pal.muted
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: w.finished()
            }
        }
    }
}
