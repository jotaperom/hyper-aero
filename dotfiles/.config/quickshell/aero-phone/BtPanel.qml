import QtQuick

Item {
    id: bp
    property var pal
    property var backend
    property bool live: false
    property string expanded: ""
    property string toast: ""
    readonly property var st: backend ? backend.bt : ({})
    readonly property bool avail: st.avail !== false
    readonly property bool powered: !!st.powered
    readonly property var devs: st.devices || []
    readonly property var rows: {
        var mine = devs.filter(function(d) { return d.paired })
        var near = devs.filter(function(d) { return !d.paired })
        var out = []
        if (mine.length) out = out.concat([{ header: "MIS DISPOSITIVOS" }], mine)
        if (near.length) out = out.concat([{ header: "DISPONIBLES" }], near)
        return out
    }
    readonly property int count: devs.length
    signal back()
    signal act(string name)

    function glyphFor(d) {
        var i = d.icon || ""
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "\u{F02CB}"
        if (i.indexOf("audio") >= 0) return "\u{F04C3}"
        if (i.indexOf("mouse") >= 0) return "\u{F037D}"
        if (i.indexOf("keyboard") >= 0) return "\u{F030C}"
        if (i.indexOf("gaming") >= 0) return "\u{F0297}"
        if (i.indexOf("phone") >= 0) return "\u{F011C}"
        if (i.indexOf("computer") >= 0) return "\u{F0322}"
        if (i.indexOf("watch") >= 0) return "\u{F0897}"
        return "\u{F00AF}"
    }

    function subFor(d) {
        if (d.connected) return "Conectado" + (d.battery >= 0 ? "  ·  \u{F0079} " + d.battery + "%" : "")
        if (d.paired) return "Emparejado  ·  tocá para conectar"
        return "Nuevo  ·  tocá para emparejar"
    }

    function say(msg) {
        toast = msg
        toastTimer.restart()
    }

    function connect(d) {
        if (!backend) return
        expanded = ""
        backend.btConnect(d.mac, function(r) { say(r.msg) })
    }

    function tap(d) {
        if (d.connected) expanded = expanded === d.mac ? "" : d.mac
        else connect(d)
    }

    onLiveChanged: {
        if (live && backend) {
            expanded = ""
            backend.btRefresh()
            if (powered) backend.btScan()
        }
    }

    Timer {
        interval: bp.backend && bp.backend.btScanning ? 2500 : 6000
        repeat: true
        running: bp.live
        onTriggered: if (bp.backend && !bp.expanded) bp.backend.btRefresh()
    }

    Timer {
        id: toastTimer
        interval: 3200
        onTriggered: bp.toast = ""
    }

    PanelHeader {
        id: header
        x: 14
        y: 4
        width: parent.width - 28
        pal: bp.pal
        title: "Bluetooth"
        on: bp.powered
        switchEnabled: bp.avail
        spinning: !!(bp.backend && bp.backend.btScanning)
        onBack: bp.back()
        onRefresh: if (bp.backend) bp.backend.btScan()
        onToggled: function(v) { if (bp.backend) bp.backend.btPower(v) }
    }

    Text {
        id: status
        anchors.top: header.bottom
        anchors.topMargin: 8
        x: 18
        width: parent.width - 36
        elide: Text.ElideRight
        text: !bp.avail ? "SIN ADAPTADOR BLUETOOTH" : (!bp.powered ? "BLUETOOTH APAGADO" : (bp.backend && bp.backend.btScanning ? "BUSCANDO DISPOSITIVOS…" : "VISIBLE COMO ESTA COMPU"))
        font.family: "JetBrainsMono Nerd Font"
        font.weight: Font.Bold
        font.pixelSize: 10
        font.letterSpacing: 1
        color: bp.pal.heroSub
    }

    ListView {
        id: list
        anchors.top: status.bottom
        anchors.topMargin: 6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        x: 14
        width: parent.width - 28
        clip: true
        spacing: 6
        visible: bp.powered
        boundsBehavior: Flickable.StopAtBounds
        model: bp.rows
        delegate: Item {
            id: cell
            required property var modelData
            width: list.width
            height: loader.item ? loader.item.implicitHeight : 0
            Loader {
                id: loader
                width: parent.width
                sourceComponent: cell.modelData.header ? headerComp : rowComp
            }
            Component {
                id: headerComp
                Item {
                    implicitHeight: 24
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        x: 4
                        text: cell.modelData.header
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 10
                        font.letterSpacing: 1
                        color: bp.pal.heroSub
                    }
                }
            }
            Component {
                id: rowComp
                NetRow {
                    readonly property var d: cell.modelData
                    pal: bp.pal
                    glyph: bp.glyphFor(d)
                    title: d.name
                    sub: bp.subFor(d)
                    active: d.connected
                    busy: !!(bp.backend && bp.backend.btBusy === d.mac)
                    expanded: bp.expanded === d.mac
                    showMore: d.paired && !d.connected
                    mode: "actions"
                    actions: d.connected
                        ? [{ id: "forget", label: "Olvidar", danger: true }, { id: "disconnect", label: "Desconectar", primary: true }]
                        : [{ id: "forget", label: "Olvidar", danger: true }, { id: "connect", label: "Conectar", primary: true }]
                    onTapped: bp.tap(d)
                    onMore: bp.expanded = bp.expanded === d.mac ? "" : d.mac
                    onAction: function(id) {
                        bp.expanded = ""
                        if (!bp.backend) return
                        if (id === "disconnect") bp.backend.btDisconnect(d.mac, function(r) { bp.say(r.msg) })
                        else if (id === "forget") bp.backend.btForget(d.mac, function(r) { bp.say(r.msg) })
                        else if (id === "connect") bp.connect(d)
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: list
        spacing: 8
        visible: !bp.powered || (bp.count === 0 && !(bp.backend && bp.backend.btScanning))
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: bp.powered ? "\u{F00AF}" : "\u{F00B2}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 40
            color: bp.pal.heroSub
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: !bp.avail ? "NO DISPONIBLE" : (bp.powered ? "NADA CERCA TODAVÍA" : "ENCENDÉ EL BLUETOOTH")
            font.family: "Michroma"
            font.pixelSize: 10
            color: bp.pal.heroSub
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 40, toastText.implicitWidth + 30)
        height: 32
        radius: 16
        antialiasing: true
        color: bp.pal.field
        border.width: 1
        border.color: bp.pal.glow
        opacity: bp.toast.length ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Text {
            id: toastText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 24)
            elide: Text.ElideRight
            text: bp.toast
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: bp.pal.text
        }
    }
}
