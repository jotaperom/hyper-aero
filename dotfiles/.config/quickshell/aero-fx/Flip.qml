import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "Lang.js" as L

Scope {
    id: fl
    property var pal
    property bool night: false
    property string run: "/tmp"
    property bool open: false
    property bool mapped: false
    property var target: null
    property var wins: []
    property int sel: 0
    property real reveal: open ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: fl.open ? 360 : 200; easing.type: Easing.OutCubic } }

    function pickScreen() {
        var list = Quickshell.screens
        var mon = Hyprland.focusedMonitor
        for (var i = 0; i < list.length; i++) {
            if (mon && list[i].name === mon.name) return list[i]
        }
        return list.length ? list[0] : null
    }

    function show() {
        if (!listProc.running) listProc.running = true
    }

    function next() {
        if (wins.length) sel = (sel + 1) % wins.length
    }

    function prev() {
        if (wins.length) sel = (sel - 1 + wins.length) % wins.length
    }

    function close() {
        open = false
        hide.restart()
    }

    function choose() {
        var w = wins[sel]
        close()
        if (w) Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + w.address + "\" })"])
    }

    function toplevelFor(addr) {
        var list = Hyprland.toplevels ? Hyprland.toplevels.values : []
        var want = String(addr).replace(/^0x/, "")
        for (var i = 0; i < list.length; i++) {
            var t = list[i]
            if (t && String(t.address).replace(/^0x/, "") === want) return t.wayland || null
        }
        return null
    }

    Process {
        id: listProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                var list = []
                try {
                    list = JSON.parse(text)
                } catch (err) {
                }
                list = list.filter(function(c) { return c.mapped && !c.hidden && c.workspace && c.workspace.id > 0 })
                list.sort(function(a, b) { return a.focusHistoryID - b.focusHistoryID })
                fl.wins = list.map(function(c) {
                    return { address: c.address, title: c.title || "", cls: c.class || "", ws: c.workspace.id, w: c.size[0], h: c.size[1] }
                })
                if (!fl.wins.length) return
                fl.sel = fl.wins.length > 1 ? 1 : 0
                fl.target = fl.pickScreen()
                hide.stop()
                fl.mapped = true
                fl.open = true
            }
        }
    }

    Timer {
        id: hide
        interval: 240
        onTriggered: if (!fl.open) fl.mapped = false
    }

    PanelWindow {
        id: win
        visible: fl.mapped
        screen: fl.target
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "aero-flip"
        WlrLayershell.keyboardFocus: fl.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            opacity: fl.reveal
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.06, 0.16, 0.72) }
                GradientStop { position: 1.0; color: Qt.rgba(0.0, 0.02, 0.08, 0.86) }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(m) {
                if (m.button === Qt.RightButton) fl.close()
                else fl.choose()
            }
            onWheel: function(w) {
                if (w.angleDelta.y < 0) fl.next()
                else fl.prev()
            }
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: function(e) {
                if (e.key === Qt.Key_Escape) fl.close()
                else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right || e.key === Qt.Key_Down) fl.next()
                else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left || e.key === Qt.Key_Up) fl.prev()
                else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) fl.choose()
                e.accepted = true
            }
            Keys.onReleased: function(e) {
                if (!e.isAutoRepeat && (e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R || e.key === Qt.Key_Meta)) fl.choose()
                e.accepted = true
            }
        }

        Item {
            id: stage
            anchors.fill: parent
            readonly property real cardW: Math.min(width * 0.46, 900)
            readonly property real baseX: width * 0.24
            readonly property real baseY: height * 0.52
            readonly property int n: fl.wins.length

            Repeater {
                model: fl.wins
                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property int k: stage.n ? (index - fl.sel + stage.n) % stage.n : 0
                    readonly property real aspect: Math.max(0.3, Math.min(3, modelData.h / Math.max(1, modelData.w)))
                    width: stage.cardW
                    height: Math.min(stage.height * 0.56, stage.cardW * aspect)
                    x: stage.baseX + k * stage.width * 0.055 - width / 2 + stage.cardW / 2
                    y: stage.baseY - height / 2 - k * stage.height * 0.045 + (1 - fl.reveal) * 80
                    z: 1000 - k
                    scale: 1 - k * 0.045
                    opacity: (k > 7 ? 0 : 1 - k * 0.08) * fl.reveal
                    Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    transform: Rotation {
                        origin.x: card.width / 2
                        origin.y: card.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: -34
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -6
                        radius: 14
                        color: Qt.rgba(1, 1, 1, card.k === 0 ? 0.22 : 0.1)
                        border.width: card.k === 0 ? 2 : 1
                        border.color: card.k === 0 && fl.pal ? fl.pal.glow : Qt.rgba(1, 1, 1, 0.5)
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: 10
                        color: fl.night ? "#0b1224" : "#dfe9f5"
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file://" + fl.run + "/aero-thumbs/" + String(card.modelData.address).replace(/^0x/, "") + ".jpg"
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                        }

                        ScreencopyView {
                            id: live
                            anchors.fill: parent
                            captureSource: fl.mapped && card.k < 8 ? fl.toplevelFor(card.modelData.address) : null
                            live: card.k === 0
                            visible: hasContent
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !live.hasContent
                            text: String(card.modelData.cls).split(".").pop().charAt(0).toUpperCase()
                            font.family: "Michroma"
                            font.pixelSize: 64
                            color: fl.night ? "#2a3c66" : "#a9c3e4"
                            z: -1
                        }

                        Rectangle {
                            width: parent.width
                            height: parent.height * 0.3
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                            }
                        }
                    }

                    Rectangle {
                        anchors.top: parent.bottom
                        anchors.topMargin: 6
                        width: parent.width
                        height: parent.height * 0.35
                        opacity: 0.25
                        visible: card.k === 0
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.25) }
                            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            fl.sel = card.index
                            fl.choose()
                        }
                    }
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: parent.height * 0.08
            spacing: 6
            opacity: fl.reveal
            visible: fl.wins.length > 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: fl.wins.length ? String(fl.wins[fl.sel].cls).split(".").pop().toUpperCase() : ""
                font.family: "Michroma"
                font.pixelSize: 13
                font.letterSpacing: 2
                color: fl.pal ? fl.pal.glow : "#6fd3ff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, win.width * 0.6)
                elide: Text.ElideRight
                text: fl.wins.length ? fl.wins[fl.sel].title : ""
                font.family: "Exo 2"
                font.weight: Font.DemiBold
                font.pixelSize: 18
                color: "#ffffff"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: L.f("Escritorio %1  ·  Tab siguiente  ·  Enter abrir  ·  Esc cerrar", fl.wins.length ? fl.wins[fl.sel].ws : "")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                color: Qt.rgba(1, 1, 1, 0.55)
            }
        }
    }
}
