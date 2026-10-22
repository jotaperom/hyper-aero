import QtQuick
import "Tint.js" as Tint

FocusScope {
    id: host
    property var backend
    property bool active: false
    property int page: 0
    property string openSub: ""
    property var now: new Date()
    property string toastText: ""
    property string forceSkin: ""
    readonly property bool night: !!(backend && backend.st && backend.st.mode === "night")
    readonly property string accent: backend && backend.st && backend.st.accent ? backend.st.accent : "blue"
    readonly property var pal: Tint.palette(night ? nightPal : dayPal, accent)
    readonly property string skin: forceSkin.length ? forceSkin : (backend && backend.skin ? backend.skin : "iphone")
    readonly property var pages: skinLoader.item ? skinLoader.item.pages : null
    readonly property bool inSub: page === 1 && !!pages && pages.controls.sub.length > 0
    readonly property var pageNames: ["Apps", "Control", "Hoy"]
    readonly property real shown: skinLoader.item ? skinLoader.item.shown : 0
    readonly property var skinFiles: ({
        iphone: "SkinIphone.qml", flip: "SkinFlip.qml", aqua: "SkinAqua.qml", visor: "SkinVisor.qml",
        slider: "SkinSlider.qml", holo: "SkinHolo.qml", pda: "SkinPda.qml", orbit: "SkinOrbit.qml"
    })
    signal requestClose()
    signal closed()

    readonly property var dayPal: ({
        scrim: "#0b2a66", scrimA: 0.13, paper0: "#f4f8fc", paper1: "#d0e2f4", bubble: "#eef3f8", bar0: "#2350c8", bar1: "#142a8c",
        text: "#0b0d12", muted: "#5a6270", accent: "#1e6fd9", glow: "#3d9be9", ring: "#ffffff",
        tile0: "#f7ffffff", tile1: "#e6eef6fd", tile2: "#d9e1ecf8", tile3: "#e6eef4fb",
        tileBorder: "#b3ffffff", onBorder: "#e61446c2",
        on0: "#8cc6f5", on1: "#3d9be9", on2: "#1446c2", on3: "#1e6fd9",
        glossTop: 0.75, badge: "#d9ffffff", track: "#99ffffff",
        icon0: "#fdffffff", icon1: "#f2edf4fc", icon2: "#f2d3e2f3",
        iconBorder: "#e6ffffff", iconGloss: 0.7,
        field: "#ebffffff", shelf: "#6bffffff", accentFill: "#1e6fd9",
        hero: "#ffffff", heroShadow: "#801446c2", heroSub: "#f0ffffff",
        label: "#ffffff", labelShadow: "#b30b2a66", status: "#ffffff",
        wall0: "#1446c2", wall1: "#2a7fe0", wall2: "#4c9eec", wall3: "#86c4f4",
        blobA: "#55ffffff", blobB: "#38ffffff", blobC: "#2effffff", arc: "#73ffffff",
        body0: "#f6f9fc", body1: "#c9d3de", body2: "#eef3f8", body3: "#9eabba", body4: "#e3e9f0",
        edge0: "#7d8a9c", edge1: "#aab5c3", rim: "#ffffff", bezel: "#0b0f18",
        halo: "#663d9be9", shadow: "#8c0b1a3a", home: "#e6ffffff",
        key0: "#ffffff", key1: "#f1f6fc", key2: "#d9e5f2", key3: "#ecf3fa",
        keyEdge: "#7f9cc0", keyRim: "#ccffffff", keyText: "#1d2836", keySub: "#5f6b7c", keyLit: "#1e6fd9"
    })

    readonly property var nightPal: ({
        scrim: "#020610", scrimA: 0.14, paper0: "#dce9f6", paper1: "#a9c5e3", bubble: "#16243f", bar0: "#1f3f86", bar1: "#0e1d44",
        text: "#e6eefb", muted: "#8b97ab", accent: "#6fd3ff", glow: "#6fd3ff", ring: "#6fd3ff",
        tile0: "#d92c4370", tile1: "#d91d3058", tile2: "#d914234a", tile3: "#d91a2c52",
        tileBorder: "#596fd3ff", onBorder: "#d96fd3ff",
        on0: "#8cc6f5", on1: "#3d9be9", on2: "#1446c2", on3: "#1e6fd9",
        glossTop: 0.16, badge: "#800a1428", track: "#b3070c18",
        icon0: "#f0334c7c", icon1: "#f01c2c52", icon2: "#f0111c38",
        iconBorder: "#666fd3ff", iconGloss: 0.22,
        field: "#d9070c18", shelf: "#8c0e182e", accentFill: "#1e6fd9",
        hero: "#e6eefb", heroShadow: "#99000000", heroSub: "#a9c4e6",
        label: "#e6eefb", labelShadow: "#e6000000", status: "#e6eefb",
        wall0: "#0f2250", wall1: "#0a1736", wall2: "#070f24", wall3: "#04070f",
        blobA: "#4d3d9be9", blobB: "#2e6fd3ff", blobC: "#661446c2", arc: "#596fd3ff",
        body0: "#46587c", body1: "#1c253a", body2: "#33415f", body3: "#0d1322", body4: "#26314c",
        edge0: "#05080f", edge1: "#1a2540", rim: "#806fd3ff", bezel: "#020409",
        halo: "#593d9be9", shadow: "#cc000000", home: "#cce6eefb",
        key0: "#4a5c84", key1: "#2b3a5c", key2: "#1b2643", key3: "#25324f",
        keyEdge: "#04070e", keyRim: "#596fd3ff", keyText: "#c3d4ee", keySub: "#7d8ca8", keyLit: "#6fd3ff"
    })

    function tx(v) {
        return Tint.color(v, accent)
    }

    function tint(hex, a) {
        return "#" + ("0" + Math.round(Math.max(0, Math.min(1, a)) * 255).toString(16)).slice(-2) + hex.slice(1)
    }

    function toast(t) {
        toastText = t
        toastTimer.restart()
    }

    Timer {
        id: toastTimer
        interval: 1400
        onTriggered: host.toastText = ""
    }

    Timer {
        interval: 1000
        repeat: true
        running: host.shown > 0
        triggeredOnStart: true
        onTriggered: host.now = new Date()
    }

    function focusPage() {
        if (!pages) return
        if (page === 0) pages.apps.focusSearch()
        else if (page === 2) pages.assist.focusInput()
        else keySink.forceActiveFocus()
    }

    function prepare() {
        if (!pages) return
        pages.apps.reset()
        pages.controls.sub = openSub
        openSub = ""
        focusPage()
    }

    onActiveChanged: {
        if (!skinLoader.item) return
        if (active) {
            prepare()
            skinLoader.item.open()
        } else {
            skinLoader.item.close()
        }
    }

    onPageChanged: focusPage()

    function controlsSub(sub) {
        if (pages) pages.controls.sub = sub
    }

    function typeIn(t) {
        page = 0
        if (pages) pages.apps.typeIn(t)
    }

    function typeKey(t) {
        if (!pages) return
        if (t === "\b") {
            if (page === 2) pages.assist.backspace()
            else pages.apps.backspace()
        } else if (t === "\n") {
            keypad("ok")
        } else if (page === 2) {
            pages.assist.typeIn(t)
        } else {
            typeIn(t)
        }
    }

    function act(name) {
        var starting = (name === "rec" || name === "rec-region") && !(backend && backend.st && backend.st.rec)
        if (backend) backend.act(name)
        if (starting || ["wifi-advanced", "shot", "lock", "suspend", "reboot", "poweroff"].indexOf(name) >= 0) requestClose()
    }

    function scrollPage(dir) {
        if (!pages) return
        if (page === 0) pages.apps.move(0, dir)
        else if (page === 1) pages.controls.scrollBy(dir * 90)
        else pages.assist.scrollBy(dir * 60)
    }

    function keypad(k) {
        if (!pages) return
        if (k === "softL") {
            if (inSub) pages.controls.sub = ""
            else page = (page + 2) % 3
        } else if (k === "softR") {
            page = (page + 1) % 3
        } else if (k === "call") {
            page = 2
            pages.assist.focusInput()
            toast("Nota rápida")
        } else if (k === "end") {
            if (inSub) pages.controls.sub = ""
            else requestClose()
        } else if (k === "home") {
            if (inSub) pages.controls.sub = ""
            page = 0
        } else if (k === "up") {
            scrollPage(-1)
        } else if (k === "down") {
            scrollPage(1)
        } else if (k === "left" || k === "right") {
            var d = k === "left" ? -1 : 1
            if (page === 0) pages.apps.move(d, 0)
            else page = (page + 3 + d) % 3
        } else if (k === "ok") {
            if (page === 0) pages.apps.activate()
            else if (page === 2) pages.assist.send("")
        } else if (k === "vol+" || k === "vol-") {
            if (backend) backend.setVolume(Math.max(0, Math.min(1, backend.volume + (k === "vol+" ? 0.05 : -0.05))))
            toast("Volumen " + Math.round(Math.max(0, Math.min(1, (backend ? backend.volume : 0) + (k === "vol+" ? 0.05 : -0.05))) * 100) + "%")
        } else if (k === "1") {
            page = 1
            pages.controls.sub = "wifi"
        } else if (k === "2") {
            page = 1
            pages.controls.sub = "bt"
        } else if (k === "3") {
            act("night")
            toast(night ? "Modo claro" : "Modo oscuro")
        } else if (k === "4") {
            act("shot")
        } else if (k === "5") {
            act("rec")
        } else if (k === "6") {
            if (backend) backend.mediaCmd("toggle")
            toast("Música ▶❚❚")
        } else if (k === "7") {
            act("warm")
            toast("Luz cálida")
        } else if (k === "8") {
            act("dnd")
            toast("No molestar")
        } else if (k === "9") {
            act("themes")
            toast("Temas")
        } else if (k === "*") {
            if (backend) backend.toggleMute()
            toast("Silencio")
        } else if (k === "0") {
            page = 0
        } else if (k === "#") {
            act("lock")
        }
    }

    function handleKey(e) {
        if (e.key === Qt.Key_Escape) {
            if (inSub) pages.controls.sub = ""
            else host.requestClose()
            e.accepted = true
        } else if (inSub) {
            e.accepted = false
        } else if (e.key === Qt.Key_Tab) {
            host.page = (host.page + 1) % 3
            e.accepted = true
        } else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) {
            host.page = 0
            e.accepted = true
        } else if (host.page === 1 && pages && (e.key === Qt.Key_Up || e.key === Qt.Key_Down)) {
            pages.controls.scrollBy(e.key === Qt.Key_Up ? -90 : 90)
            e.accepted = true
        } else if (e.text && e.text.length === 1 && e.text.charCodeAt(0) > 32 && !(e.modifiers & Qt.ControlModifier)) {
            host.typeIn(e.text)
            e.accepted = true
        }
    }

    Keys.onPressed: function(e) { host.handleKey(e) }

    Connections {
        target: host.pages ? host.pages.controls : null
        function onSubChanged() {
            if (!host.pages.controls.sub.length && host.page === 1) keySink.forceActiveFocus()
        }
    }

    Item {
        id: keySink
        Keys.onPressed: function(e) { host.handleKey(e) }
    }

    Rectangle {
        anchors.fill: parent
        opacity: Math.max(0, Math.min(1, host.shown))
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: host.tint(host.pal.scrim, host.pal.scrimA) }
            GradientStop { position: 0.38; color: host.tint(host.pal.scrim, host.pal.scrimA * 0.55) }
            GradientStop { position: 0.7; color: host.tint(host.pal.scrim, 0) }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: host.requestClose()
        }
    }

    function loadSkin() {
        skinLoader.source = ""
        skinLoader.setSource(skinFiles[skin] || "SkinIphone.qml", { host: host, variant: skin })
    }

    onSkinChanged: loadSkin()
    Component.onCompleted: loadSkin()

    Loader {
        id: skinLoader
        anchors.fill: parent
        onLoaded: {
            if (host.active) {
                host.prepare()
                item.open()
            }
        }
    }
}
