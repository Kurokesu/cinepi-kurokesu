import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Pane {
    id: root
    implicitWidth: 720
    height: 91
    padding: 8
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

    RowLayout {
        id: configBarRow
        anchors.fill: parent
        spacing: 34

        Button {
            id: formatButton
            objectName: "formatOpen"
            flat: true
            background: Item {}

            contentItem: Column {
                anchors.centerIn: parent
                Label {
                    text: root.resolution
                    font.pixelSize: 21
                    font.weight: Font.Medium
                    anchors.horizontalCenter: parent.horizontalCenter
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
                        color: "white"
                        radius: height / 4
                    }
                }
            }
        }

        Button {
            id: aspectButton
            objectName: "aspectOpen"
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
                    text: root.aspectRatio
                    font.pixelSize: 21
                    font.weight: Font.Bold
                    color: "white"
                }
            }
        }

        Button {
            id: guideButton
            objectName: "guideOpen"
            flat: true
            display: AbstractButton.IconOnly
            icon.source: "images/grid_guides_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            icon.width: 59
            icon.height: 59
            background: Item {}
        }

        Button {
            id: monitorButton
            objectName: "monitorOpen"
            flat: true
            display: AbstractButton.IconOnly
            icon.source: "images/visibility_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            icon.width: 59
            icon.height: 59
            background: Item {}
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

    states: [
        State {
            name: "recording"
            when: root.recording

            PropertyChanges {
                target: formatButton
                visible: false
            }
            PropertyChanges {
                target: aspectButton
                visible: false
            }
            PropertyChanges {
                target: guideButton
                visible: false
            }
            PropertyChanges {
                target: monitorButton
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
                target: recordingBadge
                property: "opacity"
                duration: 1000
                easing.type: Easing.OutCubic
            }
        }
    ]
}
