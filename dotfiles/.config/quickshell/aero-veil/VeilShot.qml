import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import "Lang.js" as L

Item {
    id: shot
    property var core
    property string file: ""
    readonly property real diag: Math.sqrt(width * width + height * height)
    readonly property real hold: core.hold
    readonly property real open: core.open
    readonly property string kind: core.kind
    readonly property bool theme: kind === "theme"
    readonly property bool night: kind === "night"
    readonly property bool day: kind === "day"
    readonly property color tint: core.tint
    readonly property color glow: night ? "#a9c8ff" : day ? "#ffe3a3" : Qt.lighter(core.tint, 1.55)
    readonly property real wave: Math.sin(open * Math.PI)
    readonly property real decor: theme ? Math.max(0, 1 - open * 1.8) : Math.max(0, 1 - open * 2.4)
    readonly property real edge: diag * 0.16
    readonly property real sweepX: diag / 2 - open * (diag + edge)
    readonly property real irisR: open * diag * 0.6
    property real clock: 0

    NumberAnimation on clock {
        running: shot.core.active
        from: 0
        to: 1
        duration: 16000
        loops: Animation.Infinite
    }

    function rnd(i, s) {
        var x = Math.sin(i * 127.1 + s * 311.7) * 43758.5453
        return x - Math.floor(x)
    }

    function cyc(i, speed, seed) {
        var x = shot.clock * speed + rnd(i, seed)
        return x - Math.floor(x)
    }

    Image {
        id: src
        anchors.fill: parent
        visible: false
        layer.enabled: true
        source: shot.core.hasShot && shot.file ? "file://" + shot.file + "?" + shot.core.stamp : ""
        cache: false
        asynchronous: false
        smooth: true
    }

    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            visible: shot.theme
            width: shot.irisR * 2
            height: width
            radius: width / 2
            x: shot.width / 2 - shot.irisR
            y: shot.height / 2 - shot.irisR
            color: "#ffffff"
        }

        Item {
            visible: !shot.theme
            x: shot.width / 2
            y: shot.height / 2
            rotation: 16
            Rectangle {
                x: shot.sweepX
                y: -shot.diag
                width: shot.diag * 2
                height: shot.diag * 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#00ffffff" }
                    GradientStop { position: shot.edge / (shot.diag * 2); color: "#ffffffff" }
                    GradientStop { position: 1.0; color: "#ffffffff" }
                }
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: src
        visible: shot.core.hasShot
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 40
        blur: shot.hold * (shot.theme ? 0.5 : 0.3) * (1 - shot.open)
        brightness: shot.night ? -0.3 * shot.hold : shot.day ? 0.1 * shot.hold : -0.05 * shot.hold
        saturation: shot.theme ? -0.4 * shot.hold : shot.night ? -0.25 * shot.hold : 0.1 * shot.hold
        maskEnabled: shot.open > 0.001
        maskSource: mask
        maskInverted: true
        maskThresholdMin: 0.5
        maskSpreadAtMin: shot.theme ? 0.08 : 0.5
    }

    Rectangle {
        anchors.fill: parent
        color: shot.tint
        opacity: shot.hold * shot.core.strength * shot.decor
    }

    Shape {
        anchors.fill: parent
        visible: shot.core.active && !shot.day
        opacity: shot.hold * shot.decor * (shot.theme ? 0.75 : 0.45)
        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: shot.width / 2; centerY: shot.height / 2; centerRadius: shot.diag * 0.62
                focalX: shot.width / 2; focalY: shot.height / 2
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.45; color: "#14050a14" }
                GradientStop { position: 1.0; color: "#c0050a14" }
            }
            startX: 0; startY: 0
            PathLine { x: shot.width; y: 0 }
            PathLine { x: shot.width; y: shot.height }
            PathLine { x: 0; y: shot.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Item {
        id: themeFx
        anchors.fill: parent
        visible: shot.theme && shot.core.active

        Rectangle {
            x: -400 + shot.cyc(0, 9, 3) * (shot.width + 800)
            y: shot.height / 2 - height / 2
            width: 260
            height: shot.diag * 1.4
            rotation: 18
            opacity: shot.hold * shot.decor * 0.8
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00ffffff" }
                GradientStop { position: 0.5; color: "#38ffffff" }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }

        Repeater {
            model: 28
            delegate: Rectangle {
                required property int index
                readonly property real size: 10 + shot.rnd(index, 4) * 38
                readonly property real p: shot.cyc(index, 3 + shot.rnd(index, 5) * 4, 2)
                width: size
                height: size
                radius: size / 2
                x: shot.rnd(index, 1) * shot.width + Math.sin(p * Math.PI * 4 + index) * 24
                y: shot.height + 40 - p * (shot.height + 140)
                opacity: shot.hold * shot.decor * (0.35 + shot.rnd(index, 6) * 0.5) * Math.min(1, (1 - p) * 4)
                border.width: 1.5
                border.color: Qt.rgba(1, 1, 1, 0.75)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.35) }
                    GradientStop { position: 0.7; color: Qt.rgba(shot.glow.r, shot.glow.g, shot.glow.b, 0.18) }
                    GradientStop { position: 1.0; color: Qt.rgba(shot.tint.r, shot.tint.g, shot.tint.b, 0.45) }
                }
                Rectangle {
                    x: parent.width * 0.2
                    y: parent.height * 0.12
                    width: parent.width * 0.42
                    height: parent.height * 0.26
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.75)
                }
            }
        }

        Item {
            id: orb
            width: 200
            height: 200
            x: shot.width / 2 - width / 2
            y: shot.height / 2 - height / 2
            scale: (0.35 + 0.65 * shot.hold) * (1 + shot.open * 2.2)
            opacity: Math.min(1, shot.hold * 1.4) * Math.max(0, 1 - shot.open * 2.2)

            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    readonly property real pulse: (shot.clock * 10 + index / 3) % 1
                    anchors.centerIn: parent
                    width: parent.width * (1 + pulse * 1.3)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 3
                    border.color: shot.glow
                    opacity: (1 - pulse) * 0.6
                }
            }

            Shape {
                anchors.fill: parent
                anchors.margins: -26
                rotation: shot.clock * 360 * 9
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: shot.glow
                    strokeWidth: 5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 126; centerY: 126; radiusX: 122; radiusY: 122; startAngle: 0; sweepAngle: 110 }
                }
                ShapePath {
                    strokeColor: Qt.rgba(1, 1, 1, 0.85)
                    strokeWidth: 3
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 126; centerY: 126; radiusX: 122; radiusY: 122; startAngle: 180; sweepAngle: 70 }
                }
            }

            Shape {
                anchors.fill: parent
                anchors.margins: -10
                rotation: -shot.clock * 360 * 6
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Qt.rgba(shot.glow.r, shot.glow.g, shot.glow.b, 0.7)
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 110; centerY: 110; radiusX: 106; radiusY: 106; startAngle: 40; sweepAngle: 200 }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                border.width: 2
                border.color: Qt.rgba(1, 1, 1, 0.9)
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(shot.tint, 1.7) }
                    GradientStop { position: 0.45; color: shot.tint }
                    GradientStop { position: 1.0; color: Qt.darker(shot.tint, 1.8) }
                }
                Rectangle {
                    x: parent.width * 0.16
                    y: parent.height * 0.06
                    width: parent.width * 0.68
                    height: parent.height * 0.42
                    radius: height / 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.85) }
                        GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.05) }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.72
                    width: parent.width * 0.5
                    height: parent.height * 0.16
                    radius: height / 2
                    color: Qt.rgba(shot.glow.r, shot.glow.g, shot.glow.b, 0.55)
                }
            }
        }

        Rectangle {
            readonly property real r: shot.irisR
            visible: shot.open > 0.001
            x: shot.width / 2 - r
            y: shot.height / 2 - r
            width: r * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 26
            border.color: Qt.rgba(shot.glow.r, shot.glow.g, shot.glow.b, 0.28)
            opacity: shot.wave
        }

        Rectangle {
            readonly property real r: shot.irisR
            visible: shot.open > 0.001
            x: shot.width / 2 - r
            y: shot.height / 2 - r
            width: r * 2
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 6
            border.color: Qt.rgba(1, 1, 1, 0.95)
            opacity: shot.wave
        }

        Repeater {
            model: 22
            delegate: Rectangle {
                required property int index
                readonly property real ang: index / 22 * Math.PI * 2 + shot.rnd(index, 8) * 0.3
                readonly property real dist: shot.irisR * (1.0 + shot.rnd(index, 9) * 0.12) + 18
                visible: shot.open > 0.001
                width: 6 + shot.rnd(index, 10) * 8
                height: width
                radius: width / 2
                x: shot.width / 2 + Math.cos(ang) * dist - width / 2
                y: shot.height / 2 + Math.sin(ang) * dist - height / 2
                color: index % 3 === 0 ? "#ffffff" : shot.glow
                opacity: shot.wave * 0.9
            }
        }
    }

    Item {
        id: nightFx
        anchors.fill: parent
        visible: shot.night && shot.core.active
        opacity: shot.decor

        Rectangle {
            anchors.fill: parent
            opacity: shot.hold
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#c00a1438" }
                GradientStop { position: 0.55; color: "#600a1a46" }
                GradientStop { position: 1.0; color: "#20081430" }
            }
        }

        Repeater {
            model: 90
            delegate: Rectangle {
                required property int index
                width: 1.5 + shot.rnd(index, 11) * 2.5
                height: width
                radius: width / 2
                x: shot.rnd(index, 12) * shot.width
                y: shot.rnd(index, 13) * shot.height * 0.72
                color: index % 7 === 0 ? "#cfe0ff" : "#ffffff"
                opacity: shot.hold * (0.35 + 0.65 * Math.abs(Math.sin(shot.clock * Math.PI * 2 * (8 + shot.rnd(index, 14) * 14) + index)))
            }
        }

        Item {
            id: moon
            width: 150
            height: 150
            x: shot.width * 0.76
            y: shot.height * (0.16 + (1 - shot.hold) * 0.3)

            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    anchors.centerIn: parent
                    width: parent.width * (1.25 + index * 0.4)
                    height: width
                    radius: width / 2
                    color: Qt.rgba(0.66, 0.78, 1, 0.12 - index * 0.03)
                }
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0; x2: 150; y2: 150
                        GradientStop { position: 0.0; color: "#ffffff" }
                        GradientStop { position: 1.0; color: "#b9cdf5" }
                    }
                    startX: 75; startY: 0
                    PathArc { x: 75; y: 150; radiusX: 75; radiusY: 75; direction: PathArc.Clockwise }
                    PathArc { x: 75; y: 0; radiusX: 52; radiusY: 75; direction: PathArc.Counterclockwise }
                }
            }
        }
    }

    Item {
        id: dayFx
        anchors.fill: parent
        visible: shot.day && shot.core.active
        opacity: shot.decor
        readonly property real sx: shot.width * 0.8
        readonly property real sy: shot.height * (0.2 + (1 - shot.hold) * 0.25)

        Shape {
            anchors.fill: parent
            opacity: shot.hold
            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: dayFx.sx; centerY: dayFx.sy; centerRadius: shot.diag * 0.7
                    focalX: dayFx.sx; focalY: dayFx.sy
                    GradientStop { position: 0.0; color: "#b0fff4cc" }
                    GradientStop { position: 0.35; color: "#40ffe9b0" }
                    GradientStop { position: 1.0; color: "#00ffffff" }
                }
                startX: 0; startY: 0
                PathLine { x: shot.width; y: 0 }
                PathLine { x: shot.width; y: shot.height }
                PathLine { x: 0; y: shot.height }
                PathLine { x: 0; y: 0 }
            }
        }

        Repeater {
            model: 6
            delegate: Rectangle {
                required property int index
                readonly property real t: 0.35 + index * 0.28
                readonly property real size: [90, 40, 130, 26, 70, 180][index]
                width: size
                height: size
                radius: size / 2
                x: dayFx.sx + (shot.width / 2 - dayFx.sx) * t - size / 2
                y: dayFx.sy + (shot.height / 2 - dayFx.sy) * t - size / 2
                color: ["#33ffe7a6", "#40ffd1f0", "#22b8f0ff", "#55fff4c2", "#2aa6ffd8", "#18ffffff"][index]
                border.width: 1
                border.color: "#30ffffff"
                opacity: shot.hold * 0.9
            }
        }

        Rectangle {
            x: dayFx.sx - width / 2
            y: dayFx.sy - height / 2
            width: shot.width * 0.9 * shot.hold
            height: 3
            radius: 1.5
            opacity: shot.hold * 0.7
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00fff2c8" }
                GradientStop { position: 0.5; color: "#fffff6dc" }
                GradientStop { position: 1.0; color: "#00fff2c8" }
            }
        }

        Item {
            x: dayFx.sx - 70
            y: dayFx.sy - 70
            width: 140
            height: 140
            rotation: shot.clock * 360 * 3

            Repeater {
                model: 12
                delegate: Rectangle {
                    required property int index
                    x: 70 - width / 2
                    y: -34
                    width: 7
                    height: 38 + (index % 2) * 18
                    radius: 3.5
                    color: "#d9ffe39a"
                    transform: Rotation { origin.x: 3.5; origin.y: 104; angle: index * 30 }
                }
            }
        }

        Rectangle {
            x: dayFx.sx - 60
            y: dayFx.sy - 60
            width: 120
            height: 120
            radius: 60
            border.width: 3
            border.color: "#fffff8e6"
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#fffffbe8" }
                GradientStop { position: 0.5; color: "#ffffd66e" }
                GradientStop { position: 1.0; color: "#ffffaa33" }
            }
            Rectangle {
                x: 22; y: 10
                width: 76; height: 40
                radius: 20
                color: "#99ffffff"
            }
        }

        Repeater {
            model: 18
            delegate: Rectangle {
                required property int index
                readonly property real p: shot.cyc(index, 2 + shot.rnd(index, 15) * 3, 16)
                width: 3 + shot.rnd(index, 17) * 5
                height: width
                radius: width / 2
                x: shot.rnd(index, 18) * shot.width
                y: shot.height - p * shot.height * 0.9
                color: "#fff6d8"
                opacity: shot.hold * (1 - p) * 0.8
            }
        }
    }

    Item {
        visible: !shot.theme && shot.core.active && shot.open > 0.001
        x: shot.width / 2
        y: shot.height / 2
        rotation: 16
        Rectangle {
            x: shot.sweepX + shot.edge * 0.5 - 70
            y: -shot.diag
            width: 140
            height: shot.diag * 2
            opacity: shot.wave
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00ffffff" }
                GradientStop { position: 0.5; color: Qt.rgba(shot.glow.r, shot.glow.g, shot.glow.b, 0.85) }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }
        Rectangle {
            x: shot.sweepX + shot.edge * 0.5 - 2
            y: -shot.diag
            width: 4
            height: shot.diag * 2
            color: "#ffffff"
            opacity: shot.wave
        }
    }

    Rectangle {
        anchors.centerIn: caption
        width: caption.width + 70
        height: caption.height + 34
        radius: height / 2
        visible: caption.visible
        opacity: caption.opacity
        scale: caption.scale
        color: "#b30a1226"
        border.width: 1.5
        border.color: Qt.rgba(shot.glow.r, shot.glow.g, shot.glow.b, 0.8)
        Rectangle {
            x: 20; y: 3
            width: parent.width - 40
            height: parent.height * 0.42
            radius: height / 2
            color: "#1fffffff"
        }
    }

    Column {
        id: caption
        anchors.horizontalCenter: parent.horizontalCenter
        y: shot.theme ? shot.height / 2 + 160 : shot.height * 0.5 - 30
        spacing: 10
        visible: shot.core.active && shot.core.label.length > 0
        opacity: Math.min(1, shot.hold * 1.5) * Math.max(0, 1 - shot.open * 3)
        scale: 0.92 + 0.08 * shot.hold

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: shot.core.label
            font.family: "Michroma"
            font.pixelSize: 30
            font.letterSpacing: 9
            color: "#ffffff"
            style: Text.Raised
            styleColor: "#990b0d12"
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 260 * shot.hold
            height: 3
            radius: 1.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00ffffff" }
                GradientStop { position: 0.5; color: shot.glow }
                GradientStop { position: 1.0; color: "#00ffffff" }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: shot.theme ? L.t("Pintando la estación…") : shot.night ? L.t("Bajando las luces…") : L.t("Encendiendo la estación…")
            font.family: "Exo 2"
            font.weight: Font.Bold
            font.pixelSize: 15
            font.letterSpacing: 1
            color: Qt.rgba(1, 1, 1, 0.9)
            style: Text.Raised
            styleColor: "#880b0d12"
        }
    }
}
