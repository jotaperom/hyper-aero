import QtQuick
import "Tint.js" as Tint
import "Pal.js" as Pal
import "Lang.js" as L

Item {
    id: v
    property var api
    property string work: api ? api.accent : "blue"
    property string wall: api ? api.wallpaper : "auto"
    property int tab: 0
    property bool nightView: api ? api.mode === "night" : false
    property string themeName: ""
    property var layers: [
        { type: "bubbles", name: L.t("Burbujas Aero"), glyph: "\u{F05E3}", on: true, amount: 0.7, speed: 1 },
        { type: "waves", name: L.t("Ondas de luz"), glyph: "\u{F078D}", on: true, amount: 0.7, speed: 1 },
        { type: "sparkles", name: L.t("Destellos"), glyph: "\u{F0AE2}", on: false, amount: 0.6, speed: 1 },
        { type: "aurora", name: L.t("Aurora"), glyph: "\u{F0674}", on: false, amount: 0.6, speed: 1 },
        { type: "rain", name: L.t("Lluvia en el vidrio"), glyph: "\u{F0596}", on: false, amount: 0.5, speed: 1 },
        { type: "hud", name: L.t("Barrido HUD"), glyph: "\u{F02C1}", on: false, amount: 0.5, speed: 1 },
        { type: "mist", name: L.t("Neblina"), glyph: "\u{F0591}", on: false, amount: 0.6, speed: 1 },
        { type: "snow", name: L.t("Copos"), glyph: "\u{F0717}", on: false, amount: 0.6, speed: 1 },
        { type: "bokeh", name: L.t("Orbes de luz"), glyph: "\u{F0695}", on: false, amount: 0.6, speed: 1 },
        { type: "rays", name: L.t("Rayos de sol"), glyph: "\u{F059A}", on: false, amount: 0.6, speed: 1 },
        { type: "petals", name: L.t("Pétalos"), glyph: "\u{F09F1}", on: false, amount: 0.5, speed: 1 },
        { type: "stars", name: L.t("Estrellas fugaces"), glyph: "\u{F1741}", on: false, amount: 0.6, speed: 1 },
        { type: "caustics", name: L.t("Luz de agua"), glyph: "\u{F058C}", on: false, amount: 0.5, speed: 1 },
        { type: "flare", name: L.t("Destello de lente"), glyph: "\u{F0D72}", on: false, amount: 0.6, speed: 1 },
        { type: "grid", name: L.t("Cuadrícula Y2K"), glyph: "\u{F0758}", on: false, amount: 0.6, speed: 1 }
    ]
    property bool useDraft: false
    readonly property var presetHS: ({ blue: [215, 100], red: [350, 100], green: [162, 72], black: [188, 5] })
    readonly property var presetNames: ({ blue: L.t("AZUL"), red: L.t("ROJO"), green: L.t("VERDE"), black: L.t("NEGRO") })
    readonly property var hs: toHS(work)
    readonly property var pal: Pal.make(nightView, work)
    readonly property color workColor: Tint.color("#3d9be9", work)
    readonly property var selWall: findWall(wall)
    readonly property bool busy: !!(api && api.busy.length)
    readonly property bool hasPreview: !!(api && api.previewDay.length)
    readonly property bool dirty: !!api && (work !== api.accent || wall !== api.wallpaper)
    readonly property string stillDay: selWall ? selWall.day : autoStill(work, false)
    readonly property string stillNight: selWall ? selWall.night : autoStill(work, true)
    readonly property bool drafting: useDraft && !!api && api.image.length > 0
    readonly property string draftName: api && api.image ? api.image.split("/").pop() : ""
    readonly property bool rendering: !!api && api.busy === "render"
    readonly property bool previewing: !!api && api.previewing
    readonly property string shown: drafting ? (hasPreview ? (nightView ? api.previewNight : api.previewDay) : "file://" + api.image) : (nightView ? stillNight : stillDay)

    function draftChanged() {
        if (useDraft && api && api.image.length) autoPreview.restart()
    }

    function autoStill(acc, night) {
        if (!api) return ""
        var key = ["blue", "red", "green", "black"].indexOf(acc) >= 0 ? acc : "blue"
        var a = api.autos && api.autos[key] ? api.autos[key] : null
        if (a && (night ? a.night : a.day)) return night ? a.night : a.day
        return night ? api.autoNight : api.autoDay
    }

    function pickWall(id) {
        useDraft = false
        wall = id
    }

    onWorkChanged: draftChanged()
    onLayersChanged: draftChanged()
    onTabChanged: draftChanged()
    onUseDraftChanged: draftChanged()

    Connections {
        target: v.api
        function onImageChanged() {
            if (v.api.image.length) v.useDraft = true
            v.draftChanged()
        }
    }

    Timer {
        id: autoPreview
        interval: 650
        onTriggered: if (v.api && v.api.image.length) v.api.preview(v.spec())
    }

    function toHS(acc) {
        if (presetHS[acc]) return presetHS[acc]
        var m = /^c-(\d{1,3})-(\d{1,3})$/.exec(acc || "")
        return m ? [parseInt(m[1], 10), parseInt(m[2], 10)] : [215, 100]
    }

    function make(h, s) {
        return "c-" + Math.round(Math.max(0, Math.min(359, h))) + "-" + Math.round(Math.max(0, Math.min(140, s)))
    }

    function nameOf(acc) {
        if (presetNames[acc]) return presetNames[acc]
        var p = toHS(acc)
        return p[1] < 12 ? L.t("GRIS") : "PERSONAL · " + p[0]
    }

    function findWall(id) {
        if (!api || !id || id === "auto") return null
        for (var i = 0; i < api.walls.length; i++) {
            if (api.walls[i].id === id) return api.walls[i]
        }
        return null
    }

    function spec() {
        var out = []
        for (var i = 0; i < layers.length; i++) {
            if (layers[i].on) out.push({ type: layers[i].type, amount: layers[i].amount, speed: layers[i].speed })
        }
        return { image: api ? api.image : "", accent: work, layers: out }
    }

    function setLayer(i, change) {
        var copy = layers.slice()
        copy[i] = Object.assign({}, copy[i], change)
        layers = copy
    }

    function file(p) {
        return p && p.length ? (p.indexOf("file://") === 0 ? p : "file://" + p) : ""
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: v.nightView ? "#0b1530" : "#e9f2fb" }
            GradientStop { position: 1.0; color: v.nightView ? "#050912" : "#c7dbef" }
        }
    }

    Item {
        id: head
        width: parent.width
        height: 64

        Rectangle {
            anchors.bottom: parent.bottom
            x: 22
            width: parent.width - 44
            height: 3
            radius: 1.5
            color: v.pal.track
            visible: v.rendering || v.previewing
            clip: true
            Rectangle {
                height: parent.height
                radius: 1.5
                color: v.workColor
                width: v.rendering ? parent.width * v.api.progress : parent.width * 0.3
                x: v.rendering ? 0 : sweep.p * (parent.width * 1.3) - parent.width * 0.3
                QtObject {
                    id: sweep
                    property real p: 0
                    NumberAnimation on p {
                        running: v.previewing && !v.rendering
                        from: 0
                        to: 1
                        duration: 900
                        loops: Animation.Infinite
                    }
                }
                Behavior on width { enabled: v.rendering; NumberAnimation { duration: 400 } }
            }
        }

        Text {
            x: 26
            anchors.verticalCenter: parent.verticalCenter
            text: L.t("◢ ESTUDIO DE TEMAS")
            font.family: "Michroma"
            font.pixelSize: 17
            font.letterSpacing: 2
            color: v.pal.ink
        }

        Row {
            anchors.centerIn: parent
            spacing: 8
            Repeater {
                model: [["\u{F03D8}", L.t("COLOR")], ["\u{F02E9}", L.t("FONDO")], ["\u{F08B5}", L.t("MIS TEMAS")]]
                delegate: Pill {
                    required property var modelData
                    required property int index
                    pal: v.pal
                    glyph: modelData[0]
                    text: modelData[1]
                    on: v.tab === index
                    primary: v.tab === index
                    onClicked: v.tab = index
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Pill {
                pal: v.pal
                glyph: v.nightView ? "\u{F0594}" : "\u{F05A8}"
                text: v.nightView ? L.t("Noche") : L.t("Día")
                onClicked: v.nightView = !v.nightView
            }
            Pill {
                pal: v.pal
                glyph: "\u{F0156}"
                onClicked: if (v.api) v.api.close()
            }
        }
    }

    Item {
        id: stage
        x: 22
        y: head.height
        width: parent.width * 0.58 - 30
        height: parent.height - head.height - 22

        Rectangle {
            id: frame
            width: parent.width
            height: Math.min(parent.height - 92, width * 9 / 16)
            radius: 18
            clip: true
            color: "#000000"
            border.width: 2
            border.color: v.pal.cardBorder

            Image {
                anchors.fill: parent
                source: v.file(v.shown)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
            }

            Item {
                id: mock
                anchors.fill: parent
                readonly property real k: width / 1536

                Rectangle {
                    x: 14 * mock.k; y: 8 * mock.k
                    width: parent.width - 28 * mock.k
                    height: 40 * mock.k
                    radius: height / 2
                    color: v.pal.card0
                    border.width: 1
                    border.color: v.pal.cardBorder
                    Row {
                        x: 18 * mock.k
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8 * mock.k
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "◢ HYPER·AERO"
                            font.family: "Michroma"
                            font.pixelSize: Math.max(6, 13 * mock.k)
                            color: v.pal.ink
                        }
                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                required property int index
                                anchors.verticalCenter: parent.verticalCenter
                                width: 40 * mock.k
                                height: 24 * mock.k
                                radius: height / 2
                                border.width: 1
                                border.color: index === 1 ? v.pal.select : v.pal.btnBorder
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: index === 1 ? v.pal.fill0 : v.pal.btn0 }
                                    GradientStop { position: 1.0; color: index === 1 ? v.pal.fill2 : v.pal.btn2 }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "0" + (index + 1)
                                    font.family: "Michroma"
                                    font.pixelSize: Math.max(5, 9 * mock.k)
                                    color: index === 1 ? "#ffffff" : v.pal.btnText
                                }
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "13:52"
                        font.family: "Michroma"
                        font.pixelSize: Math.max(7, 16 * mock.k)
                        color: v.pal.ink
                    }
                }

                Rectangle {
                    x: 30 * mock.k
                    y: parent.height - height - 34 * mock.k
                    width: 380 * mock.k
                    height: 210 * mock.k
                    radius: 20 * mock.k
                    border.width: 1
                    border.color: v.pal.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: v.pal.card0 }
                        GradientStop { position: 0.5; color: v.pal.card1 }
                        GradientStop { position: 1.0; color: v.pal.card3 }
                    }
                    Column {
                        x: 18 * mock.k
                        y: 14 * mock.k
                        width: parent.width - 36 * mock.k
                        spacing: 12 * mock.k
                        Text {
                            text: "TELEMETRY"
                            font.family: "Michroma"
                            font.pixelSize: Math.max(6, 12 * mock.k)
                            color: v.pal.ink
                        }
                        Repeater {
                            model: [0.62, 0.34, 0.8]
                            delegate: Rectangle {
                                required property real modelData
                                width: parent.width
                                height: 12 * mock.k
                                radius: height / 2
                                color: v.pal.track
                                Rectangle {
                                    width: parent.width * modelData
                                    height: parent.height
                                    radius: height / 2
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: v.pal.fill0 }
                                        GradientStop { position: 1.0; color: v.pal.fill2 }
                                    }
                                }
                            }
                        }
                        Row {
                            spacing: 10 * mock.k
                            Repeater {
                                model: 3
                                delegate: Rectangle {
                                    required property int index
                                    width: 44 * mock.k
                                    height: 44 * mock.k
                                    radius: width / 2
                                    border.width: 2
                                    border.color: v.pal.btnBorder
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: index === 1 ? v.pal.fill0 : v.pal.btn0 }
                                        GradientStop { position: 1.0; color: index === 1 ? v.pal.fill2 : v.pal.btn2 }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 30 * mock.k
                    y: 80 * mock.k
                    width: 300 * mock.k
                    height: 120 * mock.k
                    radius: 20 * mock.k
                    border.width: 1
                    border.color: v.pal.cardBorder
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: v.pal.shell0 }
                        GradientStop { position: 0.5; color: v.pal.shell2 }
                        GradientStop { position: 1.0; color: v.pal.shell4 }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "21:43"
                        font.family: "Michroma"
                        font.pixelSize: Math.max(8, 38 * mock.k)
                        color: "#ffffff"
                    }
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 12
                anchors.topMargin: mock.k * 56 + 8
                visible: v.drafting
                width: badge.implicitWidth + 24
                height: 26
                radius: 13
                color: "#cc050a14"
                border.width: 1
                border.color: v.pal.select
                Row {
                    id: badge
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8; radius: 4
                        color: v.previewing ? "#ffc04d" : "#4cff7a"
                        SequentialAnimation on opacity {
                            running: v.previewing
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.25; duration: 400 }
                            NumberAnimation { to: 1; duration: 400 }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: v.previewing ? L.t("Actualizando vista previa…") : (v.hasPreview ? L.t("VISTA PREVIA · SIN MOVIMIENTO · ") + (v.nightView ? L.t("NOCHE") : L.t("DÍA")) : L.t("IMAGEN ORIGINAL"))
                        font.family: "Exo 2"
                        font.weight: Font.Bold
                        font.pixelSize: 11
                        color: "#ffffff"
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 64
                visible: v.rendering
                color: "#cc050a14"
                Column {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 8
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width / 2
                            text: L.t("Generando tu fondo animado…")
                            font.family: "Exo 2"
                            font.weight: Font.Bold
                            font.pixelSize: 14
                            color: "#ffffff"
                        }
                        Text {
                            width: parent.width / 2
                            horizontalAlignment: Text.AlignRight
                            text: Math.round((v.api ? v.api.progress : 0) * 100) + "%" + (v.api && v.api.eta.length ? "  ·  " + v.api.eta : "")
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            color: "#ffffff"
                        }
                    }
                    Rectangle {
                        width: parent.width
                        height: 10
                        radius: 5
                        color: Qt.rgba(1, 1, 1, 0.2)
                        Rectangle {
                            width: Math.max(10, parent.width * (v.api ? v.api.progress : 0))
                            height: parent.height
                            radius: 5
                            color: v.workColor
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#99000000"
                visible: v.busy && !v.rendering
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    width: parent.width * 0.6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: v.api && v.api.busy === "render" ? L.t("Generando tu fondo animado…") : v.api && v.api.busy === "preview" ? L.t("Preparando vista previa…") : v.api && v.api.busy === "apply" ? L.t("Aplicando el tema…") : L.t("Un momento…")
                        font.family: "Exo 2"
                        font.weight: Font.Bold
                        font.pixelSize: 18
                        color: "#ffffff"
                    }
                    Rectangle {
                        visible: v.api && v.api.busy === "render"
                        width: parent.width
                        height: 12
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.2)
                        Rectangle {
                            width: parent.width * (v.api ? v.api.progress : 0)
                            height: parent.height
                            radius: 6
                            color: v.workColor
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: v.api && v.api.busy === "render"
                        text: L.f("%1%  ·  podés seguir usando la compu", Math.round((v.api ? v.api.progress : 0) * 100))
                        font.family: "Exo 2"
                        font.pixelSize: 13
                        color: Qt.rgba(1, 1, 1, 0.85)
                    }
                }
            }
        }

        Row {
            anchors.top: frame.bottom
            anchors.topMargin: 16
            spacing: 14

            Rectangle {
                width: 56
                height: 56
                radius: 28
                color: v.workColor
                border.width: 3
                border.color: "#ffffff"
                Rectangle {
                    x: 10; y: 4
                    width: 36; height: 18; radius: 9
                    color: Qt.rgba(1, 1, 1, 0.45)
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    text: v.nameOf(v.work)
                    font.family: "Michroma"
                    font.pixelSize: 14
                    color: v.pal.ink
                }
                Text {
                    text: v.drafting ? L.f("Fondo: nuevo · %1 (sin generar)", v.draftName) : L.f("Fondo: %1", v.selWall ? v.selWall.name : L.t("Original del tema"))
                    font.family: "Exo 2"
                    font.pixelSize: 13
                    color: v.pal.muted
                }
            }
        }

        Pill {
            anchors.right: parent.right
            anchors.top: frame.bottom
            anchors.topMargin: 20
            pal: v.pal
            primary: true
            glyph: "\u{F012C}"
            text: v.drafting ? L.t("Generar y aplicar") : v.dirty ? L.t("Aplicar") : L.t("Aplicado")
            enabled2: (v.dirty || v.drafting) && !v.busy
            onClicked: {
                if (v.drafting) v.api.renderApply(v.spec(), v.work)
                else v.api.apply(v.work, v.wall)
            }
        }
    }

    Rectangle {
        id: side
        x: stage.x + stage.width + 24
        y: head.height
        width: parent.width - x - 22
        height: parent.height - head.height - 22
        radius: 20
        border.width: 1
        border.color: v.pal.cardBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: v.pal.card0 }
            GradientStop { position: 0.5; color: v.pal.card1 }
            GradientStop { position: 1.0; color: v.pal.card3 }
        }
        clip: true

        Flickable {
            anchors.fill: parent
            anchors.margins: 18
            contentHeight: v.tab === 0 ? colorTab.height : v.tab === 1 ? wallTab.height : themeTab.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: colorTab
                visible: v.tab === 0
                width: parent.width
                spacing: 14

                Text { text: L.t("TONO"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Slider {
                    width: parent.width
                    pal: v.pal
                    value: v.hs[0] / 359
                    knob: v.workColor
                    stops: [
                        GradientStop { position: 0.0; color: "#ff3b3b" },
                        GradientStop { position: 0.17; color: "#ffd23b" },
                        GradientStop { position: 0.33; color: "#3bff6a" },
                        GradientStop { position: 0.5; color: "#3bf0ff" },
                        GradientStop { position: 0.67; color: "#3b5bff" },
                        GradientStop { position: 0.83; color: "#d23bff" },
                        GradientStop { position: 1.0; color: "#ff3b3b" }
                    ]
                    onMoved: function(x) { v.work = v.make(x * 359, Math.max(20, v.hs[1])) }
                }

                Text { text: L.t("INTENSIDAD"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Slider {
                    width: parent.width
                    pal: v.pal
                    value: v.hs[1] / 140
                    knob: v.workColor
                    stops: [
                        GradientStop { position: 0.0; color: Tint.color("#3d9be9", v.make(v.hs[0], 0)) },
                        GradientStop { position: 0.5; color: Tint.color("#3d9be9", v.make(v.hs[0], 70)) },
                        GradientStop { position: 1.0; color: Tint.color("#3d9be9", v.make(v.hs[0], 140)) }
                    ]
                    onMoved: function(x) { v.work = v.make(v.hs[0], x * 140) }
                }

                Text { text: L.t("PREDETERMINADOS"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Flow {
                    width: parent.width
                    spacing: 8
                    Repeater {
                        model: ["blue", "red", "green", "black"]
                        delegate: Pill {
                            required property string modelData
                            pal: v.pal
                            text: v.presetNames[modelData].charAt(0) + v.presetNames[modelData].slice(1).toLowerCase()
                            glyph: "●"
                            on: v.work === modelData
                            onClicked: v.work = modelData
                        }
                    }
                }

                Text { text: L.t("SACADOS DEL FONDO"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: v.api ? v.api.suggest : []
                        delegate: Rectangle {
                            required property var modelData
                            width: 46
                            height: 46
                            radius: 23
                            color: modelData.hex
                            border.width: v.work === modelData.accent ? 3 : 2
                            border.color: v.work === modelData.accent ? v.pal.select : "#ffffff"
                            Rectangle { x: 8; y: 3; width: 30; height: 15; radius: 7.5; color: Qt.rgba(1, 1, 1, 0.4) }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: v.work = modelData.accent
                            }
                        }
                    }
                    Pill {
                        pal: v.pal
                        glyph: "\u{F0068}"
                        text: L.t("Analizar fondo")
                        enabled2: !v.busy
                        onClicked: v.api.palette(v.drafting ? v.api.image : v.selWall ? v.selWall.day : v.autoStill(v.work, false))
                    }
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: L.t("Todo el escritorio sigue este color: barra, widgets, teléfono, notificaciones, terminal, bordes y menús.")
                    font.family: "Exo 2"
                    font.pixelSize: 12
                    color: v.pal.muted
                }
            }

            Column {
                id: wallTab
                visible: v.tab === 1
                width: parent.width
                spacing: 12

                Rectangle {
                    visible: v.rendering
                    width: parent.width
                    height: 70
                    radius: 14
                    color: v.pal.hover
                    border.width: 1
                    border.color: v.pal.select
                    Column {
                        x: 14
                        y: 12
                        width: parent.width - 28
                        spacing: 8
                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: "\u{F0FCE}  " + L.f("Generando «%1» · %2%", v.api ? v.api.renderName : "", Math.round((v.api ? v.api.progress : 0) * 100)) + (v.api && v.api.eta.length ? " · " + v.api.eta : "")
                            font.family: "Exo 2"
                            font.weight: Font.Bold
                            font.pixelSize: 13
                            color: v.pal.ink
                        }
                        GelBar {
                            width: parent.width
                            pal: v.pal
                            value: v.api ? v.api.progress : 0
                        }
                    }
                }

                Text { text: L.t("MIS FONDOS"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Flow {
                    width: parent.width
                    spacing: 10
                    Repeater {
                        model: [{ id: "auto", name: L.t("Original"), thumb: v.autoStill(v.work, false) }].concat(v.api ? v.api.walls : [])
                        delegate: Item {
                            required property var modelData
                            width: 132
                            height: 96
                            Rectangle {
                                width: 132
                                height: 74
                                radius: 12
                                clip: true
                                color: "#000000"
                                border.width: !v.drafting && v.wall === modelData.id ? 3 : 1
                                border.color: !v.drafting && v.wall === modelData.id ? v.pal.select : v.pal.cardBorder
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: v.file(modelData.thumb)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 264
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: v.pickWall(modelData.id)
                                }
                                Rectangle {
                                    visible: modelData.id !== "auto" && wallHover.hovered
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 5
                                    width: 24; height: 24; radius: 12
                                    color: "#cce0384f"
                                    Text { anchors.centerIn: parent; text: "\u{F01B4}"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; color: "#ffffff" }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: v.api.deleteWall(modelData.id)
                                    }
                                }
                                HoverHandler { id: wallHover }
                            }
                            Text {
                                y: 78
                                width: 132
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.name
                                font.family: "Exo 2"
                                font.pixelSize: 12
                                color: v.pal.ink
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: v.pal.sep }

                Text { text: L.t("FONDO NUEVO"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Row {
                    spacing: 10
                    width: parent.width
                    Pill {
                        pal: v.pal
                        glyph: "\u{F087C}"
                        text: L.t("Elegir imagen")
                        enabled2: !v.busy
                        onClicked: v.api.pickImage()
                    }
                    Pill {
                        visible: !!v.api && v.api.image.length > 0 && !v.drafting
                        pal: v.pal
                        glyph: "\u{F0208}"
                        text: L.t("Ver")
                        onClicked: v.useDraft = true
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 170
                        elide: Text.ElideMiddle
                        text: v.api && v.api.image ? v.api.image.split("/").pop() : L.t("Ninguna todavía")
                        font.family: "Exo 2"
                        font.pixelSize: 12
                        color: v.pal.muted
                    }
                }

                Text { text: L.t("ANIMACIONES"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Repeater {
                    model: v.layers
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: wallTab.width
                        height: modelData.on ? 76 : 40
                        radius: 14
                        color: modelData.on ? v.pal.hover : "transparent"
                        border.width: 1
                        border.color: modelData.on ? v.pal.select : v.pal.sep
                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        clip: true

                        Row {
                            x: 12
                            y: 8
                            spacing: 10
                            Text { text: modelData.glyph; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; color: modelData.on ? v.pal.accent : v.pal.muted }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name; font.family: "Exo 2"; font.weight: Font.Bold; font.pixelSize: 13; color: v.pal.ink }
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            y: 9
                            width: 40; height: 22; radius: 11
                            color: modelData.on ? v.workColor : v.pal.track
                            border.width: 1
                            border.color: v.pal.sep
                            Rectangle {
                                x: modelData.on ? parent.width - width - 2 : 2
                                y: 2
                                width: 18; height: 18; radius: 9
                                color: "#ffffff"
                                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: v.setLayer(index, { on: !modelData.on })
                            }
                        }
                        Row {
                            visible: modelData.on
                            x: 12
                            y: 42
                            spacing: 10
                            Slider {
                                width: wallTab.width - 150
                                pal: v.pal
                                value: modelData.amount
                                knob: v.workColor
                                stops: [
                                    GradientStop { position: 0.0; color: v.pal.track },
                                    GradientStop { position: 1.0; color: v.workColor }
                                ]
                                onMoved: function(x) { v.setLayer(index, { amount: Math.round(x * 100) / 100 }) }
                            }
                            Row {
                                spacing: 4
                                Repeater {
                                    model: [1, 2, 3]
                                    delegate: Rectangle {
                                        required property int modelData
                                        width: 30; height: 24; radius: 8
                                        color: v.layers[index].speed === modelData ? v.workColor : "transparent"
                                        border.width: 1
                                        border.color: v.pal.sep
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData === 1 ? "1×" : modelData === 2 ? "2×" : "3×"
                                            font.family: "Exo 2"
                                            font.weight: Font.Bold
                                            font.pixelSize: 11
                                            color: v.layers[index].speed === modelData ? "#ffffff" : v.pal.muted
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: v.setLayer(index, { speed: modelData })
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    spacing: 10
                    Pill {
                        pal: v.pal
                        glyph: "\u{F0208}"
                        text: v.previewing ? L.t("Actualizando…") : L.t("Vista previa")
                        enabled2: !v.previewing && !!v.api && v.api.image.length > 0
                        onClicked: v.api.preview(v.spec())
                    }
                    Pill {
                        pal: v.pal
                        primary: true
                        glyph: "\u{F0FCE}"
                        text: v.rendering ? L.f("Generando %1%", Math.round(v.api.progress * 100)) : L.t("Generar fondo")
                        enabled2: !v.busy && !!v.api && v.api.image.length > 0
                        onClicked: v.api.render(v.spec())
                    }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: L.t("Generar crea la versión de día y la de noche. Tarda unos minutos según cuántas animaciones elijás; mientras tanto podés seguir usando la compu.")
                    font.family: "Exo 2"
                    font.pixelSize: 12
                    color: v.pal.muted
                }
            }

            Column {
                id: themeTab
                visible: v.tab === 2
                width: parent.width
                spacing: 12

                Text { text: L.t("GUARDAR LO QUE ESTÁS VIENDO"); font.family: "Michroma"; font.pixelSize: 11; color: v.pal.ink }
                Row {
                    spacing: 10
                    Rectangle {
                        width: themeTab.width - 130
                        height: 36
                        radius: 18
                        color: v.pal.field
                        border.width: 1
                        border.color: nameInput.activeFocus ? v.pal.select : v.pal.fieldBorder
                        TextInput {
                            id: nameInput
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: "Exo 2"
                            font.pixelSize: 14
                            color: v.pal.ink
                            clip: true
                            text: v.themeName
                            onTextEdited: v.themeName = text
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !parent.text.length
                                text: L.t("Nombre del tema")
                                font: parent.font
                                color: v.pal.dim
                            }
                        }
                    }
                    Pill {
                        pal: v.pal
                        primary: true
                        glyph: "\u{F0193}"
                        text: L.t("Guardar")
                        enabled2: v.themeName.trim().length > 0 && !v.drafting
                        onClicked: {
                            v.api.saveTheme(v.themeName.trim(), v.work, v.wall)
                            v.themeName = ""
                        }
                    }
                }

                Text {
                    visible: v.drafting
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: L.t("Estás viendo un fondo nuevo sin generar: dale «Generar y aplicar» y después lo guardás como tema.")
                    font.family: "Exo 2"
                    font.pixelSize: 12
                    color: v.pal.muted
                }

                Rectangle { width: parent.width; height: 1; color: v.pal.sep }

                Flow {
                    width: parent.width
                    spacing: 12
                    Repeater {
                        model: [{ id: "p-blue", name: L.t("Azul"), accent: "blue", wallpaper: "auto", builtin: true },
                                { id: "p-red", name: L.t("Rojo"), accent: "red", wallpaper: "auto", builtin: true },
                                { id: "p-green", name: L.t("Verde"), accent: "green", wallpaper: "auto", builtin: true },
                                { id: "p-black", name: L.t("Negro"), accent: "black", wallpaper: "auto", builtin: true }].concat(v.api ? v.api.themes : [])
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            readonly property var w: v.findWall(modelData.wallpaper)
                            readonly property bool chosen: !v.drafting && v.work === modelData.accent && v.wall === modelData.wallpaper
                            width: (themeTab.width - 12) / 2
                            height: 128
                            radius: 16
                            clip: true
                            color: "#000000"
                            border.width: chosen ? 3 : 1
                            border.color: chosen ? v.pal.select : v.pal.cardBorder
                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: v.file(card.w ? card.w.thumb : v.autoStill(card.modelData.accent, false))
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 400
                            }
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 2
                                radius: 14
                                opacity: 0.55
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 0.55; color: Qt.rgba(Tint.color("#3d9be9", card.modelData.accent).r, Tint.color("#3d9be9", card.modelData.accent).g, Tint.color("#3d9be9", card.modelData.accent).b, 0.35) }
                                    GradientStop { position: 1.0; color: Tint.color("#1446c2", card.modelData.accent) }
                                }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 40
                                color: "#99050a14"
                                Row {
                                    x: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16; height: 16; radius: 8
                                        color: Tint.color("#3d9be9", card.modelData.accent)
                                        border.width: 2
                                        border.color: "#ffffff"
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: card.modelData.name
                                        font.family: "Exo 2"
                                        font.weight: Font.Bold
                                        font.pixelSize: 13
                                        color: "#ffffff"
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    v.work = card.modelData.accent
                                    v.pickWall(card.modelData.wallpaper)
                                }
                            }
                            Rectangle {
                                visible: !card.modelData.builtin && cardHover.hovered
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 6
                                width: 26; height: 26; radius: 13
                                color: "#cce0384f"
                                Text { anchors.centerIn: parent; text: "\u{F01B4}"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: "#ffffff" }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: v.api.deleteTheme(card.modelData.id)
                                }
                            }
                            HoverHandler { id: cardHover }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        width: toastText.implicitWidth + 40
        height: 40
        radius: 20
        color: "#e6050a14"
        border.width: 1
        border.color: v.pal.select
        opacity: v.api && v.api.toast.length ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Text {
            id: toastText
            anchors.centerIn: parent
            text: v.api ? v.api.toast : ""
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 13
            color: "#ffffff"
        }
    }
}
