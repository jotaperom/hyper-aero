import QtQuick

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

    function focusSearch() {
        search.forceActiveFocus()
    }

    function reset() {
        search.text = ""
        sel = 0
        nav = false
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
                var s = Qt.locale("es_ES").toString(scr.now, "dddd d 'de' MMMM")
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
                text: "Buscar en NEXUS"
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
                cursorShape: Qt.PointingHandCursor
                onClicked: scr.launch(modelData.key)
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
            text: "SIN COINCIDENCIAS"
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
        border.width: 1
        border.color: scr.pal.tileBorder
        Behavior on opacity { NumberAnimation { duration: 180 } }

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

        Row {
            anchors.centerIn: parent
            spacing: scr.compact ? 14 : 18
            Repeater {
                model: scr.favorites
                delegate: AppIcon {
                    required property int index
                    required property var modelData
                    opacity: Math.max(0, Math.min(1, (scr.reveal * 1.9 - 0.9 - index * 0.08) * 3))
                    size: scr.iconSize
                    pal: scr.pal
                    source: modelData.icon
                    name: modelData.name
                    hot: fav.containsMouse
                    MouseArea {
                        id: fav
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: scr.launch(modelData.key)
                    }
                }
            }
        }
    }
}
