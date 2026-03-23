

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
    property alias isoControl: isoControl
    property alias shutterControl: shutterControl
    property alias wbControl: wbControl

    property int isoValue: isoControl.currentIndex >= 0 ? isoControl.values[isoControl.currentIndex] : 0

    Pane {
        id: configBar
        height: 91
        padding: 8
        background: Rectangle {
            color: "#40000000"
        }
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        RowLayout {
            id: configBarRow
            anchors.fill: parent
            spacing: 34

            Button {
                id: formatButton
                flat: true
                background: Item {}

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
                id: aspectButton
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
                        width: aspectButton.width
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
                id: configBarSpacer
                Layout.fillWidth: true
            }

            Label {
                id: recordingTimer
                visible: false
                text: "00:00:00:00"
                font.pixelSize: 21
                font.weight: Font.Bold
                leftPadding: 16
                rightPadding: 16
                topPadding: 6
                bottomPadding: 6
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                background: Rectangle {
                    id: recordingBadge
                    color: Material.accent
                    radius: height / 2
                    opacity: 0
                }
            }

            Button {
                id: menuButton
                text: "\u22ee"
                flat: true
                font.pixelSize: 34
                rightPadding: 0
                font.weight: Font.Bold
                background: Item {}
            }
        }
    }

    Rectangle {
        id: preview
        color: Material.background
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: configBar.bottom
        anchors.bottom: controlsBar.top

        MouseArea {
            id: previewArea
            anchors.fill: parent
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
                Layout.minimumWidth: 89
                label: "ISO"
                value: isoControl.displayText
                highlighted: !isoControl.autoMode
            }

            ControlButton {
                id: shutterButton
                Layout.minimumWidth: 89
                label: "SA"
                value: shutterControl.displayText
                highlighted: !shutterControl.autoMode
            }

            ControlButton {
                id: wbButton
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
            when: isoButton.checked

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
            when: shutterButton.checked

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
            when: wbButton.checked

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
            name: "recording"
            when: recordButton.checked

            PropertyChanges {
                target: formatButton
                visible: false
            }
            PropertyChanges {
                target: aspectButton
                visible: false
            }
            PropertyChanges {
                target: configBarSpacer
                visible: false
            }
            PropertyChanges {
                target: menuButton
                visible: false
            }
            PropertyChanges {
                target: recordingTimer
                visible: true
            }
            PropertyChanges {
                target: recordingBadge
                opacity: 1
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
                target: recordingBadge
                property: "opacity"
                duration: 1000
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

