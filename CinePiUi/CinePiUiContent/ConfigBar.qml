import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Pane {
    id: root
    implicitWidth: 720
    height: 91
    verticalPadding: 0
    horizontalPadding: 8
    background: Rectangle {
        color: "#40000000"
    }

    property bool recording: false
    property string resolution: "4K"
    property int fps: 24
    property string aspectRatio: "16:9"

    property alias formatButton: formatButton
    property alias aspectButton: aspectButton
    property alias guideButton: guideButton
    property alias monitorButton: monitorButton
    property alias menuButton: menuButton

    RowLayout {
        id: configBarRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: menuButton.left

        Item {
            Layout.fillWidth: true
        }

        Button {
            id: formatButton
            objectName: "formatOpen"
            flat: true
            Layout.preferredWidth: 89
            Layout.fillHeight: true
            background: Item {}

            contentItem: Item {
                Column {
                    anchors.centerIn: parent
                    Label {
                        text: root.resolution
                        font.pixelSize: 21
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.weight: Font.Medium
                        color: formatButton.checked ? Material.accent : "white"
                    }

                    Label {
                        width: 44
                        text: root.fps.toString()
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        font.weight: Font.Bold
                        color: "black"
                        anchors.horizontalCenter: parent.horizontalCenter
                        background: Rectangle {
                            color: formatButton.checked ? Material.accent : "white"
                            radius: height / 4
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Button {
            id: aspectButton
            objectName: "aspectOpen"
            flat: true
            Layout.preferredWidth: 89
            Layout.fillHeight: true
            background: Item {}

            contentItem: Item {
                id: item1
                implicitWidth: 49
                implicitHeight: aspectLabel.implicitHeight

                Rectangle {
                    width: aspectButton.width - 34
                    height: aspectLabel.height + 13
                    color: "transparent"
                    radius: height / 4
                    border.color: aspectButton.checked ? Material.accent : "white"
                    border.width: 2
                    anchors.centerIn: parent
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: aspectButton.width
                    height: aspectLabel.implicitHeight
                    color: "black"
                }

                Label {
                    id: aspectLabel
                    anchors.centerIn: parent
                    text: root.aspectRatio
                    font.pixelSize: 21
                    font.weight: Font.Bold
                    color: aspectButton.checked ? Material.accent : "white"
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Button {
            id: guideButton
            objectName: "guideOpen"
            flat: true
            Layout.preferredWidth: 89
            Layout.fillHeight: true
            display: AbstractButton.IconOnly
            icon.source: "images/grid_guides_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            icon.width: 59
            icon.height: 59
            background: Item {}
        }

        Item {
            Layout.fillWidth: true
        }

        Button {
            id: monitorButton
            objectName: "monitorOpen"
            flat: true
            Layout.preferredWidth: 89
            Layout.fillHeight: true
            display: AbstractButton.IconOnly
            icon.source: "images/visibility_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            icon.width: 59
            icon.height: 59
            background: Item {}
        }

        Item {
            Layout.fillWidth: true
        }
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
        anchors.centerIn: parent
        background: Rectangle {
            id: recordingBadge
            color: Material.accent
            radius: height / 2
            opacity: 0
        }
    }

    Button {
        id: menuButton
        objectName: "settingsOpen"
        text: "\u22ee"
        flat: true
        font.pixelSize: 34
        font.weight: Font.Bold
        width: 72
        anchors.right: parent.right
        anchors.rightMargin: -root.rightPadding
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        horizontalPadding: 0
        contentItem: Label {
            text: menuButton.text
            font: menuButton.font
            color: "white"
            horizontalAlignment: Text.AlignRight
            rightPadding: 4
            verticalAlignment: Text.AlignVCenter
        }
        background: Item {}
    }

    states: [
        State {
            name: "recording"
            when: root.recording

            PropertyChanges {
                target: configBarRow
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
                target: recordingBadge
                property: "opacity"
                duration: 1000
                easing.type: Easing.OutCubic
            }
        }
    ]
}
