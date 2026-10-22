import QtQuick
import QtQuick.Shapes

Shape {
    id: bd
    property color c0: "#ffffff"
    property color c1: "#f2f5f9"
    property color c2: "#e2e8f0"
    property color c3: "#f8fafc"
    property color line: "transparent"
    property real lineWidth: 0
    property bool flat: false
    width: 1000
    height: 410
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: bd.line
        strokeWidth: bd.lineWidth
        fillGradient: bd.flat ? null : grad
        fillColor: bd.c1
        startX: 64; startY: 0
        PathLine { x: bd.width - 64; y: 0 }
        PathQuad { x: bd.width; y: 64; controlX: bd.width; controlY: 0 }
        PathLine { x: bd.width; y: 296 }
        PathCubic { x: bd.width - 76; y: 410; control1X: bd.width; control1Y: 372; control2X: bd.width - 30; control2Y: 410 }
        PathLine { x: bd.width - 236; y: 410 }
        PathCubic { x: bd.width - 330; y: 374; control1X: bd.width - 284; control1Y: 410; control2X: bd.width - 296; control2Y: 374 }
        PathLine { x: 330; y: 374 }
        PathCubic { x: 236; y: 410; control1X: 296; control1Y: 374; control2X: 284; control2Y: 410 }
        PathLine { x: 76; y: 410 }
        PathCubic { x: 0; y: 296; control1X: 30; control1Y: 410; control2X: 0; control2Y: 372 }
        PathLine { x: 0; y: 64 }
        PathQuad { x: 64; y: 0; controlX: 0; controlY: 0 }
    }

    LinearGradient {
        id: grad
        x1: 0; y1: 0
        x2: 0; y2: 410
        GradientStop { position: 0.0; color: bd.c0 }
        GradientStop { position: 0.45; color: bd.c1 }
        GradientStop { position: 0.55; color: bd.c2 }
        GradientStop { position: 1.0; color: bd.c3 }
    }
}
