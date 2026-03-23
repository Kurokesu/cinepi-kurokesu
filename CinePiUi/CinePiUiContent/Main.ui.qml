

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
    property alias wbButton: wbButton
    property alias isoPanel: isoPanel
    property alias shutterPanel: shutterPanel
    property alias wbPanel: wbPanel

    property int isoValue: isoPanel.currentIndex >= 0 ? isoPanel.values[isoPanel.currentIndex] : 0

    Pane {
        id: topBar
        padding: 8
        background: Rectangle {
            color: "#40000000"
        }
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        RowLayout {
            id: topBarRow
            anchors.fill: parent
            spacing: 34

            Button {
                id: resFpsButton
                flat: true

                contentItem: Column {
                    id: column
                    anchors.centerIn: parent
                    Label {
                        text: "4K"
                        font.pixelSize: 21
                        font.weight: Font.Medium
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Label {
                        width: 44
                        text: "30"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: Font.Bold
                        color: "#000000"
                        anchors.horizontalCenter: parent.horizontalCenter
                        background: Rectangle {
                            color: "white"
                            radius: height / 4
                        }
                    }
                }
            }

            Button {
                id: ratioButton
                flat: true

                background: Rectangle {
                    color: "transparent"
                    radius: height / 4
                    border.color: "white"
                    border.width: 2
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                }

                contentItem: Item {
                    implicitWidth: 49
                    implicitHeight: ratioLabel.implicitHeight

                    Rectangle {
                        anchors.centerIn: parent
                        width: ratioButton.width
                        height: ratioLabel.implicitHeight
                        color: "black"
                    }

                    Label {
                        id: ratioLabel
                        anchors.centerIn: parent
                        text: "16:9"
                        font.pixelSize: 21
                        font.weight: Font.Bold
                        color: "white"
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: recordingPill
                visible: false
                Layout.alignment: Qt.AlignCenter
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 18
                color: Material.accent

                Label {
                    anchors.centerIn: parent
                    text: "00:00:00:00"
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    font.family: "monospace"
                    color: "white"
                }
            }

            Button {
                id: settingsButton
                text: "\u22ee"
                flat: true
                font.pixelSize: 34
                rightPadding: 0
                font.weight: Font.Bold
            }
        }
    }

    Rectangle {
        id: preview
        color: Material.background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.bottom: controlsBar.top

        MouseArea {
            id: previewArea
            anchors.fill: parent
        }
    }

    Item {
        id: pickerContainer
        z: 1
        height: 98
        opacity: 0
        visible: opacity > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlsBar.top
        anchors.bottomMargin: -20

        PickerPanel {
            id: isoPanel
            anchors.fill: parent
            visible: false
            values: [50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1600, 3200]
            labeledValues: [50, 100, 200, 400, 800, 3200]
        }

        PickerPanel {
            id: shutterPanel
            anchors.fill: parent
            visible: false
            values: [11.25, 15, 22.5, 30, 37.5, 45, 60, 72, 75, 90, 108, 120, 144, 150, 172.8, 180, 216, 270, 324, 360]
            labeledValues: [45, 90, 180, 360]
            visibleTickCount: 16
            suffix: "°"
        }

        PickerPanel {
            id: wbPanel
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

            ControlButton {
                id: wbButton
                Layout.minimumWidth: 89
                label: "WB"
                value: wbPanel.displayText
                highlighted: !wbPanel.autoMode
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
            when: isoButton.checked

            PropertyChanges {
                target: pickerContainer
                opacity: 1
                anchors.bottomMargin: 0
            }
            PropertyChanges {
                target: isoPanel
                visible: true
            }
        },
        State {
            name: "isoManual"
            extend: "isoOpen"

            PropertyChanges {
                target: isoPanel
                autoMode: false
            }
        },
        State {
            name: "shutterOpen"
            when: shutterButton.checked

            PropertyChanges {
                target: pickerContainer
                opacity: 1
                anchors.bottomMargin: 0
            }
            PropertyChanges {
                target: shutterPanel
                visible: true
            }
        },
        State {
            name: "shutterManual"
            extend: "shutterOpen"

            PropertyChanges {
                target: shutterPanel
                autoMode: false
            }
        },
        State {
            name: "wbOpen"
            when: wbButton.checked

            PropertyChanges {
                target: pickerContainer
                opacity: 1
                anchors.bottomMargin: 0
            }
            PropertyChanges {
                target: wbPanel
                visible: true
            }
        },
        State {
            name: "wbManual"
            extend: "wbOpen"

            PropertyChanges {
                target: wbPanel
                autoMode: false
            }
        }
    ]

    transitions: [
        Transition {
            PropertyAnimation {
                target: pickerContainer
                properties: "opacity,anchors.bottomMargin"
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

