import QtQuick

Item {
    id: core
    property bool active: false
    property bool hasShot: false
    property int stamp: 0
    property string ident: ""
    property string lastCmd: ""
    property string kind: "theme"
    property string label: ""
    property color tint: "#3d9be9"
    property real strength: 0
    property real hold: 0
    property real open: 0
    property real fade: 1 - open
    property double coveredAt: 0
    property int minHold: 720
    signal report(string line)

    function handle(text) {
        var p = String(text).trim().split(/\s+/)
        if (p.length < 2 || p[0] + p[1] === lastCmd) return
        lastCmd = p[0] + p[1]
        if (p[0] === "cover") {
            var k = p[4] || "theme"
            cover(p[1], p[2] || "3d9be9", Number(p[3] || 0), ["theme", "night", "day"].indexOf(k) >= 0 ? k : "theme",
                  p.slice(5).join(" ").replace(/_/g, " "))
        } else if (p[0] === "reveal") {
            reveal(p[1])
        }
    }

    function cover(id, hex, amount, k, text) {
        revealAnim.stop()
        holdAnim.stop()
        delayReveal.stop()
        ident = id
        kind = k
        label = text
        tint = "#" + hex
        strength = Math.max(0, Math.min(0.4, amount))
        hold = 0
        open = 0
        coveredAt = Date.now()
        stamp++
        hasShot = true
        active = true
        holdAnim.start()
        ack.restart()
    }

    function reveal(id) {
        if (!active || (id && id !== ident) || revealAnim.running) return
        ack.stop()
        var wait = minHold - (Date.now() - coveredAt)
        if (wait > 20) {
            delayReveal.interval = wait
            delayReveal.restart()
            return
        }
        revealAnim.duration = kind === "theme" ? 980 : 1100
        revealAnim.restart()
    }

    Timer {
        id: ack
        interval: 70
        onTriggered: core.report("covered " + core.ident)
    }

    Timer {
        id: delayReveal
        onTriggered: core.reveal(core.ident)
    }

    Timer {
        interval: 6000
        running: core.active && !revealAnim.running
        onTriggered: core.reveal(core.ident)
    }

    NumberAnimation {
        id: holdAnim
        target: core
        property: "hold"
        from: 0
        to: 1
        duration: 700
        easing.type: Easing.OutCubic
    }

    NumberAnimation {
        id: revealAnim
        target: core
        property: "open"
        from: 0
        to: 1
        duration: 980
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.6, 0.0, 0.2, 1.0, 1.0, 1.0]
        onFinished: {
            core.active = false
            core.hasShot = false
            core.hold = 0
            core.open = 0
            core.report("idle " + core.ident)
        }
    }
}
