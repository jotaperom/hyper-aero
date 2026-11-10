import QtQuick
import QtQuick.Particles

Item {
    id: fx
    property string kind: "clear"
    property bool heavy: false
    property bool night: false
    property real density: 1
    readonly property bool wet: kind === "rain" || kind === "drizzle" || kind === "storm"
    readonly property real rate: (kind === "drizzle" ? 70 : (heavy || kind === "storm" ? 260 : 150)) * density
    readonly property real gloom: kind === "storm" ? 0.22 : (wet ? 0.14 : (kind === "cloudy" ? 0.08 : (kind === "fog" ? 0.06 : 0)))

    visible: kind !== "clear" && density > 0
    clip: true

    Rectangle {
        anchors.fill: parent
        color: fx.night ? Qt.rgba(0, 0.02, 0.06, fx.gloom * 1.4) : Qt.rgba(0.12, 0.18, 0.28, fx.gloom)
        Behavior on color { ColorAnimation { duration: 2000 } }
    }

    Item {
        anchors.fill: parent
        visible: fx.kind === "fog" || fx.kind === "cloudy" || fx.wet
        opacity: fx.kind === "fog" ? 0.9 : (fx.kind === "cloudy" ? 0.45 : 0.3)
        Repeater {
            model: 3
            delegate: Image {
                required property int index
                source: "fx/fog.png"
                width: fx.width * 1.8
                height: fx.height * (0.7 + index * 0.15)
                y: fx.height * (0.18 + index * 0.26) - height / 2
                opacity: fx.night ? 0.55 : 0.9
                NumberAnimation on x {
                    from: -fx.width * 0.6 + index * 120
                    to: index % 2 ? -fx.width * 0.05 : -fx.width * 0.5
                    duration: 90000 + index * 30000
                    loops: Animation.Infinite
                    easing.type: Easing.InOutSine
                    running: fx.visible
                }
            }
        }
    }

    ParticleSystem {
        id: sky
        anchors.fill: parent
        running: fx.visible && (fx.wet || fx.kind === "snow")
    }

    ImageParticle {
        system: sky
        groups: ["rain"]
        source: "fx/rain.png"
        color: fx.night ? "#9fc4ff" : "#ffffff"
        alpha: fx.kind === "drizzle" ? 0.35 : 0.55
        autoRotation: true
        entryEffect: ImageParticle.None
    }

    Emitter {
        system: sky
        group: "rain"
        enabled: fx.wet
        x: -fx.width * 0.1
        y: -60
        width: fx.width * 1.2
        height: 1
        emitRate: fx.rate
        lifeSpan: 1400
        size: fx.kind === "drizzle" ? 34 : 54
        sizeVariation: 16
        velocity: AngleDirection { angle: 100; angleVariation: 3; magnitude: fx.kind === "drizzle" ? 700 : 1100; magnitudeVariation: 200 }
    }

    ImageParticle {
        system: sky
        groups: ["drop"]
        source: "fx/drop.png"
        alpha: 0.85
        entryEffect: ImageParticle.Fade
    }

    Emitter {
        system: sky
        group: "drop"
        enabled: fx.wet && fx.density > 0.4
        anchors.fill: parent
        emitRate: (fx.kind === "drizzle" ? 3 : 6) * fx.density
        lifeSpan: 7000
        lifeSpanVariation: 3000
        size: 22
        sizeVariation: 12
        velocity: PointDirection { y: 6; yVariation: 10 }
        acceleration: PointDirection { y: 4; yVariation: 6 }
    }

    ImageParticle {
        system: sky
        groups: ["snow"]
        source: "fx/flake.png"
        color: "#ffffff"
        alpha: 0.8
        rotationVariation: 180
        entryEffect: ImageParticle.Fade
    }

    Emitter {
        system: sky
        group: "snow"
        enabled: fx.kind === "snow"
        x: -fx.width * 0.1
        y: -30
        width: fx.width * 1.2
        height: 1
        emitRate: (fx.heavy ? 90 : 45) * fx.density
        lifeSpan: 14000
        size: 10
        sizeVariation: 8
        velocity: AngleDirection { angle: 90; angleVariation: 20; magnitude: 70; magnitudeVariation: 30 }
    }

    Wander {
        system: sky
        groups: ["snow"]
        xVariance: 60
        pace: 40
    }

    Rectangle {
        id: flash
        anchors.fill: parent
        color: "#e8f2ff"
        opacity: 0
        SequentialAnimation {
            id: bolt
            NumberAnimation { target: flash; property: "opacity"; to: 0.32; duration: 60 }
            NumberAnimation { target: flash; property: "opacity"; to: 0.05; duration: 90 }
            NumberAnimation { target: flash; property: "opacity"; to: 0.22; duration: 50 }
            NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 600; easing.type: Easing.OutCubic }
        }
    }

    Timer {
        running: fx.visible && fx.kind === "storm"
        repeat: true
        interval: 7000
        onTriggered: {
            interval = 6000 + Math.random() * 14000
            bolt.start()
        }
    }
}
