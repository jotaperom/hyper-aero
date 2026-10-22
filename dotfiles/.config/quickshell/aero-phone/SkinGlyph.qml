import QtQuick

Item {
    id: g
    property string kind: "iphone"
    property color ink: "#ffffff"
    property color fill: "#33ffffff"
    width: 64
    height: 64

    Item {
        anchors.fill: parent
        visible: g.kind === "iphone"
        Rectangle { anchors.centerIn: parent; width: 30; height: 56; radius: 8; color: g.fill; border.width: 2; border.color: g.ink }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 8; width: 10; height: 4; radius: 2; color: g.ink }
    }

    Item {
        anchors.fill: parent
        visible: g.kind === "flip"
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 2; width: 30; height: 32; topLeftRadius: 10; topRightRadius: 10; bottomLeftRadius: 3; bottomRightRadius: 3; color: g.fill; border.width: 2; border.color: g.ink }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 34; width: 22; height: 4; radius: 2; color: g.ink }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 38; width: 30; height: 24; bottomLeftRadius: 10; bottomRightRadius: 10; topLeftRadius: 3; topRightRadius: 3; color: "transparent"; border.width: 2; border.color: g.ink }
        Grid { anchors.horizontalCenter: parent.horizontalCenter; y: 44; columns: 3; spacing: 3; Repeater { model: 6; Rectangle { width: 5; height: 4; radius: 1; color: g.ink } } }
    }

    Item {
        anchors.fill: parent
        visible: g.kind === "slider"
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 24; width: 34; height: 36; radius: 6; color: "transparent"; border.width: 2; border.color: g.ink; opacity: 0.6 }
        Grid { anchors.horizontalCenter: parent.horizontalCenter; y: 46; columns: 5; spacing: 2; Repeater { model: 10; Rectangle { width: 4; height: 4; radius: 1; color: g.ink } } }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 2; width: 34; height: 40; radius: 7; color: g.fill; border.width: 2; border.color: g.ink }
    }

    Item {
        anchors.fill: parent
        visible: g.kind === "holo"
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 2; width: 30; height: 44; radius: 4; color: g.fill; border.width: 1; border.color: g.ink; opacity: 0.85 }
        Repeater { model: 6; Rectangle { required property int index; anchors.horizontalCenter: parent.horizontalCenter; y: 8 + index * 6; width: 24; height: 1; color: g.ink; opacity: 0.5 } }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 52; width: 36; height: 9; radius: 4.5; color: "transparent"; border.width: 2; border.color: g.ink }
    }

    Item {
        anchors.fill: parent
        visible: g.kind === "pda"
        Rectangle { anchors.centerIn: parent; width: 40; height: 56; radius: 9; color: g.fill; border.width: 2; border.color: g.ink }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 10; width: 30; height: 30; radius: 3; color: "transparent"; border.width: 1; border.color: g.ink }
        Row { anchors.horizontalCenter: parent.horizontalCenter; y: 46; spacing: 4; Repeater { model: 4; Rectangle { width: 5; height: 5; radius: 2.5; color: g.ink } } }
        Rectangle { x: 54; y: 8; width: 3; height: 46; radius: 1.5; color: g.ink }
    }

    Item {
        anchors.fill: parent
        visible: g.kind === "orbit"
        Rectangle { anchors.centerIn: parent; width: 34; height: 34; radius: 17; color: g.fill; border.width: 2; border.color: g.ink }
        Rectangle { anchors.centerIn: parent; width: 16; height: 34; radius: 8; color: "transparent"; border.width: 1; border.color: g.ink }
        Rectangle { anchors.centerIn: parent; width: 60; height: 18; radius: 9; color: "transparent"; border.width: 1.5; border.color: g.ink; rotation: -14 }
        Rectangle { x: 52; y: 22; width: 7; height: 7; radius: 3.5; color: g.ink }
        Rectangle { x: 6; y: 38; width: 5; height: 5; radius: 2.5; color: g.ink }
    }

    Item {
        anchors.fill: parent
        visible: g.kind === "aqua"
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 4; width: 36; height: 48; radius: 14; color: "transparent"; border.width: 2; border.color: g.ink }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 18; width: 32; height: 32; bottomLeftRadius: 12; bottomRightRadius: 12; color: g.fill }
        Rectangle { x: 26; y: 30; width: 6; height: 6; radius: 3; color: "transparent"; border.width: 1.5; border.color: g.ink }
        Rectangle { x: 33; y: 22; width: 4; height: 4; radius: 2; color: "transparent"; border.width: 1.5; border.color: g.ink }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 54; width: 48; height: 7; radius: 3.5; color: g.ink }
    }

    Item {
        anchors.fill: parent
        visible: g.kind === "visor"
        Rectangle { anchors.centerIn: parent; width: 38; height: 46; color: g.fill; border.width: 1.5; border.color: g.ink }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 14; width: 30; height: 1.5; color: g.ink }
        Repeater {
            model: [[6, 4, 1, 1], [58, 4, -1, 1], [6, 60, 1, -1], [58, 60, -1, -1]]
            Item {
                required property var modelData
                Rectangle { x: modelData[2] > 0 ? modelData[0] : modelData[0] - 10; y: modelData[1] - 1; width: 10; height: 2.5; color: g.ink }
                Rectangle { x: modelData[0] - 1; y: modelData[3] > 0 ? modelData[1] : modelData[1] - 10; width: 2.5; height: 10; color: g.ink }
            }
        }
    }
}
