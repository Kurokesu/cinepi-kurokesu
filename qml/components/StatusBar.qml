import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

/**
 * StatusBar - Top bar showing camera parameters and status.
 *
 * Displays: resolution, FPS, ISO, shutter angle, white balance,
 *           recording status, and connection indicators.
 */
Rectangle {
    id: root
    color: "#CC000000"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 16

        // Resolution
        StatusItem {
            label: "RES"
            value: camera.width > 0 ? (camera.width + "x" + camera.height) : "---"
        }

        // FPS
        StatusItem {
            label: "FPS"
            value: camera.fps > 0 ? camera.fps.toString() : "---"
        }

        // Separator
        Rectangle { width: 1; height: 24; color: "#444444"; Layout.alignment: Qt.AlignVCenter }

        // ISO
        StatusItem {
            label: "ISO"
            value: camera.iso > 0 ? camera.iso.toString() : "---"
            highlight: camera.iso >= 3200
        }

        // Shutter Angle
        StatusItem {
            label: "SHT"
            value: camera.shutterAngle > 0 ? (camera.shutterAngle + "°") : "---"
        }

        // White Balance
        StatusItem {
            label: "WB"
            value: camera.whiteBalance > 0 ? camera.whiteBalance.toString() : "AUTO"
        }

        Item { Layout.fillWidth: true }

        // Recording indicator
        Row {
            spacing: 6
            visible: camera.recording
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: "#FF0000"
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: camera.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }

            Text {
                text: "REC"
                color: "#FF0000"
                font.pixelSize: 13
                font.bold: true
                font.family: "monospace"
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Redis connection dot
        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: camera.connected ? "#00CC00" : "#CC0000"
            Layout.alignment: Qt.AlignVCenter

            ToolTip.visible: connMouse.containsMouse
            ToolTip.text: camera.connected ? "Camera connected" : "Camera disconnected"

            MouseArea {
                id: connMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }
    }

    /** Reusable status display item */
    component StatusItem: Column {
        property string label: ""
        property string value: ""
        property bool highlight: false

        Layout.alignment: Qt.AlignVCenter
        spacing: 1

        Text {
            text: parent.label
            color: "#888888"
            font.pixelSize: 9
            font.family: "monospace"
            font.bold: true
        }

        Text {
            text: parent.value
            color: parent.highlight ? "#FFAA00" : "#FFFFFF"
            font.pixelSize: 14
            font.family: "monospace"
            font.bold: true
        }
    }
}
