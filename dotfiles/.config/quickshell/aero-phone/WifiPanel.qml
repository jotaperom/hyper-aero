import QtQuick

Item {
    id: wp
    property var pal
    property var backend
    property bool live: false
    property string expanded: ""
    property string forcePass: ""
    property string toast: ""
    readonly property var st: backend ? backend.wifi : ({})
    readonly property bool radio: !!st.radio
    readonly property var nets: st.networks || []
    readonly property var current: {
        for (var i = 0; i < nets.length; i++) if (nets[i].active) return nets[i]
        return null
    }
    signal back()
    signal act(string name)

    function glyphFor(n) {
        var lock = n.sec !== "OPEN"
        if (n.signal >= 75) return lock ? "\u{F092A}" : "\u{F0928}"
        if (n.signal >= 50) return lock ? "\u{F0927}" : "\u{F0925}"
        if (n.signal >= 25) return lock ? "\u{F0924}" : "\u{F0922}"
        return lock ? "\u{F0921}" : "\u{F091F}"
    }

    function subFor(n) {
        if (n.active) return "Conectada" + (st.ip ? "  ·  " + st.ip : "")
        if (n.known) return "Guardada  ·  " + n.signal + "%"
        if (n.sec === "OPEN") return "Abierta  ·  " + n.signal + "%"
        if (n.sec === "ENTERPRISE") return "Empresarial  ·  " + n.signal + "%"
        return "Protegida  ·  " + n.signal + "%"
    }

    function say(msg) {
        toast = msg
        toastTimer.restart()
    }

    function connect(ssid, pw) {
        if (!backend) return
        expanded = ""
        backend.wifiConnect(ssid, pw, function(r) {
            if (r.ok) {
                forcePass = ""
                say(r.msg)
            } else if (r.kind === "needpass") {
                forcePass = ssid
                expanded = ssid
                say(r.msg)
            } else {
                say(r.msg || "No se pudo conectar")
            }
        })
    }

    function tap(n) {
        if (n.active) {
            expanded = expanded === n.ssid ? "" : n.ssid
        } else if (n.sec === "ENTERPRISE" && !n.known) {
            expanded = expanded === n.ssid ? "" : n.ssid
        } else if (n.known || n.sec === "OPEN") {
            connect(n.ssid, "")
        } else {
            expanded = expanded === n.ssid ? "" : n.ssid
        }
    }

    onLiveChanged: {
        if (live && backend) {
            expanded = ""
            forcePass = ""
            backend.wifiRefresh(true)
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: wp.live
        onTriggered: if (wp.backend && !wp.expanded) wp.backend.wifiRefresh(false)
    }

    Timer {
        id: toastTimer
        interval: 3200
        onTriggered: wp.toast = ""
    }

    PanelHeader {
        id: header
        x: 14
        y: 4
        width: parent.width - 28
        pal: wp.pal
        title: "Wi-Fi"
        on: wp.radio
        spinning: !!(wp.backend && wp.backend.wifiScanning)
        onBack: wp.back()
        onRefresh: if (wp.backend) wp.backend.wifiRefresh(true)
        onToggled: function(v) { if (wp.backend) wp.backend.wifiRadio(v) }
    }

    Text {
        id: status
        anchors.top: header.bottom
        anchors.topMargin: 8
        x: 18
        width: parent.width - 36
        elide: Text.ElideRight
        text: !wp.radio ? "WI-FI APAGADO" : (wp.current ? "CONECTADO  ·  " + wp.current.ssid.toUpperCase() : "SIN CONEXIÓN  ·  " + wp.nets.length + " REDES")
        font.family: "JetBrainsMono Nerd Font"
        font.weight: Font.Bold
        font.pixelSize: 10
        font.letterSpacing: 1
        color: wp.pal.heroSub
    }

    ListView {
        id: list
        anchors.top: status.bottom
        anchors.topMargin: 10
        anchors.bottom: footLink.top
        anchors.bottomMargin: 8
        x: 14
        width: parent.width - 28
        clip: true
        spacing: 6
        visible: wp.radio
        boundsBehavior: Flickable.StopAtBounds
        model: wp.nets
        delegate: NetRow {
            required property var modelData
            width: list.width
            pal: wp.pal
            glyph: wp.glyphFor(modelData)
            title: modelData.ssid
            sub: wp.subFor(modelData)
            active: modelData.active
            busy: !!(wp.backend && wp.backend.wifiBusy === modelData.ssid)
            expanded: wp.expanded === modelData.ssid
            showMore: modelData.known && !modelData.active
            mode: (wp.forcePass === modelData.ssid || (!modelData.known && modelData.sec === "SECURED")) && !modelData.active ? "pass" : "actions"
            note: modelData.sec === "ENTERPRISE" && !modelData.known ? "Red empresarial (usuario y contraseña). Configurala en los ajustes avanzados." : (wp.forcePass === modelData.ssid ? "La contraseña guardada no funcionó. Escribila de nuevo." : "")
            actions: modelData.active
                ? [{ id: "forget", label: "Olvidar", danger: true }, { id: "disconnect", label: "Desconectar", primary: true }]
                : (modelData.sec === "ENTERPRISE" && !modelData.known
                    ? [{ id: "advanced", label: "Ajustes avanzados", primary: true }]
                    : [{ id: "forget", label: "Olvidar", danger: true }, { id: "connect", label: "Conectar", primary: true }])
            onTapped: wp.tap(modelData)
            onMore: wp.expanded = wp.expanded === modelData.ssid ? "" : modelData.ssid
            onCancel: {
                wp.expanded = ""
                wp.forcePass = ""
            }
            onSubmit: function(pw) { wp.connect(modelData.ssid, pw) }
            onAction: function(id) {
                wp.expanded = ""
                if (!wp.backend) return
                if (id === "disconnect") wp.backend.wifiDisconnect(function(r) { wp.say(r.msg) })
                else if (id === "forget") wp.backend.wifiForget(modelData.ssid, function(r) { wp.say(r.msg) })
                else if (id === "connect") wp.connect(modelData.ssid, "")
                else if (id === "advanced") wp.act("wifi-advanced")
            }
        }
    }

    Column {
        anchors.centerIn: list
        spacing: 8
        visible: !wp.radio || (wp.nets.length === 0 && !(wp.backend && wp.backend.wifiScanning))
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: wp.radio ? "\u{F092E}" : "\u{F05AA}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 40
            color: wp.pal.heroSub
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: wp.radio ? "NO HAY REDES A LA VISTA" : "ENCENDÉ EL WI-FI"
            font.family: "Michroma"
            font.pixelSize: 10
            color: wp.pal.heroSub
        }
    }

    Rectangle {
        anchors.bottom: footLink.top
        anchors.bottomMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 40, toastText.implicitWidth + 30)
        height: 32
        radius: 16
        antialiasing: true
        color: wp.pal.field
        border.width: 1
        border.color: wp.pal.glow
        opacity: wp.toast.length ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        Text {
            id: toastText
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - 24)
            elide: Text.ElideRight
            text: wp.toast
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 12
            color: wp.pal.text
        }
    }

    Text {
        id: footLink
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: "\u{F0493}  Ajustes avanzados"
        font.family: "Exo 2"
        font.weight: Font.DemiBold
        font.pixelSize: 12
        color: footArea.containsMouse ? wp.pal.glow : wp.pal.heroSub
        MouseArea {
            id: footArea
            anchors.fill: parent
            anchors.margins: -8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: wp.act("wifi-advanced")
        }
    }
}
