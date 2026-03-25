

/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import CinePiUi
import QtQuick.Layouts

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Material.background
    property alias viewfinderArea: viewfinderArea
    property alias formatButton: configBar.formatButton
    property alias aspectButton: configBar.aspectButton
    property alias isoButton: isoButton
    property alias shutterButton: shutterButton
    property alias wbButton: wbButton
    property alias recordButton: recordButton
    property alias isoControl: isoControl
    property alias shutterControl: shutterControl
    property alias wbControl: wbControl

    property int isoValue: isoControl.currentIndex
                           >= 0 ? isoControl.values[isoControl.currentIndex] : 0

    ConfigBar {
        id: configBar
        recording: recordButton.checked
        resolution: formatControl.selectedResolution
        fps: formatControl.selectedFps
        aspectRatio: aspectControl.selectedRatio
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
    }

    Rectangle {
        id: viewfinder
        // color: "white"
        color: Material.background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: configBar.bottom
        anchors.bottom: controlBar.top

        MouseArea {
            id: viewfinderArea
            anchors.fill: parent
        }

    Item {
        id: configSheet
        opacity: 0
        visible: opacity > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: configBar.bottom
        anchors.topMargin: -20
        z: 1

        FormatSheet {
            id: formatControl
            anchors.left: parent.left
            anchors.right: parent.right
            visible: false
        }

        AspectSheet {
            id: aspectControl
            anchors.left: parent.left
            anchors.right: parent.right
            visible: false
        }
    }

    Item {
        id: controlSheet
        z: 1
        height: 98
        opacity: 0
        visible: opacity > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlBar.top
        anchors.bottomMargin: -20

        ControlSheet {
            id: isoControl
            anchors.fill: parent
            visible: false
            values: [50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1600, 3200]
            labeledValues: [50, 100, 200, 400, 800, 3200]
        }

        ControlSheet {
            id: shutterControl
            anchors.fill: parent
            visible: false
            values: [11.25, 15, 22.5, 30, 37.5, 45, 60, 72, 75, 90, 108, 120, 144, 150, 172.8, 180, 216, 270, 324, 360]
            labeledValues: [45, 90, 180, 360]
            visibleTickCount: 16
            suffix: "°"
        }

        ControlSheet {
            id: wbControl
            anchors.fill: parent
            visible: false
            minValue: 2300
            maxValue: 10000
            step: 100
            visibleTickCount: 34
            labeledValues: [2300, 3600, 4900, 6200, 7500, 8800, 10000]
            suffix: "K"
        }
    }

    Pane {
        id: controlBar
        padding: 8
        background: Rectangle {
            color: "#40000000"
        }
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        RowLayout {
            id: controlsRow
            anchors.fill: parent
            spacing: 34

            ControlButton {
                id: isoButton
                objectName: "isoOpen"
                Layout.minimumWidth: 89
                label: "ISO"
                value: isoControl.displayText
                highlighted: !isoControl.autoMode
            }

            ControlButton {
                id: shutterButton
                objectName: "shutterOpen"
                Layout.minimumWidth: 89
                label: "SA"
                value: shutterControl.displayText
                highlighted: !shutterControl.autoMode
            }

            ControlButton {
                id: wbButton
                objectName: "wbOpen"
                Layout.minimumWidth: 89
                label: "WB"
                value: wbControl.displayText
                highlighted: !wbControl.autoMode
            }

            Item {
                Layout.fillWidth: true
            }

            RecordButton {
                id: recordButton
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.preferredHeight: 89
                Layout.preferredWidth: 89
            }
        }
    }

    states: [
        State {
            name: "isoOpen"

            PropertyChanges {
                target: isoButton
                checked: true
            }
            PropertyChanges {
                target: controlSheet
                opacity: 1
                anchors.bottomMargin: 0
            }
            PropertyChanges {
                target: isoControl
                visible: true
            }
        },
        State {
            name: "isoManual"
            extend: "isoOpen"

            PropertyChanges {
                target: isoControl
                autoMode: false
            }
        },
        State {
            name: "shutterOpen"

            PropertyChanges {
                target: shutterButton
                checked: true
            }
            PropertyChanges {
                target: controlSheet
                opacity: 1
                anchors.bottomMargin: 0
            }
            PropertyChanges {
                target: shutterControl
                visible: true
            }
        },
        State {
            name: "shutterManual"
            extend: "shutterOpen"

            PropertyChanges {
                target: shutterControl
                autoMode: false
            }
        },
        State {
            name: "wbOpen"

            PropertyChanges {
                target: wbButton
                checked: true
            }
            PropertyChanges {
                target: controlSheet
                opacity: 1
                anchors.bottomMargin: 0
            }
            PropertyChanges {
                target: wbControl
                visible: true
            }
        },
        State {
            name: "wbManual"
            extend: "wbOpen"

            PropertyChanges {
                target: wbControl
                autoMode: false
            }
        },
        State {
            name: "formatOpen"

            PropertyChanges {
                target: formatButton
                checked: true
            }
            PropertyChanges {
                target: configSheet
                opacity: 1
                anchors.topMargin: 0
            }
            PropertyChanges {
                target: formatControl
                visible: true
            }
        },
        State {
            name: "aspectOpen"

            PropertyChanges {
                target: aspectButton
                checked: true
            }
            PropertyChanges {
                target: configSheet
                opacity: 1
                anchors.topMargin: 0
            }
            PropertyChanges {
                target: aspectControl
                visible: true
            }
        },
        State {
            name: "recording"

            PropertyChanges {
                target: configBar
                recording: true
            }
        }
    ]

    transitions: [
        Transition {
            PropertyAnimation {
                target: controlSheet
                properties: "opacity,anchors.bottomMargin"
                duration: 200
                easing.type: Easing.OutCubic
            }
            PropertyAnimation {
                target: configSheet
                properties: "opacity,anchors.topMargin"
                duration: 200
                easing.type: Easing.OutCubic
            }
            to: "*"
            from: "*"
        }
    ]
}

/*##^##
Designer {
    D{i:0}D{i:18;transitionDuration:2000}
}
##^##*/

