import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.surface

    property int resWidth: 1920
    property int resHeight: 1080
    property int fps: 30

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        StatusItem {
            label: "RES"
            value: root.resWidth > 0 ? (root.resWidth + "x" + root.resHeight) : "---"
        }

        Rectangle {
            width: 1; height: 28
            color: Theme.separator
            Layout.alignment: Qt.AlignVCenter
        }

        StatusItem {
            label: "FPS"
            value: root.fps > 0 ? root.fps.toString() : "---"
        }

        Item { Layout.fillWidth: true }
    }
}
