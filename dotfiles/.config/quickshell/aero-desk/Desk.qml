import QtQuick
import Quickshell
import Quickshell.Io
import "Registry.js" as Reg
import "Lang.js" as L

Item {
    id: desk
    property var core
    readonly property var pal: core.pal
    readonly property int cell: 48
    readonly property int margin: 16
    readonly property int gap: 6
    property real stableW: 0
    property real stableH: 0
    property var ids: []
    property string hudVariant: ""
    property var hudWidths: ({})
    property bool predicting: false
    readonly property int cols: Math.max(1, Math.floor((stableW - margin * 2) / cell))
    readonly property int rows: Math.max(1, Math.floor((stableH - margin * 2) / cell))
    readonly property real ox: Math.round((stableW - cols * cell) / 2)
    readonly property real oy: Math.round((stableH - rows * cell) / 2)
    signal editRequested()

    function fit(spec) {
        var reg = Reg.find(spec.id)
        var w = Math.min(cols, Math.max(reg ? reg.minW : 1, spec.w))
        var h = Math.min(rows, Math.max(reg ? reg.minH : 1, spec.h))
        return { id: spec.id, c: Math.max(0, Math.min(cols - w, spec.c)), r: Math.max(0, Math.min(rows - h, spec.r)), w: w, h: h }
    }

    function specOf(id) {
        var l = core.layout || []
        for (var i = 0; i < l.length; i++) {
            if (l[i].id === id) return l[i]
        }
        return { id: id, c: 0, r: 0, w: 1, h: 1 }
    }

    function syncIds() {
        var l = core.layout || []
        var n = []
        for (var i = 0; i < l.length; i++) n.push(l[i].id)
        if (n.join("|") !== ids.join("|")) ids = n
    }

    function applySize(w, h) {
        stableW = w
        stableH = h
        maybeDefaults()
        sizeUp()
    }

    function settle() {
        if (width < 1 || height < 1) return
        applySize(width, height)
        if (hudVariant.length) {
            var m = hudWidths
            m[hudVariant] = width
            hudWidths = m
        }
    }

    function hudSize(v) {
        return v === "telemetry" ? 282 : (v === "telemetry-slim" ? 60 : 0)
    }

    function hudChanged(v) {
        if (!v.length || v === hudVariant) return
        var old = hudVariant
        hudVariant = v
        if (!old.length || stableW <= 0) return
        var target = hudWidths[v] !== undefined ? hudWidths[v] : stableW + hudSize(old) - hudSize(v)
        predicting = true
        settleTimer.stop()
        predictTimer.restart()
        applySize(target, stableH)
    }

    function maybeDefaults() {
        if (core.loaded && core.fresh && stableW > 200 && stableH > 200) {
            core.fresh = false
            core.savedCols = cols
            core.savedRows = rows
            core.setLayout(Reg.defaults(cols, rows))
        }
    }

    function sizeUp() {
        if (core.loaded && !core.fresh && stableW > 200 && stableH > 200) core.adapt(cols, rows)
    }

    onWidthChanged: if (stableW <= 0) settle(); else if (!predicting) settleTimer.restart()
    onHeightChanged: if (stableH <= 0) settle(); else if (!predicting) settleTimer.restart()
    Component.onCompleted: syncIds()
    Timer {
        id: settleTimer
        interval: 140
        onTriggered: desk.settle()
    }
    Timer {
        id: predictTimer
        interval: 900
        onTriggered: {
            desk.predicting = false
            desk.settle()
        }
    }
    FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/aero-hud.variant"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: desk.hudChanged(text().trim())
    }
    Connections {
        target: desk.core
        function onFreshChanged() { desk.maybeDefaults() }
        function onLoadedChanged() { desk.maybeDefaults(); desk.sizeUp() }
        function onLayoutChanged() { desk.syncIds() }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: function(m) {
            if (m.button === Qt.RightButton) menu.openAt(m.x, m.y)
            else menu.close()
        }
    }

    Item {
        id: layer
        anchors.fill: parent
        opacity: desk.core.hidden || desk.core.editing ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Repeater {
            model: desk.ids
            delegate: WidgetFrame {
                required property var modelData
                required property int index
                readonly property var spec: desk.fit(desk.specOf(modelData))
                x: desk.ox + spec.c * desk.cell + desk.gap
                y: desk.oy + spec.r * desk.cell + desk.gap
                width: spec.w * desk.cell - desk.gap * 2
                height: spec.h * desk.cell - desk.gap * 2
                Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                wid: modelData
                core: desk.core
                opacity: 0
                Component.onCompleted: appear.start()
                NumberAnimation on opacity {
                    id: appear
                    running: false
                    to: 1
                    duration: 360
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    ContextMenu {
        id: menu
        pal: desk.pal
        bounds: Qt.size(desk.width, desk.height)
        items: [
            { key: "edit", glyph: "\u{F03EB}", text: L.t("Editar escritorio"), hint: "SUPER+ALT+D" },
            { key: "hide", glyph: "\u{F0209}", text: desk.core.hidden ? L.t("Mostrar widgets") : L.t("Ocultar widgets"), hint: "SUPER+D" },
            { key: "mode", glyph: "\u{F050E}", text: desk.core.night ? L.t("Modo día") : L.t("Modo noche"), hint: "SUPER+T" },
            { key: "accent", glyph: "\u{F03D8}", text: L.t("Cambiar tema"), hint: "" },
            { key: "studio", glyph: "\u{F08B5}", text: L.t("Estudio de temas"), hint: "" }
        ]
        onPicked: function(key) {
            if (key === "edit") desk.editRequested()
            else if (key === "hide") desk.core.toggleHidden()
            else if (key === "mode") desk.core.nightToggle()
            else if (key === "accent") desk.core.openThemes()
            else if (key === "studio") desk.core.openStudio()
        }
    }
}
