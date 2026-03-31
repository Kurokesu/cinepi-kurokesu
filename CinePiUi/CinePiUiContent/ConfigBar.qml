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
    property alias menuButton: menuButton

    RowLayout {
        id: configBarRow
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: menuButton.left

        Item { Layout.fillWidth: true }

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

        Item { Layout.fillWidth: true }

        Button {
            id: aspectButton
            objectName: "aspectOpen"
            flat: true

            background: Rectangle {
                color: "transparent"
                radius: height / 4
                border.color: parent.checked ? Material.accent : "white"
                border.width: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
            }

            contentItem: Item {
                implicitWidth: 49
                implicitHeight: aspectLabel.implicitHeight

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

        Item { Layout.fillWidth: true }

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

        Item { Layout.fillWidth: true }

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

        Item { Layout.fillWidth: true }
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
        text: "\u22ee"
        flat: true
        font.pixelSize: 34
        font.weight: Font.Bold
        width: 72
        anchors.right: parent.right
        anchors.rightMargin: -root.padding
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
