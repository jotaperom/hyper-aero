import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: shell
    readonly property string scripts: Quickshell.env("HOME") + "/.config/hyper-aero/scripts"
    readonly property string tool: scripts + "/aero-studio.py"
    property bool shown: true
    property string screenName: ""

    function pickScreen() {
        var list = Quickshell.screens
        var mon = Hyprland.focusedMonitor
        for (var i = 0; i < list.length; i++) {
            if (mon && list[i].name === mon.name) return list[i]
        }
        return list.length ? list[0] : null
    }

    QtObject {
        id: backend
        property var themes: []
        property string mode: "day"
        property var pending: null

        function apply(item) {
            pending = ["apply", item.accent, item.wallpaper]
            shell.shown = false
            launch.restart()
        }

        function studio() {
            pending = null
            shell.shown = false
            Quickshell.execDetached([shell.scripts + "/studio.sh"])
            quitLater.restart()
        }
    }

    Timer {
        id: launch
        interval: 180
        onTriggered: {
            if (backend.pending) Quickshell.execDetached([shell.tool].concat(backend.pending))
            quitLater.restart()
        }
    }

    Timer {
        id: quitLater
        interval: 120
        onTriggered: Qt.quit()
    }

    Process {
        id: loader
        command: [shell.tool, "switch"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text)
                    backend.mode = d.mode || "day"
                    backend.themes = d.themes || []
                } catch (err) {
                }
                view.open = true
            }
        }
    }

    PanelWindow {
        id: win
        visible: shell.shown
        screen: shell.pickScreen()
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "aero-carousel"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        CarouselView {
            id: view
            anchors.fill: parent
            api: backend
            focus: true
            onClosed: Qt.quit()
        }
    }

    IpcHandler {
        target: "carousel"

        function toggle(): void {
            view.dismiss()
        }
    }
}
