import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.surface

    property int iso: 800
    property int shutterAngle: 180
    property int whiteBalance: 0

    signal isoChangeRequested(int val)
    signal shutterAngleChangeRequested(int val)
    signal whiteBalanceChangeRequested(int val)
    signal gearClicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        ControlButton {
            label: "ISO"
            value: root.iso.toString()
            values: CameraPresets.isoValues
            currentValue: root.iso
            setter: function(v) { root.isoChangeRequested(v) }
            onClicked: isoPopup.open()
        }

        ControlButton {
            label: "SHT"
            value: root.shutterAngle + "\u00B0"
            values: CameraPresets.shutterAngles
            currentValue: root.shutterAngle
            setter: function(v) { root.shutterAngleChangeRequested(v) }
            onClicked: shutterPopup.open()
        }

        ControlButton {
            label: "WB"
            value: root.whiteBalance > 0 ? root.whiteBalance + "K" : "AUTO"
            onClicked: wbPopup.open()
        }

        RoundButton {
            width: Theme.gearButtonSize
            height: Theme.gearButtonSize
            radius: Theme.gearButtonSize / 2
            flat: true
            Layout.alignment: Qt.AlignVCenter

            background: Rectangle {
                radius: Theme.gearButtonSize / 2
                color: Theme.surfaceHover
                scale: parent.pressed ? Theme.pressScale : 1.0
                Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }
            }

            contentItem: Text {
                anchors.centerIn: parent
                text: "\u2699"
                color: Theme.textSecondary
                font.pixelSize: 34
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: root.gearClicked()
        }
    }

    // --- ISO Popup ---
    Popup {
        id: isoPopup
        x: (root.width - width) / 2
        y: -height - 8
        width: Theme.popupWidth
        height: 220
        modal: true

        enter: popupEnterTransition
        exit: popupExitTransition
        background: Rectangle { color: "#EE" + Theme.surface.toString().substring(1); radius: Theme.radiusMedium }

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "ISO"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontLabel
                font.letterSpacing: 1.5
            }

            Grid {
                columns: 4
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: CameraPresets.isoValues
                    delegate: PopupGridItem {
                        itemWidth: Theme.popupItemWidth
                        text: modelData.toString()
                        checked: root.iso === modelData
                        onClicked: { root.isoChangeRequested(modelData); isoPopup.close() }
                    }
                }
            }
        }
    }

    // --- Shutter Angle Popup ---
    Popup {
        id: shutterPopup
        x: (root.width - width) / 2
        y: -height - 8
        width: Theme.popupWidth
        height: 250
        modal: true

        enter: popupEnterTransition
        exit: popupExitTransition
        background: Rectangle { color: "#EE" + Theme.surface.toString().substring(1); radius: Theme.radiusMedium }

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "SHUTTER ANGLE"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontLabel
                font.letterSpacing: 1.5
            }

            Grid {
                columns: 4
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: CameraPresets.shutterAngles
                    delegate: PopupGridItem {
                        itemWidth: Theme.popupItemWidth
                        text: modelData + "\u00B0"
                        checked: root.shutterAngle === modelData
                        onClicked: { root.shutterAngleChangeRequested(modelData); shutterPopup.close() }
                    }
                }
            }
        }
    }

    // --- White Balance Popup ---
    Popup {
        id: wbPopup
        x: (root.width - width) / 2
        y: -height - 8
        width: Theme.popupWidth
        height: 250
        modal: true

        enter: popupEnterTransition
        exit: popupExitTransition
        background: Rectangle { color: "#EE" + Theme.surface.toString().substring(1); radius: Theme.radiusMedium }

        Column {
            anchors.centerIn: parent
            spacing: 8

            Text {
                text: "WHITE BALANCE"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontLabel
                font.letterSpacing: 1.5
            }

            Grid {
                columns: 3
                spacing: 6
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: CameraPresets.whiteBalancePresets.length
                    delegate: PopupGridItem {
                        itemWidth: Theme.popupItemWidthWB
                        text: CameraPresets.whiteBalancePresets[index].label
                        checked: root.whiteBalance === CameraPresets.whiteBalancePresets[index].value
                        onClicked: {
                            root.whiteBalanceChangeRequested(CameraPresets.whiteBalancePresets[index].value)
                            wbPopup.close()
                        }
                    }
                }
            }
        }
    }

    // --- Shared popup transitions ---
    Transition {
        id: popupEnterTransition
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        }
    }

    Transition {
        id: popupExitTransition
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.9; duration: 120; easing.type: Easing.InCubic }
        }
    }
}
