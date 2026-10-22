import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: shell
    readonly property string run: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string aero: Quickshell.env("HOME") + "/.config/hyper-aero"
    property var st: ({ active: false })
    property string accent: "blue"
    property bool night: false

    FileView {
        path: shell.run + "/aero-snap.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                shell.st = JSON.parse(text())
            } catch (err) {
            }
        }
    }

    FileView {
        path: shell.aero + "/theme/accent"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.accent = text().trim()
    }

    FileView {
        path: shell.aero + "/theme/mode"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: shell.night = text().trim() === "night"
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            readonly property bool mine: !!shell.st.active && shell.st.mon === modelData.name
            screen: modelData
            visible: mine || hold.running
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "aero-snap"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            onMineChanged: if (!mine) hold.restart()

            Timer {
                id: hold
                interval: 260
            }

            SnapView {
                anchors.fill: parent
                st: win.mine ? shell.st : ({ active: false })
                accent: shell.accent
                night: shell.night
            }
        }
    }
}
