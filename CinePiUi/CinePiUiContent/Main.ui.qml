

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
    property alias isoPicker: isoPicker
    property string isoDisplayText: isoAuto ? "A " + isoPicker.currentValue : isoPicker.currentValue
    property bool isoAuto: true
    property int isoValue: isoPicker.currentIndex >= 0 ? isoPicker.values[isoPicker.currentIndex] : 0

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

    Rectangle {
        id: isoPanel
        height: 98
        opacity: 0
        visible: opacity > 0
        color: "#40000000"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlsBar.top
        z: 1

        RowLayout {
            id: isoPanelRow
            anchors.fill: parent
            anchors.leftMargin: Constants.spacingLarge
            anchors.rightMargin: Constants.spacingLarge

            Button {
                id: isoAutoButton
                text: checked ? qsTr("AUTO") : qsTr("MANUAL")
                Layout.preferredWidth: 108
                checkable: true
                checked: root.isoAuto
                background: Rectangle {
                    id: rectangle
                    color: "#66545454"
                    radius: height / 5
                }
                contentItem: Label {
                    id: label
                    text: isoAutoButton.text
                    font.pixelSize: 22
                    color: isoAutoButton.checked ? Material.accent : Material.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.weight: Font.Medium
                    font.capitalization: Font.AllUppercase
                }
            }

            RulerPicker {
                id: isoPicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: isoAutoButton.width + isoPanelRow.spacing
                showLabels: !root.isoAuto
                showIndicator: !root.isoAuto
                centered: root.isoAuto
                displayText: root.isoDisplayText
            }
        }
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
                value: root.isoDisplayText
                highlighted: !root.isoAuto
            }

            ControlButton {
                id: shutterButton
                Layout.minimumWidth: 89
                label: "SA"
                value: "A 180°"
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
            id: transition
            ParallelAnimation {
                SequentialAnimation {
                    PauseAnimation {
                        duration: 0
                    }

                    PropertyAnimation {
                        target: isoPanel
                        property: "opacity"
                        duration: 250
                    }
                }
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

