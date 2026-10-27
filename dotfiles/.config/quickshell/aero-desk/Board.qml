import QtQuick
import Quickshell.Io

Item {
    id: board
    property var core
    property string screenName: ""
    property bool primary: false
    property var layout: []
    property bool editing: false
    property bool loaded: false
    property bool fresh: false
    property int designCols: 0
    property int designRows: 0
    readonly property string dir: core ? core.deskDir : ""
    readonly property string file: dir + "/layout-" + safe(screenName) + ".json"
    signal doneRequested()

    function safe(n) {
        return String(n || "screen").replace(/[^A-Za-z0-9_.-]/g, "_")
    }

    function placed(id) {
        for (var i = 0; i < layout.length; i++) {
            if (layout[i].id === id) return true
        }
        return false
    }

    function project(spec, cols, rows) {
        var c = spec.c
        var r = spec.r
        if (designCols > 0 && cols > 0 && cols !== designCols && spec.c + spec.w / 2 > designCols / 2) c = cols - (designCols - spec.c)
        if (designRows > 0 && rows > 0 && rows !== designRows && spec.r + spec.h / 2 > designRows / 2) r = rows - (designRows - spec.r)
        return { id: spec.id, c: c, r: r, w: spec.w, h: spec.h }
    }

    function setLayout(list, cols, rows) {
        layout = core.sanitize(list)
        if (cols > 0 && rows > 0) {
            designCols = cols
            designRows = rows
        }
        save()
    }

    function save() {
        store.setText(JSON.stringify({ version: 3, cell: 48, screen: screenName, cols: designCols, rows: designRows, widgets: layout }, null, 2) + "\n")
    }

    function take(text, fromLegacy) {
        if (!core) {
            Qt.callLater(take, text, fromLegacy)
            return
        }
        try {
            var d = JSON.parse(text)
            designCols = d.cols | 0
            designRows = d.rows | 0
            layout = core.sanitize(d.widgets || [])
            if (fromLegacy) {
                if (d.hidden) core.setHidden(true)
                save()
            }
        } catch (err) {
            layout = []
            fresh = true
        }
        loaded = true
    }

    function openEdit() {
        if (editing) return
        core.setHidden(false)
        editing = true
    }

    onLayoutChanged: if (core) core.setPlaced(screenName, layout)
    Component.onDestruction: if (core) core.setPlaced(screenName, [])

    FileView {
        id: store
        path: board.screenName.length ? board.file : ""
        printErrors: false
        onLoaded: board.take(text(), false)
        onLoadFailed: {
            if (board.primary) {
                legacy.path = board.dir + "/layout.json"
            } else {
                board.layout = []
                board.fresh = true
                board.loaded = true
            }
        }
    }

    FileView {
        id: legacy
        path: ""
        printErrors: false
        onLoaded: board.take(text(), true)
        onLoadFailed: {
            board.layout = []
            board.fresh = true
            board.loaded = true
        }
    }
}
