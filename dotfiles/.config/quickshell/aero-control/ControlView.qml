import QtQuick
import "Lang.js" as L
import "Tint.js" as Tint

Item {
    id: v
    property var pal
    property var api
    property string page: "look"
    property string keyQuery: ""
    readonly property var st: api ? api.st : ({})
    readonly property var set: st.settings || ({})
    readonly property var feat: st.features || ({ profiles: true, lang: true, updates: true })
    readonly property var pages: [
        { id: "look", glyph: "\u{F03D8}", label: L.t("Apariencia") },
        { id: "fx", glyph: "\u{F0BFE}", label: L.t("Efectos") },
        { id: "desk", glyph: "\u{F0A1F}", label: L.t("Escritorio y dock") },
        { id: "media", glyph: "\u{F057E}", label: L.t("Sonido y pantallas") },
        { id: "region", glyph: "\u{F01E7}", label: L.t("Idioma y región") },
        { id: "perf", glyph: "\u{F04C5}", label: L.t("Rendimiento") },
        { id: "keys", glyph: "\u{F030C}", label: L.t("Atajos") },
        { id: "system", glyph: "\u{F0493}", label: L.t("Sistema") }
    ]
    readonly property var skins: [
        { id: "iphone", label: "iPhone" }, { id: "flip", label: "Flip" }, { id: "aqua", label: "Aqua" }, { id: "visor", label: "Visor" },
        { id: "slider", label: "Slider" }, { id: "holo", label: "Holo" }, { id: "pda", label: "PDA" }, { id: "orbit", label: "Orbit" }
    ]

    function flag(k) {
        return set[k] !== false
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: v.pal.btn0 === "#ffffff" ? "#eaf3fc" : "#0f1c38" }
            GradientStop { position: 1.0; color: v.pal.btn0 === "#ffffff" ? "#cfe2f6" : "#070d1c" }
        }
    }

    Rectangle {
        id: side
        width: 238
        height: parent.height
        gradient: Gradient {
            GradientStop { position: 0.0; color: v.pal.shell1 }
            GradientStop { position: 0.6; color: v.pal.shell3 }
            GradientStop { position: 1.0; color: v.pal.shell4 }
        }
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Qt.rgba(1, 1, 1, 0.35)
        }
        Rectangle {
            width: parent.width
            height: 120
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.28) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
        }

        Column {
            x: 18
            y: 22
            spacing: 2
            Text {
                text: "◢ HYPER·AERO"
                font.family: "Michroma"
                font.pixelSize: 15
                color: "#ffffff"
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.3)
            }
            Text {
                text: L.t("Panel de control")
                font.family: "Exo 2"
                font.weight: Font.DemiBold
                font.pixelSize: 13
                color: Qt.rgba(1, 1, 1, 0.8)
            }
        }

        Column {
            y: 88
            x: 10
            width: parent.width - 20
            spacing: 4
            Repeater {
                model: v.pages.filter(function(p) { return p.id !== "perf" || v.feat.profiles !== false })
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool on: v.page === modelData.id
                    width: parent.width
                    height: 40
                    radius: 10
                    color: on ? Qt.rgba(1, 1, 1, 0.26) : (navArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
                    border.width: on ? 1 : 0
                    border.color: Qt.rgba(1, 1, 1, 0.55)
                    Row {
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Text {
                            width: 22
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData.glyph
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            color: "#ffffff"
                        }
                        Text {
                            text: modelData.label
                            font.family: "Exo 2"
                            font.weight: on ? Font.Bold : Font.DemiBold
                            font.pixelSize: 14
                            color: "#ffffff"
                        }
                    }
                    MouseArea {
                        id: navArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            v.page = modelData.id
                            scroll.contentY = 0
                        }
                    }
                }
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            x: 18
            text: v.st.version ? "v" + v.st.version : ""
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            color: Qt.rgba(1, 1, 1, 0.6)
        }
    }

    Flickable {
        id: scroll
        anchors.left: side.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentWidth: width
        contentHeight: body.implicitHeight + 60
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: body
            x: 34
            y: 26
            width: scroll.width - 68
            spacing: 10

            Text {
                text: v.pages.filter(function(p) { return p.id === v.page })[0].label
                font.family: "Exo 2"
                font.weight: Font.Bold
                font.pixelSize: 26
                color: v.pal.ink
            }

            Loader {
                width: parent.width
                sourceComponent: v.page === "look" ? lookPage : v.page === "fx" ? fxPage : v.page === "desk" ? deskPage
                    : v.page === "media" ? mediaPage : v.page === "region" ? regionPage : v.page === "perf" ? perfPage
                    : v.page === "keys" ? keysPage : systemPage
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.horizontalCenter: scroll.horizontalCenter
        width: toastText.implicitWidth + 32
        height: 36
        radius: 18
        color: v.pal.tray1
        border.width: 1
        border.color: v.pal.select
        opacity: v.api && v.api.toast.length ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Text {
            id: toastText
            anchors.centerIn: parent
            text: v.api ? v.api.toast : ""
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 13
            color: v.pal.ink
        }
    }

    Component {
        id: lookPage
        Column {
            width: body.width
            spacing: 10
            Section { pal: v.pal; text: L.t("COLOR DE ACENTO") }
            Row {
                spacing: 12
                Repeater {
                    model: ["blue", "red", "green", "black"]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: v.st.accent === modelData
                        width: 54
                        height: 54
                        radius: 27
                        border.width: on ? 3 : 1
                        border.color: on ? v.pal.select : "#ccffffff"
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Tint.SWATCH[modelData][0] }
                            GradientStop { position: 0.55; color: Tint.SWATCH[modelData][1] }
                            GradientStop { position: 1.0; color: Tint.SWATCH[modelData][2] }
                        }
                        Rectangle {
                            x: 8; y: 3
                            width: parent.width - 16
                            height: parent.height * 0.42
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.45)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: v.api.exec(["night-deck.py", "accent", modelData], true)
                        }
                    }
                }
                Pill { pal: v.pal; glyph: "\u{F03D8}"; text: L.t("Más temas…"); anchors.verticalCenter: parent.verticalCenter; onClicked: v.api.exec(["carousel.sh"]) }
            }
            Section { pal: v.pal; text: L.t("MODO") }
            Row {
                spacing: 8
                Pill { pal: v.pal; glyph: "\u{F0599}"; text: L.t("Día"); on: v.st.manual && v.st.mode === "day"; onClicked: v.api.exec(["night-deck.py", "day"], true) }
                Pill { pal: v.pal; glyph: "\u{F0594}"; text: L.t("Noche"); on: v.st.manual && v.st.mode === "night"; onClicked: v.api.exec(["night-deck.py", "night"], true) }
                Pill { pal: v.pal; glyph: "\u{F0D3E}"; text: L.t("Automático"); on: !v.st.manual; onClicked: v.api.exec(["night-deck.py", "auto"], true) }
            }
            Section { pal: v.pal; text: L.t("PIEL DEL TELÉFONO") }
            Flow {
                width: parent.width
                spacing: 8
                Repeater {
                    model: v.skins
                    delegate: Pill {
                        required property var modelData
                        pal: v.pal
                        text: modelData.label
                        on: v.st.skin === modelData.id
                        onClicked: v.api.exec(["aero-control.py", "skin", modelData.id], true)
                    }
                }
            }
            Section { pal: v.pal; text: L.t("TEMAS PROPIOS") }
            Row2 {
                pal: v.pal
                glyph: "\u{F08B5}"
                title: L.t("Estudio de temas")
                sub: L.t("Elegí cualquier color y convertí tus imágenes en fondos animados.")
                Pill { pal: v.pal; text: L.t("Abrir"); primary: true; onClicked: v.api.exec(["studio.sh"]) }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F0193}"
                title: L.t("Compartir temas")
                sub: L.t("Exportá tus temas como archivo .aerotheme o importá los que te pasen.")
                Pill { pal: v.pal; text: L.t("Exportar"); onClicked: v.api.exec(["aero-theme.py", "export-all"], true) }
                Pill { pal: v.pal; text: L.t("Importar"); onClicked: v.api.exec(["aero-theme.py", "import-found"], true) }
            }
        }
    }

    Component {
        id: fxPage
        Column {
            width: body.width
            spacing: 10
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                visible: v.feat.profiles !== false && v.st.profile === "ligero"
                text: L.t("Estás en el perfil Ligero: los bordes que reaccionan a la música y el fondo con el clima están pausados para ahorrar recursos.")
                font.family: "Exo 2"
                font.pixelSize: 13
                color: v.pal.warn
            }
            Repeater {
                model: [
                    { k: "fx.glow", g: "\u{F075A}", t: L.t("Bordes que reaccionan a la música"), s: L.t("La ventana activa brilla y ondula al ritmo de lo que suena.") },
                    { k: "fx.ripple", g: "\u{F058C}", t: L.t("Aero Ripple"), s: L.t("Ondas de agua alrededor del cursor al hacer clic.") },
                    { k: "fx.peek", g: "\u{F0208}", t: L.t("Aero Peek"), s: L.t("Pasá el mouse por la esquina inferior derecha (o mantené SUPER + ,) para ver el escritorio a través de las ventanas. Clic en la esquina: mostrar escritorio.") },
                    { k: "fx.shake", g: "\u{F0A33}", t: L.t("Aero Shake"), s: L.t("Agarrá una ventana con SUPER + clic y sacudila para minimizar las demás. Sacudila otra vez para traerlas de vuelta.") },
                    { k: "fx.weather", g: "\u{F0596}", t: L.t("Fondo con el clima"), s: L.t("Lluvia, nieve, niebla o tormenta sobre el fondo según el clima real de tu ciudad.") }
                ]
                delegate: Row2 {
                    required property var modelData
                    pal: v.pal
                    glyph: modelData.g
                    title: modelData.t
                    sub: modelData.s
                    Switch { pal: v.pal; on: v.flag(modelData.k); onToggled: function(val) { v.api.setting(modelData.k, val) } }
                }
            }
            Section { pal: v.pal; text: L.t("ATAJOS DE LOS EFECTOS") }
            Row2 { pal: v.pal; glyph: "\u{F0A25}"; title: L.t("Menú radial"); sub: L.t("SUPER + Z o SUPER + clic central: apps, capturas, música, Bluetooth y ajustes alrededor del cursor.") }
            Row2 { pal: v.pal; glyph: "\u{F0E06}"; title: "Flip 3D"; sub: L.t("SUPER + ALT + TAB o SUPER + SHIFT + TAB: tus ventanas apiladas en 3D. Tab para pasar, Enter para abrir.") }
        }
    }

    Component {
        id: deskPage
        Column {
            width: body.width
            spacing: 10
            Row2 {
                pal: v.pal
                glyph: "\u{F03EB}"
                title: L.t("Editar widgets")
                sub: L.t("Agregá, mové y cambiá el tamaño de los widgets de la pantalla donde está el mouse (SUPER + ALT + D).")
                Pill { pal: v.pal; text: L.t("Editar"); primary: true; onClicked: v.api.raw(["qs", "-c", "aero-desk", "ipc", "call", "desk", "edit"]) }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F0209}"
                title: L.t("Mostrar u ocultar widgets")
                sub: "SUPER + D"
                Pill { pal: v.pal; text: L.t("Alternar"); onClicked: v.api.raw(["qs", "-c", "aero-desk", "ipc", "call", "desk", "toggle"]) }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F003B}"
                title: L.t("Dock")
                sub: L.t("Anclá tus apps: mantené presionada una app en NEXUS y arrastrala al dock.")
                Pill { pal: v.pal; text: L.t("Editar el dock"); onClicked: v.api.exec(["phone.sh", "dock"]) }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F0387}"
                title: L.t("Letras palabra por palabra")
                sub: L.t("El widget LYRICS ilumina cada palabra mientras suena.")
                Switch { pal: v.pal; on: v.flag("lyrics.words"); onToggled: function(val) { v.api.setting("lyrics.words", val) } }
            }
        }
    }

    Component {
        id: mediaPage
        Column {
            width: body.width
            spacing: 10
            Row2 {
                pal: v.pal
                glyph: "\u{F057E}"
                title: L.t("Audio")
                sub: L.t("Salida y entrada, volumen por dispositivo y por app.")
                Pill { pal: v.pal; text: L.t("Abrir"); primary: true; onClicked: v.api.exec(["phone.sh", "audio"]) }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F0379}"
                title: L.t("Pantallas")
                sub: L.t("Duplicar, extender, acomodar y el tamaño de cada pantalla (SUPER + P).")
                Pill { pal: v.pal; text: L.t("Abrir"); primary: true; onClicked: v.api.exec(["displays.sh", "show"]) }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F0335}"
                title: L.t("Luz cálida")
                sub: L.t("Filtro de luz azul (SUPER + SHIFT + T).")
                Pill { pal: v.pal; text: L.t("Alternar"); onClicked: v.api.exec(["night-deck.py", "warm", "toggle"]) }
            }
        }
    }

    Component {
        id: regionPage
        Column {
            width: body.width
            spacing: 10
            Section { pal: v.pal; text: L.t("IDIOMA"); visible: v.feat.lang !== false }
            Row {
                visible: v.feat.lang !== false
                spacing: 8
                Pill { pal: v.pal; text: "Español"; on: v.st.lang === "es"; onClicked: v.api.exec(["aero-lang", "es"], true) }
                Pill { pal: v.pal; text: "English"; on: v.st.lang === "en"; onClicked: v.api.exec(["aero-lang", "en"], true) }
            }
            Section { pal: v.pal; text: L.t("UBICACIÓN (DÍA / NOCHE)") }
            Row {
                spacing: 8
                Field { id: lat; pal: v.pal; width: 120; hint: L.t("Latitud"); text: v.st.lat !== undefined && v.st.lat !== null ? String(v.st.lat) : "" }
                Field { id: lon; pal: v.pal; width: 120; hint: L.t("Longitud"); text: v.st.lon !== undefined && v.st.lon !== null ? String(v.st.lon) : "" }
                Pill { pal: v.pal; text: L.t("Guardar"); primary: true; onClicked: v.api.exec(["aero-control.py", "location", lat.text, lon.text], true) }
                Pill { pal: v.pal; glyph: "\u{F01A4}"; text: L.t("Detectar"); onClicked: v.api.detect(function(d) { lat.text = String(d.lat); lon.text = String(d.lon); if (!city.text.length) city.text = d.city }) }
            }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: L.t("Sur y oeste son negativos. «Detectar» consulta ipapi.co una sola vez.")
                font.family: "Exo 2"
                font.pixelSize: 12
                color: v.pal.muted
            }
            Section { pal: v.pal; text: L.t("CIUDAD DEL CLIMA") }
            Row {
                spacing: 8
                Field { id: city; pal: v.pal; width: 260; hint: L.t("Vacío: la adivina wttr.in"); text: v.st.city || "" }
                Pill { pal: v.pal; text: L.t("Guardar"); primary: true; onClicked: v.api.exec(["aero-control.py", "city", city.text], true) }
            }
        }
    }

    Component {
        id: perfPage
        Column {
            width: body.width
            spacing: 10
            Section { pal: v.pal; text: L.t("PERFIL") }
            Row {
                spacing: 8
                Pill { pal: v.pal; text: L.t("Completo"); on: v.st.profile === "completo"; onClicked: v.api.exec(["aero-profile", "completo"], true) }
                Pill { pal: v.pal; text: L.t("Equilibrado"); on: v.st.profile === "equilibrado"; onClicked: v.api.exec(["aero-profile", "equilibrado"], true) }
                Pill { pal: v.pal; text: L.t("Ligero"); on: v.st.profile === "ligero"; onClicked: v.api.exec(["aero-profile", "ligero"], true) }
            }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: L.t("Los perfiles solo cambian efectos visuales; no tocan la energía ni la CPU, así que funcionan junto con power-profiles-daemon, TLP o tuned.")
                font.family: "Exo 2"
                font.pixelSize: 12
                color: v.pal.muted
            }
            Section { pal: v.pal; text: L.t("AUTOMÁTICO") }
            Row2 {
                pal: v.pal
                glyph: "\u{F0297}"
                title: L.t("Modo juego")
                sub: L.t("Cambia a Ligero mientras un juego está en pantalla completa y vuelve a tu perfil al salir.")
                Switch { pal: v.pal; on: v.flag("auto.game"); onToggled: function(val) { v.api.setting("auto.game", val) } }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F0079}"
                title: L.t("Ahorro con batería")
                sub: L.t("Cambia a Ligero al desconectar el cargador y vuelve a tu perfil al conectarlo.")
                Switch { pal: v.pal; on: v.set["auto.battery"] === true; onToggled: function(val) { v.api.setting("auto.battery", val) } }
            }
        }
    }

    Component {
        id: keysPage
        Column {
            width: body.width
            spacing: 10
            Row {
                spacing: 8
                Field { id: q; pal: v.pal; width: 300; hint: L.t("Buscar un atajo…"); onTextChanged: v.keyQuery = text.toLowerCase() }
                Pill { pal: v.pal; glyph: "\u{F03EB}"; text: L.t("Mis atajos (user.lua)"); onClicked: v.api.raw(["kitty", "--class", "aero-float", "-e", "sh", "-c", "${EDITOR:-nano} \"$HOME/.config/hypr/user.lua\""]) }
            }
            Repeater {
                model: (v.st.keys || []).filter(function(k) { return !v.keyQuery.length || (k.keys + " " + k.what).toLowerCase().indexOf(v.keyQuery) >= 0 })
                delegate: Rectangle {
                    required property var modelData
                    width: parent.width
                    height: 36
                    radius: 9
                    color: v.pal.card1
                    border.width: 1
                    border.color: v.pal.sep
                    Text {
                        x: 14
                        width: 240
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.keys
                        elide: Text.ElideRight
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 12
                        color: v.pal.accent
                    }
                    Text {
                        x: 264
                        width: parent.width - 278
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.what
                        elide: Text.ElideRight
                        font.family: "Exo 2"
                        font.pixelSize: 13
                        color: v.pal.ink
                    }
                }
            }
        }
    }

    Component {
        id: systemPage
        Column {
            width: body.width
            spacing: 10
            Row2 {
                pal: v.pal
                visible: v.feat.updates !== false
                glyph: "\u{F06B0}"
                title: L.t("Actualizaciones")
                sub: !v.st.update || !v.st.update.latest ? L.f("Tenés la versión %1.", v.st.version || "?")
                    : (v.st.update.newer ? L.f("Hay una versión nueva: %1 (tenés %2).", v.st.update.latest, v.st.version) : L.f("Estás al día: %1.", v.st.version))
                Pill { pal: v.pal; text: L.t("Buscar"); onClicked: v.api.exec(["aero-update", "check"], true) }
                Pill { pal: v.pal; text: L.t("Actualizar"); primary: true; visible: !!(v.st.update && v.st.update.newer); onClicked: v.api.raw(["kitty", "--class", "aero-float", "--hold", "-e", v.api.scripts + "/aero-update", "install"]) }
            }
            Row2 {
                pal: v.pal
                visible: v.feat.updates !== false
                glyph: "\u{F0450}"
                title: L.t("Buscar actualizaciones al iniciar")
                sub: L.t("Una vez al día consulta GitHub para avisarte si hay una versión nueva.")
                Switch { pal: v.pal; on: v.flag("update.check"); onToggled: function(val) { v.api.setting("update.check", val) } }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F04D9}"
                title: L.t("Diagnóstico")
                sub: L.t("Revisa Hyprland, tus pantallas, el inicio de sesión y los servicios, y arma un reporte para pegar en un issue.")
                Pill { pal: v.pal; text: L.t("Ejecutar"); primary: true; onClicked: v.api.raw(["kitty", "--class", "aero-float", "--hold", "-e", v.api.scripts + "/aero-doctor"]) }
            }
            Row2 {
                pal: v.pal
                glyph: "\u{F0A1F}"
                title: L.t("Centro de bienvenida")
                sub: L.t("El recorrido del primer inicio: idioma, tema, ubicación y atajos.")
                Pill { pal: v.pal; text: L.t("Abrir"); onClicked: v.api.welcome() }
            }
        }
    }
}
