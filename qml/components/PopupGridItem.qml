import QtQuick
import QtQuick.Controls

Button {
    id: root

    property int itemWidth: Theme.popupItemWidth

    width: itemWidth
    height: Theme.popupItemHeight
    checkable: true
    flat: true

    background: Rectangle {
        radius: Theme.radiusMedium
        color: root.checked ? Theme.accent : Theme.surfaceHover
        scale: root.pressed ? Theme.pressScale : 1.0

        Behavior on scale {
            SpringAnimation { spring: 4; damping: 0.6 }
        }
    }

    contentItem: Text {
        anchors.centerIn: parent
        text: root.text
        color: Theme.textPrimary
        font.pixelSize: 15
        font.family: Theme.fontValue
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
