import QtQuick

Item {
    id: root

    property string text: ""

    width: parent ? parent.width : 200
    height: 36

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.separator
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Theme.textTertiary
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.family: Theme.fontLabel
        font.letterSpacing: 2
    }
}
