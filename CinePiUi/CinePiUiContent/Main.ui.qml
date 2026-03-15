

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
    border.width: 0
    property alias isoAutoButton: isoAutoButton
    property alias previewArea: previewArea
    property alias isoButton: isoButton
    property alias rulerPicker: rulerPicker
    property string isoDisplayText: isoAuto ? "A "
                                              + rulerPicker.currentValue : rulerPicker.currentValue
    property bool isoAuto: true
    property int isoValue: rulerPicker.currentIndex
                           >= 0 ? rulerPicker.values[rulerPicker.currentIndex] : 0

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
        border.width: 0
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
                    color: "#50000000"
                    radius: height / 5
                }
                contentItem: Label {
                    id: label
                    text: isoAutoButton.text
                    font.pixelSize: 24
                    color: isoAutoButton.checked ? Material.accent : Material.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.weight: Font.Medium
                    font.capitalization: Font.AllUppercase
                }
            }

            RulerPicker {
                id: rulerPicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.rightMargin: isoAutoButton.width + isoPanelRow.spacing
                autoMode: root.isoAuto
                displayText: root.isoDisplayText
            }
        }
    }

    Rectangle {
        id: controlsBar
        height: controlsRow.implicitHeight
        color: "#40000000"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        RowLayout {
            id: controlsRow
            anchors.fill: parent

            Button {
                id: isoButton
                Layout.minimumWidth: 86
                flat: true
                checkable: true
                background: Item {}
                Material.foreground: isoButton.checked
                                     || !root.isoAuto ? Material.accent : controlsBar.Material.foreground
                contentItem: Column {
                    id: column
                    anchors.centerIn: parent

                    Label {
                        id: isoLabel
                        text: qsTr("ISO")
                        font.pixelSize: 24
                        font.weight: Font.Normal
                        font.capitalization: Font.AllUppercase
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        id: isoValueLabel
                        text: root.isoDisplayText
                        font.pixelSize: 22
                        font.weight: Font.ExtraBold
                        font.capitalization: Font.AllUppercase
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            RoundButton {
                id: recordButton
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                checkable: true
                display: AbstractButton.IconOnly
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
                target: isoAutoButton
                checked: false
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

