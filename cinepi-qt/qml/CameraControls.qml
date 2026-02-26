import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

/**
 * CameraControls - Bottom bar with primary camera controls.
 *
 * Provides quick access to: ISO, shutter angle, FPS, WB,
 * a record button, and a settings gear.
 */
Rectangle {
    id: root
    color: "#CC000000"
    signal settingsRequested()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        // ISO control
        ControlButton {
            label: "ISO"
            value: redis.iso.toString()
            onClicked: isoPopup.open()
        }

        // Shutter Angle control
        ControlButton {
            label: "SHUTTER"
            value: redis.shutterAngle + "°"
            onClicked: shutterPopup.open()
        }

        // FPS control
        ControlButton {
            label: "FPS"
            value: redis.fps.toString()
            onClicked: fpsPopup.open()
        }

        // WB control
        ControlButton {
            label: "WB"
            value: redis.whiteBalance > 0 ? redis.whiteBalance + "K" : "AUTO"
            onClicked: wbPopup.open()
        }

        Item { Layout.fillWidth: true }

        // Record button
        Rectangle {
            width: 56
            height: 56
            radius: 28
            color: redis.recording ? "#FF0000" : "#444444"
            border.color: "#FFFFFF"
            border.width: 2
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.centerIn: parent
                width: redis.recording ? 20 : 36
                height: redis.recording ? 20 : 36
                radius: redis.recording ? 3 : 18
                color: redis.recording ? "#FFFFFF" : "#FF0000"

                Behavior on width { NumberAnimation { duration: 150 } }
                Behavior on height { NumberAnimation { duration: 150 } }
                Behavior on radius { NumberAnimation { duration: 150 } }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: redis.setRecording(!redis.recording)
            }
        }

        Item { Layout.fillWidth: true }

        // Settings gear
        Rectangle {
            width: 40
            height: 40
            radius: 20
            color: settingsMouseArea.pressed ? "#555555" : "#333333"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\u2699" // gear unicode
                color: "#CCCCCC"
                font.pixelSize: 22
            }

            MouseArea {
                id: settingsMouseArea
                anchors.fill: parent
                onClicked: root.settingsRequested()
            }
        }
    }

    // ISO Popup
    Popup {
        id: isoPopup
        x: (root.width - width) / 2
        y: -height - 8
        width: 280
        height: 200
        modal: true

        background: Rectangle { color: "#EE222222"; radius: 8 }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text { text: "ISO"; color: "#AAAAAA"; font.pixelSize: 12; font.bold: true }

            Grid {
                columns: 4
                spacing: 4
                Repeater {
                    model: [100, 200, 400, 800, 1600, 3200, 6400, 12800]
                    delegate: Rectangle {
                        width: 60; height: 36; radius: 4
                        color: redis.iso === modelData ? "#0078D7" : "#444444"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            font.family: "monospace"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { redis.setISO(modelData); isoPopup.close() }
                        }
                    }
                }
            }
        }
    }

    // Shutter Angle Popup
    Popup {
        id: shutterPopup
        x: (root.width - width) / 2
        y: -height - 8
        width: 280
        height: 200
        modal: true

        background: Rectangle { color: "#EE222222"; radius: 8 }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text { text: "SHUTTER ANGLE"; color: "#AAAAAA"; font.pixelSize: 12; font.bold: true }

            Grid {
                columns: 4
                spacing: 4
                Repeater {
                    model: [11, 22, 45, 72, 90, 144, 172, 180, 270, 360]
                    delegate: Rectangle {
                        width: 60; height: 36; radius: 4
                        color: redis.shutterAngle === modelData ? "#0078D7" : "#444444"
                        Text {
                            anchors.centerIn: parent
                            text: modelData + "°"
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            font.family: "monospace"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { redis.setShutterAngle(modelData); shutterPopup.close() }
                        }
                    }
                }
            }
        }
    }

    // FPS Popup
    Popup {
        id: fpsPopup
        x: (root.width - width) / 2
        y: -height - 8
        width: 280
        height: 160
        modal: true

        background: Rectangle { color: "#EE222222"; radius: 8 }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text { text: "FRAME RATE"; color: "#AAAAAA"; font.pixelSize: 12; font.bold: true }

            Grid {
                columns: 4
                spacing: 4
                Repeater {
                    model: [1, 5, 8, 12, 15, 18, 24, 25, 30, 48, 50, 60]
                    delegate: Rectangle {
                        width: 60; height: 36; radius: 4
                        color: redis.fps === modelData ? "#0078D7" : "#444444"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            font.family: "monospace"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { redis.setFPS(modelData); fpsPopup.close() }
                        }
                    }
                }
            }
        }
    }

    // White Balance Popup
    Popup {
        id: wbPopup
        x: (root.width - width) / 2
        y: -height - 8
        width: 280
        height: 200
        modal: true

        background: Rectangle { color: "#EE222222"; radius: 8 }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text { text: "WHITE BALANCE"; color: "#AAAAAA"; font.pixelSize: 12; font.bold: true }

            Grid {
                columns: 3
                spacing: 4
                Repeater {
                    model: ListModel {
                        ListElement { label: "AUTO"; val: 0 }
                        ListElement { label: "2800K"; val: 2800 }
                        ListElement { label: "3200K"; val: 3200 }
                        ListElement { label: "4000K"; val: 4000 }
                        ListElement { label: "4500K"; val: 4500 }
                        ListElement { label: "5600K"; val: 5600 }
                        ListElement { label: "6500K"; val: 6500 }
                        ListElement { label: "7500K"; val: 7500 }
                        ListElement { label: "9000K"; val: 9000 }
                    }
                    delegate: Rectangle {
                        width: 80; height: 36; radius: 4
                        color: redis.whiteBalance === model.val ? "#0078D7" : "#444444"
                        Text {
                            anchors.centerIn: parent
                            text: model.label
                            color: "#FFFFFF"
                            font.pixelSize: 12
                            font.family: "monospace"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: { redis.setWhiteBalance(model.val); wbPopup.close() }
                        }
                    }
                }
            }
        }
    }

    /** Reusable control button */
    component ControlButton: Rectangle {
        property string label: ""
        property string value: ""
        signal clicked()

        Layout.fillHeight: true
        Layout.preferredWidth: 72
        Layout.margins: 6
        radius: 6
        color: buttonMouse.pressed ? "#555555" : "#333333"

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: "#888888"
                font.pixelSize: 9
                font.family: "monospace"
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: value
                color: "#FFFFFF"
                font.pixelSize: 15
                font.family: "monospace"
                font.bold: true
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }
}
