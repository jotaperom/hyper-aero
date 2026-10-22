import QtQuick
import QtQuick.Shapes

Shape {
    id: dl
    property color color: "#735a6270"
    height: 1
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
        strokeColor: dl.color
        strokeWidth: 1
        strokeStyle: ShapePath.DashLine
        dashPattern: [3, 3]
        fillColor: "transparent"
        startX: 0; startY: 0.5
        PathLine { x: dl.width; y: 0.5 }
    }
}
