import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: shell
    readonly property string run: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    VeilCore {
        id: veil
        onReport: function(line) { stateFile.setText(line + "\n") }
    }

    FileView {
        id: cmdFile
        path: shell.run + "/aero-veil.cmd"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: veil.handle(text())
    }

    FileView {
        id: stateFile
        path: shell.run + "/aero-veil.state"
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: veil.active
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "hyperveil"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            VeilShot {
                anchors.fill: parent
                core: veil
                file: shell.run + "/aero-veil-" + win.modelData.name + ".ppm"
            }
        }
    }
}
