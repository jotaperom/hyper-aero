import QtQuick
import "Registry.js" as Reg

Item {
    id: frame
    property string wid: ""
    property var core
    readonly property var reg: Reg.find(wid)

    function load() {
        if (!reg || !core) return
        ld.setSource(reg.file, { core: core, pal: core.pal })
    }

    onWidChanged: load()
    onCoreChanged: if (!ld.item) load()
    Component.onCompleted: load()

    Loader {
        id: ld
        anchors.fill: parent
        onLoaded: {
            item.core = Qt.binding(function() { return frame.core })
            item.pal = Qt.binding(function() { return frame.core ? frame.core.pal : item.pal })
        }
    }
}
