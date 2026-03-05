import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.barOverlay

    signal gearClicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 4

        ControlButton {
            label: "ISO"
            value: camera.iso.toString()
            values: [100, 200, 400, 800, 1600, 3200, 6400, 12800]
            currentValue: camera.iso
            setter: function(v) { camera.setISO(v) }
            onClicked: isoPopup.open()
        }

        ControlButton {
            label: "SHT"
            value: camera.shutterAngle + "\u00B0"
            values: [11, 22, 45, 72, 90, 144, 172, 180, 270, 360]
            currentValue: camera.shutterAngle
            setter: function(v) { camera.setShutterAngle(v) }
            onClicked: shutterPopup.open()
        }

        ControlButton {
            label: "WB"
            value: camera.whiteBalance > 0 ? camera.whiteBalance + "K" : "AUTO"
            onClicked: wbPopup.open()
        }

        Rectangle {
            width: Theme.gearButtonSize
            height: Theme.gearButtonSize
            radius: Theme.gearButtonSize / 2
            color: Theme.surfaceHover
            Layout.alignment: Qt.AlignVCenter
            scale: gearMouse.pressed ? Theme.pressScale : 1.0

            Behavior on scale {
                SpringAnimation { spring: 4; damping: 0.6 }
            }

            Text {
                anchors.centerIn: parent
                text: "\u2699"
                color: Theme.textSecondary
                font.pixelSize: 34
            }

            MouseArea {
                id: gearMouse
                anchors.fill: parent
                anchors.margins: -8
                onClicked: root.gearClicked()
            }
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
                    model: [100, 200, 400, 800, 1600, 3200, 6400, 12800]
                    delegate: PopupGridItem {
                        itemWidth: Theme.popupItemWidth
                        text: modelData.toString()
                        selected: camera.iso === modelData
                        onItemClicked: { camera.setISO(modelData); isoPopup.close() }
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
                    model: [11, 22, 45, 72, 90, 144, 172, 180, 270, 360]
                    delegate: PopupGridItem {
                        itemWidth: Theme.popupItemWidth
                        text: modelData + "\u00B0"
                        selected: camera.shutterAngle === modelData
                        onItemClicked: { camera.setShutterAngle(modelData); shutterPopup.close() }
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
                    delegate: PopupGridItem {
                        itemWidth: Theme.popupItemWidthWB
                        text: model.label
                        selected: camera.whiteBalance === model.val
                        onItemClicked: { camera.setWhiteBalance(model.val); wbPopup.close() }
                    }
                }
            }
        }
    }

    // --- Shared popup enter/exit transitions ---
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

    // --- Popup grid item component ---
    component PopupGridItem: Rectangle {
        property int itemWidth: Theme.popupItemWidth
        property string text: ""
        property bool selected: false
        signal itemClicked()

        width: itemWidth
        height: Theme.popupItemHeight
        radius: Theme.radiusMedium
        color: selected ? Theme.accent : Theme.surfaceHover
        scale: itemMouse.pressed ? Theme.pressScale : 1.0

        Behavior on scale {
            SpringAnimation { spring: 4; damping: 0.6 }
        }

        Text {
            anchors.centerIn: parent
            text: parent.text
            color: Theme.textPrimary
            font.pixelSize: 15
            font.family: Theme.fontValue
            font.weight: Font.Medium
        }

        MouseArea {
            id: itemMouse
            anchors.fill: parent
            onClicked: parent.itemClicked()
        }
    }

    // --- Control button component ---
    component ControlButton: Rectangle {
        property string label: ""
        property string value: ""
        property var values: []
        property var currentValue
        property var setter
        signal clicked()

        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.margins: 4
        radius: Theme.radiusMedium
        color: Theme.surfaceHover
        scale: btnMouse.pressed ? Theme.pressScale : 1.0

        Behavior on scale {
            SpringAnimation { spring: 4; damping: 0.6 }
        }

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: label
                color: Theme.textSecondary
                font.pixelSize: 12
                font.family: Theme.fontLabel
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: value
                color: Theme.textPrimary
                font.pixelSize: 20
                font.family: Theme.fontValue
                font.weight: Font.Bold
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            onClicked: parent.clicked()
        }

        DragHandler {
            target: null
            yAxis.enabled: true
            xAxis.enabled: false
            onTranslationChanged: {
                if (!values || values.length === 0 || !setter) return
                var idx = values.indexOf(currentValue)
                if (idx < 0) return
                var steps = Math.round(-translation.y / 40)
                var newIdx = Math.max(0, Math.min(values.length - 1, idx + steps))
                if (newIdx !== idx) setter(values[newIdx])
            }
        }
    }
}
