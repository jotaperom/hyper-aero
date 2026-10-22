import QtQuick
import "Lang.js" as L

Item {
    id: td
    property var pal
    property var backend
    property bool live: false
    property var now: new Date()
    readonly property var weather: backend && backend.weather ? backend.weather : ({ ok: false })
    readonly property var days: [L.t("DOMINGO"), L.t("LUNES"), L.t("MARTES"), L.t("MIÉRCOLES"), L.t("JUEVES"), L.t("VIERNES"), L.t("SÁBADO")]
    readonly property var months: [L.t("ENERO"), L.t("FEBRERO"), L.t("MARZO"), L.t("ABRIL"), L.t("MAYO"), L.t("JUNIO"), L.t("JULIO"), L.t("AGOSTO"), L.t("SEPTIEMBRE"), L.t("OCTUBRE"), L.t("NOVIEMBRE"), L.t("DICIEMBRE")]
    signal closeRequested()
    signal pageRequested(int p)

    function two(n) {
        return n < 10 ? "0" + n : "" + n
    }

    function greeting() {
        var h = now.getHours()
        return h >= 5 && h < 12 ? L.t("Buenos días") : (h < 19 && h >= 12 ? L.t("Buenas tardes") : L.t("Buenas noches"))
    }

    function cells() {
        var first = new Date(now.getFullYear(), now.getMonth(), 1).getDay()
        var count = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
        var lead = (first + 6) % 7
        var out = []
        for (var i = 0; i < lead; i++) out.push(0)
        for (var d = 1; d <= count; d++) out.push(d)
        while (out.length % 7) out.push(0)
        return out
    }

    function scrollBy(d) {
        flick.contentY = Math.max(0, Math.min(Math.max(0, flick.contentHeight - flick.height), flick.contentY + d))
    }

    function focusInput() {
        noteEdit.forceActiveFocus()
        noteEdit.cursorPosition = noteEdit.text.length
    }

    function typeIn(t) {
        noteEdit.insert(noteEdit.cursorPosition, t)
        focusInput()
    }

    function backspace() {
        if (noteEdit.cursorPosition > 0) noteEdit.remove(noteEdit.cursorPosition - 1, noteEdit.cursorPosition)
        focusInput()
    }

    function send(text) {
        if (backend) backend.noteSave(noteEdit.text)
        saved.restart()
    }

    onLiveChanged: {
        if (!live || !backend) return
        backend.noteLoad()
        backend.weatherRefresh()
    }

    Timer {
        interval: 1000
        repeat: true
        running: td.live
        triggeredOnStart: true
        onTriggered: td.now = new Date()
    }

    Timer {
        interval: 900000
        repeat: true
        running: td.live
        onTriggered: if (td.backend) td.backend.weatherRefresh()
    }

    Timer {
        id: autosave
        interval: 900
        onTriggered: if (td.backend) td.backend.noteSave(noteEdit.text)
    }

    Timer {
        id: saved
        interval: 1600
    }

    Connections {
        target: td.backend
        function onNoteChanged() {
            if (!noteEdit.activeFocus && noteEdit.text !== td.backend.note) noteEdit.text = td.backend.note
        }
    }

    component Panel: Rectangle {
        radius: 20
        antialiasing: true
        border.width: 1
        border.color: td.pal.tileBorder
        gradient: Gradient {
            GradientStop { position: 0.0; color: td.pal.tile0 }
            GradientStop { position: 0.48; color: td.pal.tile1 }
            GradientStop { position: 0.52; color: td.pal.tile2 }
            GradientStop { position: 1.0; color: td.pal.tile3 }
        }
        Rectangle {
            x: 1; y: 1
            width: parent.width - 2
            height: Math.min(parent.height * 0.46, 40)
            radius: 19
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, td.pal.glossTop) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.height + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            x: 14
            y: 6
            width: flick.width - 28
            spacing: 12

            Column {
                x: 6
                spacing: 2
                Text {
                    text: L.t("HOY")
                    font.family: "Michroma"
                    font.pixelSize: 16
                    font.letterSpacing: 2
                    color: td.pal.hero
                    style: Text.Raised
                    styleColor: td.pal.heroShadow
                }
                Text {
                    text: L.f("%1  ·  %2 DE %3", td.days[td.now.getDay()], td.now.getDate(), td.months[td.now.getMonth()])
                    font.family: "JetBrainsMono Nerd Font"
                    font.weight: Font.Bold
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    color: td.pal.heroSub
                }
            }

            Panel {
                width: col.width
                height: 112
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Row {
                        spacing: 6
                        Text {
                            text: td.two(td.now.getHours()) + ":" + td.two(td.now.getMinutes())
                            font.family: "Michroma"
                            font.pixelSize: 40
                            color: td.pal.text
                        }
                        Text {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            text: td.two(td.now.getSeconds())
                            font.family: "Michroma"
                            font.pixelSize: 14
                            color: td.pal.accent
                        }
                    }
                    Text {
                        text: td.greeting() + (td.backend && td.backend.user ? ", " + td.backend.user : "")
                        font.family: "Exo 2"
                        font.weight: Font.Bold
                        font.pixelSize: 13
                        color: td.pal.muted
                    }
                }
                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 0
                    visible: !!td.weather.ok
                    Row {
                        anchors.right: parent.right
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: td.weather.icon || ""
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 26
                            color: td.pal.accent
                        }
                        Text {
                            text: (td.weather.temp || "--") + "°"
                            font.family: "Michroma"
                            font.pixelSize: 26
                            color: td.pal.text
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        text: (td.weather.hi || "--") + "° / " + (td.weather.lo || "--") + "°"
                        font.family: "JetBrainsMono Nerd Font"
                        font.weight: Font.Bold
                        font.pixelSize: 10
                        color: td.pal.muted
                    }
                    Text {
                        anchors.right: parent.right
                        width: Math.min(implicitWidth, col.width * 0.42)
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                        text: td.weather.place || ""
                        font.family: "Exo 2"
                        font.pixelSize: 11
                        color: td.pal.muted
                    }
                }
            }

            Panel {
                width: col.width
                height: calGrid.height + 50
                Text {
                    x: 16
                    y: 12
                    text: td.months[td.now.getMonth()] + " " + td.now.getFullYear()
                    font.family: "Michroma"
                    font.pixelSize: 11
                    color: td.pal.text
                }
                Grid {
                    id: calGrid
                    x: 12
                    y: 34
                    width: parent.width - 24
                    columns: 7
                    readonly property real cw: width / 7
                    Repeater {
                        model: L.t("L K M J V S D").split(" ")
                        delegate: Text {
                            required property string modelData
                            width: calGrid.cw
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            font.family: "JetBrainsMono Nerd Font"
                            font.weight: Font.Bold
                            font.pixelSize: 10
                            color: td.pal.muted
                        }
                    }
                    Repeater {
                        model: td.cells()
                        delegate: Item {
                            required property int modelData
                            readonly property bool today: modelData === td.now.getDate()
                            width: calGrid.cw
                            height: 24
                            Rectangle {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                radius: 11
                                visible: parent.today
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: td.pal.on0 }
                                    GradientStop { position: 1.0; color: td.pal.on2 }
                                }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData > 0 ? parent.modelData : ""
                                font.family: "Exo 2"
                                font.weight: parent.today ? Font.Black : Font.Normal
                                font.pixelSize: 12
                                color: parent.today ? "#ffffff" : td.pal.text
                            }
                        }
                    }
                }
            }

            MediaCard {
                width: col.width
                pal: td.pal
                media: td.backend ? td.backend.media : ({})
                onCmd: function(c) { if (td.backend) td.backend.mediaCmd(c) }
            }

            Panel {
                width: col.width
                height: 150
                Row {
                    x: 16
                    y: 12
                    spacing: 8
                    Text {
                        text: "\u{F1781}"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: td.pal.accent
                    }
                    Text {
                        text: L.t("NOTA RÁPIDA")
                        font.family: "Michroma"
                        font.pixelSize: 11
                        color: td.pal.text
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    y: 13
                    text: saved.running ? L.t("Guardada ✓") : L.t("Se guarda sola")
                    font.family: "Exo 2"
                    font.pixelSize: 11
                    color: saved.running ? td.pal.accent : td.pal.muted
                }
                Rectangle {
                    x: 12
                    y: 38
                    width: parent.width - 24
                    height: parent.height - 50
                    radius: 14
                    color: td.pal.field
                    border.width: 1
                    border.color: noteEdit.activeFocus ? td.pal.onBorder : td.pal.tileBorder
                    clip: true
                    TextEdit {
                        id: noteEdit
                        anchors.fill: parent
                        anchors.margins: 10
                        wrapMode: TextEdit.Wrap
                        font.family: "Exo 2"
                        font.pixelSize: 13
                        color: td.pal.text
                        selectByMouse: true
                        onTextChanged: if (activeFocus) autosave.restart()
                        Text {
                            visible: !noteEdit.text.length
                            text: L.t("Escribí algo para no olvidarlo…")
                            font: noteEdit.font
                            color: td.pal.muted
                        }
                    }
                }
            }
        }
    }
}
