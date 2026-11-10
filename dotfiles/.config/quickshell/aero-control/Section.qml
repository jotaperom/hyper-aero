import QtQuick

Text {
    property var pal
    topPadding: 10
    font.family: "JetBrainsMono Nerd Font"
    font.weight: Font.Bold
    font.pixelSize: 11
    font.letterSpacing: 1.5
    color: pal ? pal.muted : "#5a6270"
}
