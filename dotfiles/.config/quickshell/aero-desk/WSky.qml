import QtQuick
import QtQuick.Shapes

Card {
    id: w
    property var core
    readonly property var sk: core ? core.sky : ({ ok: false })
    readonly property real frac: sk.ok ? sk.frac : 0
    readonly property bool night: !!sk.night
    readonly property bool showMoon: night && body.height >= 120
    title: "SKY ARC"
    tag: sk.ok ? sk.tag : "SKY OFFLINE"

    Item {
        id: canvas
        width: parent.width
        height: parent.height - foot.height - (w.showMoon ? 16 : 0) - 4
        readonly property real cx: width / 2
        readonly property real hy: height - 10
        readonly property real rx: width / 2 - 18
        readonly property real ry: Math.max(10, height - 26)
        readonly property real ang: Math.PI * (1 - w.frac)
        readonly property real px: cx + rx * Math.cos(ang)
        readonly property real py: hy - ry * Math.sin(ang)

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: w.pal.sep
                strokeWidth: 1.5
                strokeStyle: ShapePath.DashLine
                dashPattern: [3, 4]
                fillColor: "transparent"
                PathAngleArc {
                    centerX: canvas.cx; centerY: canvas.hy
                    radiusX: canvas.rx; radiusY: canvas.ry
                    startAngle: 180; sweepAngle: 180
                }
            }
            ShapePath {
                strokeColor: w.pal.accent
                strokeWidth: 3
                capStyle: ShapePath.RoundCap
                fillColor: "transparent"
                PathAngleArc {
                    centerX: canvas.cx; centerY: canvas.hy
                    radiusX: canvas.rx; radiusY: canvas.ry
                    startAngle: 180; sweepAngle: 180 * w.frac
                }
            }
            ShapePath {
                strokeColor: w.pal.muted
                strokeWidth: 1
                fillColor: "transparent"
                startX: 0; startY: canvas.hy
                PathLine { x: canvas.width; y: canvas.hy }
            }
        }

        Repeater {
            model: 9
            delegate: Rectangle {
                required property int index
                x: canvas.cx - canvas.rx + index * canvas.rx / 4 - 0.5
                y: canvas.hy + 3
                width: 1
                height: index % 2 ? 3 : 6
                color: w.pal.muted
                opacity: 0.7
            }
        }

        Rectangle {
            x: canvas.cx - canvas.rx - 4
            y: canvas.hy - 4
            width: 8; height: 8; radius: 4
            color: w.pal.accent
        }
        Rectangle {
            x: canvas.cx + canvas.rx - 4
            y: canvas.hy - 4
            width: 8; height: 8; radius: 4
            color: "transparent"
            border.width: 2
            border.color: w.pal.accent
        }

        Repeater {
            model: w.night ? [[0.12, 0.2], [0.3, 0.08], [0.52, 0.28], [0.7, 0.12], [0.86, 0.3], [0.22, 0.45], [0.64, 0.5]] : []
            delegate: Rectangle {
                required property var modelData
                x: canvas.width * modelData[0]
                y: canvas.height * modelData[1]
                width: 2; height: 2; radius: 1
                color: w.pal.ink
                opacity: 0.55
            }
        }

        Rectangle {
            x: canvas.px - width / 2
            y: canvas.py - height / 2
            width: 46; height: 46; radius: 23
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: w.night ? "#336fd3ff" : "#55ffd27a" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: 0.8
        }

        Rectangle {
            id: orb
            x: canvas.px - width / 2
            y: canvas.py - height / 2
            width: 22; height: 22; radius: 11
            antialiasing: true
            clip: true
            border.width: 2
            border.color: w.night ? w.pal.accent : "#ffffff"
            gradient: Gradient {
                GradientStop { position: 0.0; color: w.night ? "#eef3fc" : "#fff3c4" }
                GradientStop { position: 1.0; color: w.night ? "#c9d6ea" : "#ffb13b" }
            }
            Rectangle {
                visible: w.night
                width: parent.width
                height: parent.height
                radius: width / 2
                x: (w.sk.lit !== undefined ? w.sk.lit : 0.5) * parent.width * 1.05
                color: w.pal.muted
                opacity: 0.85
            }
        }
    }

    Item {
        id: foot
        anchors.bottom: parent.bottom
        anchors.bottomMargin: w.showMoon ? 16 : 0
        width: parent.width
        height: 16
        Text {
            anchors.left: parent.left
            text: w.sk.ok ? w.sk.left : ""
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 11
            color: w.pal.ink
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: w.body.width > 250
            text: w.sk.ok ? w.sk.next : ""
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 9
            color: w.pal.accent
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            anchors.right: parent.right
            text: w.sk.ok ? w.sk.right : ""
            font.family: "JetBrainsMono Nerd Font"
            font.weight: Font.Bold
            font.pixelSize: 11
            color: w.pal.ink
        }
    }

    Text {
        visible: w.showMoon
        anchors.bottom: parent.bottom
        text: w.sk.moon || ""
        font.family: "JetBrainsMono Nerd Font"
        font.weight: Font.Bold
        font.pixelSize: 9
        color: w.pal.muted
    }
}
