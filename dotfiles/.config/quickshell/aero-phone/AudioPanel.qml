import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "Lang.js" as L

Item {
    id: ap
    property var pal
    property var backend
    property bool live: false
    signal back()

    readonly property var nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var sinks: nodes.filter(function(n) { return n && n.audio && !n.isStream && n.isSink })
    readonly property var sources: nodes.filter(function(n) { return n && n.audio && !n.isStream && !n.isSink && !ap.isMonitor(n) })
    readonly property var players: nodes.filter(function(n) { return n && n.audio && n.isStream && !n.isSink })
    readonly property var recorders: nodes.filter(function(n) { return n && n.audio && n.isStream && n.isSink && !ap.isMeter(n) })
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function props(n) {
        return (n && n.properties) ? n.properties : ({})
    }

    function isMonitor(n) {
        var p = props(n)
        return String(p["media.class"] || "").indexOf("Monitor") >= 0 || String(n.name || "").indexOf(".monitor") >= 0
    }

    function isMeter(n) {
        var p = props(n)
        if (String(p["stream.capture.sink"] || "") === "true") return true
        if (String(p["stream.monitor"] || "") === "true") return true
        var app = String(p["application.name"] || p["node.name"] || "").toLowerCase()
        return app.indexOf("cava") >= 0 || app.indexOf("peak") >= 0 || app.indexOf("quickshell") >= 0
    }

    function title(n) {
        return n.description || n.nickname || n.name || "?"
    }

    function appName(n) {
        var p = props(n)
        return p["application.name"] || n.description || n.name || "?"
    }

    function appSub(n) {
        var p = props(n)
        var m = p["media.name"] || ""
        return m === appName(n) ? "" : m
    }

    function appIcon(n) {
        var p = props(n)
        var name = p["application.icon-name"] || p["application.process.binary"] || String(p["application.name"] || "").toLowerCase()
        return name ? Quickshell.iconPath(name, true) : ""
    }

    function same(a, b) {
        return !!a && !!b && a.id === b.id
    }

    function deviceGlyph(n, input) {
        var p = props(n)
        var s = (title(n) + " " + (n.name || "") + " " + (p["device.form-factor"] || "") + " " + (p["device.bus"] || "") + " " + (p["api.bluez5.address"] ? "bluetooth" : "")).toLowerCase()
        if (input) {
            if (s.indexOf("headset") >= 0 || s.indexOf("bluetooth") >= 0) return "\u{F02CE}"
            if (s.indexOf("webcam") >= 0 || s.indexOf("camera") >= 0) return "\u{F0100}"
            return "\u{F036C}"
        }
        if (s.indexOf("hdmi") >= 0 || s.indexOf("displayport") >= 0 || s.indexOf("monitor") >= 0) return "\u{F0379}"
        if (s.indexOf("headphone") >= 0 || s.indexOf("headset") >= 0 || s.indexOf("auricular") >= 0) return "\u{F02CB}"
        if (s.indexOf("bluetooth") >= 0) return "\u{F00AF}"
        if (s.indexOf("usb") >= 0) return "\u{F0553}"
        return "\u{F04C3}"
    }

    function volGlyph(n) {
        if (!n || !n.audio || n.audio.muted || n.audio.volume <= 0.001) return "\u{F075F}"
        if (n.audio.volume < 0.34) return "\u{F057F}"
        if (n.audio.volume < 0.67) return "\u{F0580}"
        return "\u{F057E}"
    }

    function setVol(n, v) {
        if (!n || !n.audio) return
        if (v > 0 && n.audio.muted) n.audio.muted = false
        n.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleMute(n) {
        if (n && n.audio) n.audio.muted = !n.audio.muted
    }

    function useSink(n) {
        try { Pipewire.preferredDefaultAudioSink = n } catch (e) {}
    }

    function useSource(n) {
        try { Pipewire.preferredDefaultAudioSource = n } catch (e) {}
    }

    PwObjectTracker {
        objects: ap.live ? ap.sinks.concat(ap.sources, ap.players, ap.recorders) : []
    }

    PanelHeader {
        id: header
        x: 14
        y: 4
        width: parent.width - 28
        pal: ap.pal
        title: L.t("Audio")
        on: !!(ap.sink && ap.sink.audio && !ap.sink.audio.muted)
        switchEnabled: !!ap.sink
        showRefresh: false
        onBack: ap.back()
        onToggled: function(v) { if (ap.sink && ap.sink.audio) ap.sink.audio.muted = !v }
    }

    Flickable {
        id: scroll
        anchors.top: header.bottom
        anchors.topMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        x: 14
        width: parent.width - 28
        contentWidth: width
        contentHeight: col.implicitHeight + 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: scroll.width
            spacing: 8

            GlassSlider {
                width: parent.width
                pal: ap.pal
                glyph: ap.volGlyph(ap.sink)
                label: L.t("Volumen general")
                dim: !!(ap.sink && ap.sink.audio && ap.sink.audio.muted)
                value: ap.sink && ap.sink.audio ? ap.sink.audio.volume : 0
                onMoved: function(v) { ap.setVol(ap.sink, v) }
                onGlyphClicked: ap.toggleMute(ap.sink)
            }

            SectionLabel { text: L.t("SALIDA") ; pal: ap.pal }

            Repeater {
                model: ap.sinks
                delegate: AudioRow {
                    required property var modelData
                    width: col.width
                    pal: ap.pal
                    node: modelData
                    glyph: ap.volGlyph(modelData)
                    badge: ap.deviceGlyph(modelData, false)
                    label: ap.title(modelData)
                    selectable: true
                    selected: ap.same(modelData, ap.sink)
                    onPick: ap.useSink(modelData)
                    onMoved: function(v) { ap.setVol(modelData, v) }
                    onGlyphClicked: ap.toggleMute(modelData)
                }
            }

            Empty { visible: ap.sinks.length === 0; text: L.t("NO HAY SALIDAS DE AUDIO"); pal: ap.pal }

            SectionLabel { text: L.t("ENTRADA"); pal: ap.pal }

            Repeater {
                model: ap.sources
                delegate: AudioRow {
                    required property var modelData
                    width: col.width
                    pal: ap.pal
                    node: modelData
                    glyph: modelData.audio && modelData.audio.muted ? "\u{F036D}" : "\u{F036C}"
                    badge: ap.deviceGlyph(modelData, true)
                    label: ap.title(modelData)
                    selectable: true
                    selected: ap.same(modelData, ap.source)
                    onPick: ap.useSource(modelData)
                    onMoved: function(v) { ap.setVol(modelData, v) }
                    onGlyphClicked: ap.toggleMute(modelData)
                }
            }

            Empty { visible: ap.sources.length === 0; text: L.t("NO HAY MICRÓFONOS"); pal: ap.pal }

            SectionLabel { text: L.t("APPS"); pal: ap.pal }

            Repeater {
                model: ap.players
                delegate: AudioRow {
                    required property var modelData
                    width: col.width
                    pal: ap.pal
                    node: modelData
                    glyph: ap.volGlyph(modelData)
                    icon: ap.appIcon(modelData)
                    badge: "\u{F075A}"
                    label: ap.appName(modelData)
                    hint: ap.appSub(modelData)
                    onMoved: function(v) { ap.setVol(modelData, v) }
                    onGlyphClicked: ap.toggleMute(modelData)
                }
            }

            Empty { visible: ap.players.length === 0; text: L.t("NINGUNA APP ESTÁ SONANDO"); pal: ap.pal }

            SectionLabel { visible: ap.recorders.length > 0; text: L.t("APPS USANDO EL MICRÓFONO"); pal: ap.pal }

            Repeater {
                model: ap.recorders
                delegate: AudioRow {
                    required property var modelData
                    width: col.width
                    pal: ap.pal
                    node: modelData
                    glyph: modelData.audio && modelData.audio.muted ? "\u{F036D}" : "\u{F036C}"
                    icon: ap.appIcon(modelData)
                    badge: "\u{F036C}"
                    label: ap.appName(modelData)
                    onMoved: function(v) { ap.setVol(modelData, v) }
                    onGlyphClicked: ap.toggleMute(modelData)
                }
            }
        }
    }

    component SectionLabel: Item {
        property var pal
        property alias text: lbl.text
        width: parent ? parent.width : 0
        height: 22
        Text {
            id: lbl
            anchors.bottom: parent.bottom
            x: 4
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 10
            font.letterSpacing: 1
            color: parent.pal ? parent.pal.heroSub : "#888888"
        }
    }

    component Empty: Item {
        property var pal
        property alias text: msg.text
        width: parent ? parent.width : 0
        height: visible ? 30 : 0
        Text {
            id: msg
            anchors.centerIn: parent
            font.family: "Michroma"
            font.pixelSize: 9
            color: parent.pal ? parent.pal.muted : "#888888"
        }
    }
}
