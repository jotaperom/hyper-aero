import QtQuick
import "Lang.js" as L

Item {
    id: scr
    property var pal
    property var backend
    property var now: new Date()
    property alias query: search.text
    property int sel: 0
    property bool nav: false
    property real reveal: 1
    property bool compact: false
    readonly property int iconSize: compact ? 44 : 52
    readonly property bool searching: query.length > 0
    readonly property var apps: backend ? backend.apps : []
    readonly property var usage: backend ? backend.usage : ({})
    readonly property var results: rank(apps, query, usage)
    readonly property var favorites: pickFavs(apps, usage)
    readonly property int cols: width > 440 ? 6 : 4
    readonly property var pins: backend ? backend.pins : []
    readonly property bool pinsSet: backend ? backend.pinsSet : false
    readonly property int dockGap: compact ? 12 : 16
    readonly property int dockSlots: Math.max(3, Math.min(7, Math.floor((width - 40 + dockGap) / (iconSize + dockGap))))
    readonly property var dockApps: pinsSet ? byKeys(pins, apps).slice(0, dockSlots) : favorites
    property var dragApp: null
    property string dragFrom: ""
    property point dragPos: Qt.point(0, 0)
    property bool overDock: false
    property int dropAt: -1
    property var menuApp: null
    property string menuFrom: ""
    property string toast: ""
    readonly property bool hinting: !!(backend && backend.dockHint)
    readonly property bool dragDocked: !!dragApp && dockApps.some(function(a) { return a.key === dragApp.key })
    readonly property bool canDrop: dragDocked || dockApps.length < dockSlots
    signal launch(string key)
    signal closeRequested()
    signal pageRequested(int p)

    function norm(s) {
        return String(s || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "")
    }

    function rank(list, q, use) {
        var n = norm(q).trim()
        if (!n.length) {
            var all = list.slice()
            all.sort(function(a, b) { return a.sortName < b.sortName ? -1 : (a.sortName > b.sortName ? 1 : 0) })
            return all
        }
        var out = []
        for (var i = 0; i < list.length; i++) {
            var a = list[i]
            var name = norm(a.name)
            var s = 0
            if (name.indexOf(n) === 0) s = 100
            else if ((" " + name).indexOf(" " + n) >= 0) s = 80
            else if (name.indexOf(n) >= 0) s = 60
            else if (norm(a.sub).indexOf(n) >= 0) s = 40
            else if (norm(a.kw).indexOf(n) >= 0) s = 30
            else if (norm(a.key).indexOf(n) >= 0) s = 14
            else if (norm(a.comment).indexOf(n) >= 0) s = 10
            if (s > 0) out.push({ a: a, s: s + Math.min(20, use[a.key] || 0) })
        }
        out.sort(function(x, y) { return y.s - x.s || (x.a.sortName < y.a.sortName ? -1 : 1) })
        return out.map(function(o) { return o.a })
    }

    function pickFavs(list, use) {
        var used = list.filter(function(a) { return (use[a.key] || 0) > 0 })
        used.sort(function(a, b) { return (use[b.key] || 0) - (use[a.key] || 0) })
        var out = used.slice(0, 4)
        var defaults = ["kitty", "brave", "nautilus", "spotify", "vesktop", "code"]
        for (var i = 0; i < defaults.length && out.length < 4; i++) {
            for (var j = 0; j < list.length; j++) {
                if (norm(list[j].key).indexOf(defaults[i]) >= 0 && out.indexOf(list[j]) < 0) {
                    out.push(list[j])
                    break
                }
            }
        }
        return out
    }

    function byKeys(keys, list) {
        var map = {}
        for (var i = 0; i < list.length; i++) map[list[i].key] = list[i]
        var out = []
        for (var j = 0; j < keys.length; j++) {
            if (map[keys[j]]) out.push(map[keys[j]])
        }
        return out
    }

    function dockKeys() {
        return dockApps.map(function(a) { return a.key })
    }

    function say(msg) {
        toast = msg
        toastTimer.restart()
    }

    function pinApp(key, at) {
        if (!backend) return
        var cur = dockKeys()
        var l = cur.filter(function(k) { return k !== key })
        if (cur.indexOf(key) < 0 && l.length >= dockSlots) {
            say(L.t("El dock está lleno: quitá una app primero"))
            return
        }
        if (at === undefined || at < 0 || at > l.length) at = l.length
        l.splice(at, 0, key)
        backend.setPins(l)
    }

    function unpinApp(key) {
        if (!backend) return
        backend.setPins(dockKeys().filter(function(k) { return k !== key }))
    }

    function shiftApp(key, dir) {
        var l = dockKeys()
        var i = l.indexOf(key)
        var j = i + dir
        if (i < 0 || j < 0 || j >= l.length) return
        l.splice(i, 1)
        l.splice(j, 0, key)
        backend.setPins(l)
    }

    function isDocked(key) {
        return dockKeys().indexOf(key) >= 0
    }

    function beginDrag(app, from, p) {
        closeMenu()
        if (backend) backend.dockHint = false
        dragApp = app
        dragFrom = from
        dragTo(p)
    }

    function dragTo(p) {
        dragPos = p
        var r = dock.mapToItem(scr, 0, 0)
        overDock = !searching && p.x >= r.x - 12 && p.x <= r.x + dock.width + 12 && p.y >= r.y - 26 && p.y <= r.y + dock.height + 14
        if (!overDock) {
            dropAt = -1
            return
        }
        var keys = dragDocked ? dockKeys().filter(function(k) { return k !== dragApp.key }) : dockKeys()
        var n = keys.length
        var step = iconSize + dockGap
        var start = r.x + (dock.width - ((n + 1) * step - dockGap)) / 2
        dropAt = Math.max(0, Math.min(n, Math.floor((p.x - start + dockGap / 2) / step)))
    }

    function endDrag() {
        var app = dragApp
        var from = dragFrom
        var over = overDock
        var at = dropAt
        dragApp = null
        dragFrom = ""
        overDock = false
        dropAt = -1
        if (!app) return
        if (over) pinApp(app.key, at)
        else if (from === "dock") unpinApp(app.key)
    }

    function cancelDrag() {
        dragApp = null
        dragFrom = ""
        overDock = false
        dropAt = -1
    }

    function openMenu(app, from, p) {
        menuApp = app
        menuFrom = from
        bubble.x = Math.max(8, Math.min(scr.width - bubble.width - 8, p.x - bubble.width / 2))
        bubble.y = Math.max(8, Math.min(scr.height - bubble.height - 8, from === "dock" ? p.y - bubble.height - 18 : p.y + 10))
    }

    function closeMenu() {
        menuApp = null
        menuFrom = ""
    }

    function menuItems() {
        if (!menuApp) return []
        if (menuFrom === "dock") {
            var l = dockKeys()
            var i = l.indexOf(menuApp.key)
            var out = [{ id: "open", glyph: "\u{F040A}", text: L.t("Abrir") }]
            if (i > 0) out.push({ id: "left", glyph: "\u{F0141}", text: L.t("Mover a la izquierda") })
            if (i >= 0 && i < l.length - 1) out.push({ id: "right", glyph: "\u{F0142}", text: L.t("Mover a la derecha") })
            out.push({ id: "unpin", glyph: "\u{F0931}", text: L.t("Quitar del dock") })
            return out
        }
        return [
            { id: "open", glyph: "\u{F040A}", text: L.t("Abrir") },
            isDocked(menuApp.key)
                ? { id: "unpin", glyph: "\u{F0931}", text: L.t("Quitar del dock") }
                : { id: "pin", glyph: "\u{F0403}", text: L.t("Anclar al dock") }
        ]
    }

    function menuPick(id) {
        var app = menuApp
        closeMenu()
        if (!app) return
        if (id === "open") launch(app.key)
        else if (id === "pin") pinApp(app.key)
        else if (id === "unpin") unpinApp(app.key)
        else if (id === "left") shiftApp(app.key, -1)
        else if (id === "right") shiftApp(app.key, 1)
    }

    function focusSearch() {
        search.forceActiveFocus()
    }

    function reset() {
        search.text = ""
        sel = 0
        nav = false
        cancelDrag()
        closeMenu()
        grid.positionViewAtBeginning()
    }

    function move(dx, dy) {
        var n = results.length
        if (!n) return
        if (!nav) {
            nav = true
            return
        }
        sel = Math.max(0, Math.min(n - 1, sel + dx + dy * cols))
    }

    function activate() {
        var n = results.length
        if (!n) return
        if (!nav && !searching) {
            nav = true
            return
        }
        launch(results[Math.min(sel, n - 1)].key)
    }

    function backspace() {
        search.text = search.text.slice(0, -1)
        focusSearch()
    }

    function typeIn(t) {
        search.text = search.text + t
        search.cursorPosition = search.text.length
        focusSearch()
    }

    onQueryChanged: {
        sel = 0
        nav = searching
        grid.positionViewAtBeginning()
    }
    onSelChanged: grid.positionViewAtIndex(sel, GridView.Contain)

    Item {
        id: header
        x: 0; y: 0
        width: parent.width
        height: scr.searching || scr.compact ? 0 : 98
        clip: true
        opacity: Math.min(1, scr.reveal * 1.6)
        Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            y: 4
            text: Qt.formatTime(scr.now, "HH:mm")
            font.family: "Michroma"
            font.pixelSize: 46
            color: scr.pal.hero
            style: Text.Raised
            styleColor: scr.pal.heroShadow
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: clock.bottom
            anchors.topMargin: 2
            text: {
                var s = Qt.locale(L.LOCALE).toString(scr.now, L.t("dddd d 'de' MMMM"))
                return s.charAt(0).toUpperCase() + s.slice(1)
            }
            font.family: "Exo 2"
            font.weight: Font.DemiBold
            font.pixelSize: 14
            color: scr.pal.heroSub
        }
    }

    Rectangle {
        id: pill
        anchors.top: header.bottom
        anchors.topMargin: scr.compact ? 10 : 8
        x: scr.compact ? 12 : 16
        width: parent.width - x * 2
        height: scr.compact ? 36 : 42
        radius: height / 2
        antialiasing: true
        color: scr.pal.field
        border.width: search.activeFocus ? 2 : 1
        border.color: search.activeFocus ? scr.pal.glow : scr.pal.tileBorder

        Text {
            id: lens
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{F0349}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
            color: scr.pal.accent
        }

        TextInput {
            id: search
            anchors.left: lens.right
            anchors.leftMargin: 9
            anchors.right: count.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            font.family: "Exo 2"
            font.pixelSize: 15
            color: scr.pal.text
            selectionColor: scr.pal.accentFill
            selectedTextColor: "#ffffff"
            clip: true
            focus: true

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !search.text.length
                text: L.t("Buscar en NEXUS")
                font: search.font
                color: scr.pal.muted
            }

            Keys.onPressed: function(e) {
                var n = scr.results.length
                if (e.key === Qt.Key_Escape) {
                    if (search.text.length) search.text = ""
                    else scr.closeRequested()
                    e.accepted = true
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    if (n) scr.launch(scr.results[Math.min(scr.sel, n - 1)].key)
                    e.accepted = true
                } else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) {
                    scr.pageRequested(1)
                    e.accepted = true
                } else if (e.key === Qt.Key_Down) {
                    if (!scr.nav) scr.nav = true
                    else scr.sel = Math.min(n - 1, scr.sel + scr.cols)
                    e.accepted = true
                } else if (e.key === Qt.Key_Up) {
                    if (scr.sel - scr.cols >= 0) scr.sel -= scr.cols
                    e.accepted = true
                } else if (e.key === Qt.Key_Right) {
                    scr.nav = true
                    scr.sel = Math.min(n - 1, scr.sel + 1)
                    e.accepted = true
                } else if (e.key === Qt.Key_Left) {
                    scr.nav = true
                    scr.sel = Math.max(0, scr.sel - 1)
                    e.accepted = true
                }
            }
        }

        Text {
            id: count
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: scr.searching ? String(scr.results.length) : String(scr.apps.length)
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 11
            color: scr.pal.muted
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: scr.focusSearch()
            z: -1
        }
    }

    GridView {
        id: grid
        anchors.top: pill.bottom
        anchors.topMargin: 10
        anchors.bottom: scr.searching ? parent.bottom : dock.top
        anchors.bottomMargin: 6
        x: 8
        width: parent.width - 16
        cellWidth: width / scr.cols
        cellHeight: scr.compact ? 76 : 88
        clip: true
        model: scr.results
        currentIndex: scr.sel
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        cacheBuffer: 400

        delegate: Item {
            id: cellRoot
            width: grid.cellWidth
            height: grid.cellHeight
            property real pop: Math.max(0, Math.min(1, (scr.reveal * 1.9 - 0.25 - index * 0.045) * 3))
            opacity: pop
            transform: Translate { y: (1 - cellRoot.pop) * 22 }

            AppIcon {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                y: scr.compact ? 4 : 6
                size: scr.iconSize
                pal: scr.pal
                source: modelData.icon
                name: modelData.name
                lit: scr.nav && index === scr.sel
                hot: cell.containsMouse
            }

            Text {
                anchors.top: icon.bottom
                anchors.topMargin: scr.compact ? 4 : 6
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 6
                horizontalAlignment: Text.AlignHCenter
                text: modelData.name
                elide: Text.ElideRight
                font.family: "Exo 2"
                font.weight: Font.DemiBold
                font.pixelSize: 11
                color: scr.pal.label
                style: Text.Raised
                styleColor: scr.pal.labelShadow
            }

            MouseArea {
                id: cell
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: scr.dragApp ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                pressAndHoldInterval: 380
                onClicked: function(m) {
                    if (m.button === Qt.RightButton) scr.openMenu(modelData, "grid", mapToItem(scr, m.x, m.y))
                    else scr.launch(modelData.key)
                }
                onPressAndHold: function(m) {
                    if (m.button !== Qt.LeftButton) return
                    preventStealing = true
                    scr.beginDrag(modelData, "grid", mapToItem(scr, m.x, m.y))
                }
                onPositionChanged: function(m) {
                    if (scr.dragApp && pressed) scr.dragTo(mapToItem(scr, m.x, m.y))
                }
                onReleased: {
                    preventStealing = false
                    if (scr.dragApp) scr.endDrag()
                }
                onCanceled: {
                    preventStealing = false
                    scr.cancelDrag()
                }
            }
        }
    }

    Column {
        anchors.centerIn: grid
        spacing: 6
        visible: scr.searching && scr.results.length === 0
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "\u{F0349}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 34
            color: scr.pal.muted
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: L.t("SIN COINCIDENCIAS")
            font.family: "Michroma"
            font.pixelSize: 11
            color: scr.pal.muted
        }
    }

    Rectangle {
        id: dock
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        x: 12
        width: parent.width - 24
        height: scr.compact ? 64 : 78
        radius: scr.compact ? 24 : 28
        antialiasing: true
        opacity: scr.searching ? 0 : 1
        visible: opacity > 0
        color: scr.pal.shelf
        border.width: scr.overDock ? 2 : 1
        border.color: scr.overDock ? (scr.canDrop ? scr.pal.glow : "#e63a4a") : scr.pal.tileBorder
        scale: scr.overDock && scr.canDrop ? 1.03 : 1
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            x: 2; y: 1
            width: parent.width - 4
            height: parent.height * 0.42
            radius: parent.radius - 1
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, scr.pal.glossTop) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: scr.dockApps.length === 0 && !scr.dragApp
            text: L.t("Arrastrá apps acá")
            font.family: "Exo 2"
            font.weight: Font.DemiBold
            font.pixelSize: 12
            color: scr.pal.muted
        }

        Item {
            id: dockRow
            anchors.fill: parent
            Repeater {
                model: scr.dockApps
                delegate: Item {
                    id: slot
                    required property int index
                    required property var modelData
                    readonly property bool lifted: !!scr.dragApp && scr.dragApp.key === modelData.key
                    readonly property bool gap: !!scr.dragApp && scr.overDock && scr.canDrop
                    readonly property int rank: {
                        var keys = scr.dockKeys()
                        if (gap && scr.dragDocked) keys = keys.filter(function(k) { return k !== scr.dragApp.key })
                        return keys.indexOf(modelData.key)
                    }
                    readonly property int spot: gap && rank >= scr.dropAt ? rank + 1 : rank
                    readonly property int total: scr.dockApps.length - (gap && scr.dragDocked ? 1 : 0) + (gap ? 1 : 0)
                    readonly property real step: scr.iconSize + scr.dockGap
                    width: scr.iconSize
                    height: scr.iconSize
                    y: (dock.height - height) / 2
                    x: (dock.width - (total * step - scr.dockGap)) / 2 + Math.max(0, spot) * step
                    opacity: lifted ? (gap ? 0 : 0.25) : Math.max(0, Math.min(1, (scr.reveal * 1.9 - 0.9 - index * 0.08) * 3))
                    Behavior on x { enabled: !!scr.dragApp; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    AppIcon {
                        size: scr.iconSize
                        pal: scr.pal
                        source: slot.modelData.icon
                        name: slot.modelData.name
                        hot: fav.containsMouse && !scr.dragApp
                    }
                    MouseArea {
                        id: fav
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        preventStealing: true
                        cursorShape: scr.dragApp ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        pressAndHoldInterval: 380
                        onClicked: function(m) {
                            if (m.button === Qt.RightButton) scr.openMenu(slot.modelData, "dock", mapToItem(scr, m.x, m.y))
                            else scr.launch(slot.modelData.key)
                        }
                        onPressAndHold: function(m) {
                            if (m.button === Qt.LeftButton) scr.beginDrag(slot.modelData, "dock", mapToItem(scr, m.x, m.y))
                        }
                        onPositionChanged: function(m) {
                            if (scr.dragApp && pressed) scr.dragTo(mapToItem(scr, m.x, m.y))
                        }
                        onReleased: if (scr.dragApp) scr.endDrag()
                        onCanceled: scr.cancelDrag()
                    }
                }
            }
        }
    }

    Rectangle {
        id: hintBox
        anchors.bottom: dock.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 28, hintText.implicitWidth + 28)
        height: hintText.implicitHeight + 16
        radius: 14
        antialiasing: true
        color: scr.pal.field
        border.width: 1
        border.color: scr.pal.glow
        opacity: scr.hinting && !scr.searching && !scr.dragApp ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Text {
            id: hintText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, scr.width - 56)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: L.t("Mantené presionada una app y arrastrala al dock. Clic derecho para más opciones.")
            font.family: "Exo 2"
            font.weight: Font.DemiBold
            font.pixelSize: 12
            color: scr.pal.text
        }
    }

    Timer {
        running: scr.hinting
        interval: 7000
        onTriggered: if (scr.backend) scr.backend.dockHint = false
    }

    AppIcon {
        id: ghost
        visible: !!scr.dragApp
        z: 50
        size: scr.iconSize
        pal: scr.pal
        source: scr.dragApp ? scr.dragApp.icon : ""
        name: scr.dragApp ? scr.dragApp.name : ""
        lit: scr.overDock && scr.canDrop
        x: scr.dragPos.x - width / 2
        y: scr.dragPos.y - height / 2
        scale: 1.15
        opacity: 0.92
    }

    MouseArea {
        anchors.fill: parent
        z: 60
        visible: !!scr.menuApp
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: scr.closeMenu()
    }

    Rectangle {
        id: bubble
        z: 61
        width: 200
        height: menuCol.implicitHeight + 12
        radius: 14
        antialiasing: true
        color: scr.pal.field
        border.width: 1
        border.color: scr.pal.glow
        opacity: scr.menuApp ? 1 : 0
        scale: scr.menuApp ? 1 : 0.92
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

        Column {
            id: menuCol
            x: 6
            y: 6
            width: parent.width - 12
            spacing: 2
            Text {
                width: parent.width
                leftPadding: 8
                bottomPadding: 4
                elide: Text.ElideRight
                text: scr.menuApp ? scr.menuApp.name : ""
                font.family: "Michroma"
                font.pixelSize: 10
                color: scr.pal.muted
            }
            Repeater {
                model: scr.menuItems()
                delegate: Rectangle {
                    required property var modelData
                    width: menuCol.width
                    height: 30
                    radius: 9
                    color: itemArea.containsMouse ? scr.pal.badge : "transparent"
                    Row {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 9
                        Text {
                            text: modelData.glyph
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: scr.pal.accent
                        }
                        Text {
                            text: modelData.text
                            font.family: "Exo 2"
                            font.weight: Font.DemiBold
                            font.pixelSize: 13
                            color: scr.pal.text
                        }
                    }
                    MouseArea {
                        id: itemArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: scr.menuPick(modelData.id)
                    }
                }
            }
        }
    }

    Rectangle {
        z: 62
        anchors.bottom: dock.top
        anchors.bottomMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 40, toastText.implicitWidth + 30)
        height: 32
        radius: 16
        antialiasing: true
        color: scr.pal.field
        border.width: 1
        border.color: scr.pal.glow
        opacity: scr.toast.length ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Text {
            id: toastText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 24)
            elide: Text.ElideRight
            text: scr.toast
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: scr.pal.text
        }
    }

    Timer {
        id: toastTimer
        interval: 3200
        onTriggered: scr.toast = ""
    }
}
