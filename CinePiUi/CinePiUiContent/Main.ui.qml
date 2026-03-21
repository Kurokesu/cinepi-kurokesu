

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
    property alias isoAutoButton: isoAutoButton
    property alias previewArea: previewArea
    property alias isoButton: isoButton
    property alias shutterButton: shutterButton
    property alias isoPanel: isoPanel
    property alias shutterPanel: shutterPanel

    property int isoValue: isoPanel.currentIndex >= 0 ? isoPanel.values[isoPanel.currentIndex] : 0

    Pane {
        id: statusBar
        height: 100
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
    }

    Rectangle {
        id: preview
        color: Material.background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: statusBar.bottom
        anchors.bottom: controlsBar.top

        MouseArea {
            id: previewArea
            anchors.fill: parent
        }
    }

    PickerPanel {
        id: isoPanel
        opacity: 0
        visible: opacity > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlsBar.top
        z: 1
        values: [50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1600, 3200]
        labeledValues: [50, 100, 200, 400, 800, 3200]
    }

    PickerPanel {
        id: shutterPanel
        opacity: 0
        visible: opacity > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlsBar.top
        z: 1
        values: [15, 22, 30, 45, 60, 72, 90, 120, 144, 150, 172, 180, 270, 330, 360]
        labeledValues: [30, 90, 180, 360]
        suffix: "°"
    }

    Pane {
        id: controlsBar
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
                Layout.minimumWidth: 89
                label: "ISO"
                value: isoPanel.displayText
                highlighted: !isoPanel.autoMode
            }

            ControlButton {
                id: shutterButton
                Layout.minimumWidth: 89
                label: "SA"
                value: shutterPanel.displayText
                highlighted: !shutterPanel.autoMode
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
            name: "isoAuto"
            when: isoButton.checked

            PropertyChanges {
                target: isoPanel
                opacity: 1
            }
        },
        State {
            name: "isoManual"
            extend: "isoAuto"

            PropertyChanges {
                target: root
                isoAuto: false
            }
        }
    ]

    transitions: [
        Transition {
            PropertyAnimation {
                targets: [isoPanel, shutterPanel]
                property: "opacity"
                duration: 250
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

