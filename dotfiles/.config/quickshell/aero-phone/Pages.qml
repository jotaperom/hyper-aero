import QtQuick
import QtQml.Models

Item {
    id: pg
    property var host
    property var pal: host.pal
    property bool compact: height < 600
    property real reveal: 1
    readonly property alias apps: apps
    readonly property alias controls: controls
    readonly property alias assist: assist

    Connections {
        target: pg.host
        function onPageChanged() {
            if (pages.currentIndex !== pg.host.page) pages.currentIndex = pg.host.page
        }
    }

    Component.onCompleted: pages.currentIndex = host.page

    ListView {
        id: pages
        anchors.fill: parent
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: 380
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        onCurrentIndexChanged: if (pg.host.page !== currentIndex) pg.host.page = currentIndex
        model: ObjectModel {
            AppsScreen {
                id: apps
                width: pages.width
                height: pages.height
                compact: pg.compact
                pal: pg.pal
                backend: pg.host.backend
                now: pg.host.now
                reveal: pg.reveal
                onLaunch: function(key) {
                    if (pg.host.backend) pg.host.backend.launch(key)
                    pg.host.requestClose()
                }
                onCloseRequested: pg.host.requestClose()
                onPageRequested: function(p) { pg.host.page = p }
            }
            ControlScreen {
                id: controls
                width: pages.width
                height: pages.height
                pal: pg.pal
                backend: pg.host.backend
                live: pg.host.active && pg.host.page === 1
                onAct: function(name) { pg.host.act(name) }
                onCloseRequested: pg.host.requestClose()
                onPageRequested: function(p) { pg.host.page = p }
            }
            TodayScreen {
                id: assist
                width: pages.width
                height: pages.height
                pal: pg.pal
                backend: pg.host.backend
                live: pg.host.active && pg.host.page === 2
                onCloseRequested: pg.host.requestClose()
                onPageRequested: function(p) { pg.host.page = p }
            }
        }
    }
}
