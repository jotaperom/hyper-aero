import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: s
    property var glow
    property rect box: Qt.rect(0, 0, 0, 0)
    property var pts: [Qt.point(0, 0)]
    property bool warmth: false
    property bool on: true
    readonly property var dot: [Qt.point(0, 0)]

    screen: glow.screen
    visible: on && glow.live && box.width >= 2 && box.height >= 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "aerofx-glow"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}
    anchors {
        top: true
        left: true
    }
    margins {
        left: s.box.x
        top: s.box.y
    }
    implicitWidth: Math.max(2, s.box.width)
    implicitHeight: Math.max(2, s.box.height)

    Item {
        id: wrap
        readonly property int m: 44
        x: -m
        y: -m
        width: s.box.width + m * 2
        height: s.box.height + m * 2
        opacity: s.glow.fade
        layer.enabled: s.visible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: s.glow.c1
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowOpacity: 0.75 + 0.25 * s.glow.lv
            shadowScale: 1.0
            blurMax: 48
            brightness: 0.06 + 0.1 * s.glow.lv
            autoPaddingEnabled: false
        }

        Shape {
            x: wrap.m - s.box.x
            y: wrap.m - s.box.y
            width: s.box.x + s.box.width + wrap.m
            height: s.box.y + s.box.height + wrap.m
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: Qt.rgba(s.glow.c1.r, s.glow.c1.g, s.glow.c1.b, 0.28 + 0.2 * s.glow.lv)
                strokeWidth: 5 + 3 * s.glow.lv
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.FlatCap
                PathPolyline { path: s.pts }
            }

            ShapePath {
                strokeColor: s.glow.core
                strokeWidth: 1.5 + 0.8 * s.glow.lv
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin
                capStyle: ShapePath.FlatCap
                PathPolyline { path: s.pts }
            }

            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: s.glow.ox + s.glow.ow * 0.12
                    x2: s.glow.ox + s.glow.ow * 0.88
                    y1: 0
                    y2: 0
                    GradientStop { position: 0.0; color: "#00ff6f9c" }
                    GradientStop { position: 0.3; color: Qt.rgba(s.glow.warm.r, s.glow.warm.g, s.glow.warm.b, 0.3 * s.glow.heat) }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 0.62, 0.82, 0.42 * s.glow.heat) }
                    GradientStop { position: 0.7; color: Qt.rgba(s.glow.warm.r, s.glow.warm.g, s.glow.warm.b, 0.3 * s.glow.heat) }
                    GradientStop { position: 1.0; color: "#00ff6f9c" }
                }
                PathPolyline { path: s.warmth ? s.glow.haze : s.dot }
            }

            ShapePath {
                strokeColor: "transparent"
                fillGradient: LinearGradient {
                    x1: s.glow.ox + s.glow.ow * 0.18
                    x2: s.glow.ox + s.glow.ow * 0.82
                    y1: 0
                    y2: 0
                    GradientStop { position: 0.0; color: "#00ff6f9c" }
                    GradientStop { position: 0.32; color: Qt.rgba(s.glow.warm.r, s.glow.warm.g, s.glow.warm.b, s.glow.heat) }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 0.94, 0.86, s.glow.heat) }
                    GradientStop { position: 0.68; color: Qt.rgba(s.glow.warm.r, s.glow.warm.g, s.glow.warm.b, s.glow.heat) }
                    GradientStop { position: 1.0; color: "#00ff6f9c" }
                }
                PathPolyline { path: s.warmth ? s.glow.ribbon : s.dot }
            }
        }
    }
}
