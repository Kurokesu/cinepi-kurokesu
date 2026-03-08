import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property string label: ""
    property bool checked: false
    signal toggled(bool newValue)

    width: parent ? parent.width : 300
    spacing: 8

    Text {
        text: root.label
        color: Theme.textPrimary
        font.pixelSize: 13
        font.family: Theme.fontBody
        Layout.fillWidth: true
    }

    Switch {
        checked: root.checked
        onToggled: function() { root.toggled(checked) }

        indicator: Rectangle {
            width: 48; height: 28; radius: 14
            color: parent.checked ? Theme.accent : Theme.surfacePressed
            x: parent.leftPadding
            y: parent.height / 2 - height / 2

            Rectangle {
                x: parent.parent.checked ? parent.width - width - 3 : 3
                y: 3
                width: 22; height: 22; radius: 11
                color: Theme.textPrimary
                Behavior on x { SpringAnimation { spring: 4; damping: 0.6 } }
            }
        }
    }
}
