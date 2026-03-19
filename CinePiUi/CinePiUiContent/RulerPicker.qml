import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import CinePiUi

Item {
    id: root
    implicitWidth: 462
    implicitHeight: 98

    property list<int> values: [50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1600, 3200]
    property list<int> labeledValues: [50, 100, 200, 400, 800, 3200]
    property int currentIndex: 5
    property int visibleTickCount: 11
    property bool showLabels: false
    property bool showIndicator: false
    property bool centered: false
    property string displayText: "A 160"
    signal movementStarted()

    readonly property string currentValue: values[currentIndex] !== undefined
                                           ? values[currentIndex].toString() : ""

    ListView {
        id: rulerView
        anchors.fill: parent
        clip: true
        orientation: ListView.Horizontal
        model: root.values
        currentIndex: root.currentIndex

        readonly property real tickInterval: width / root.visibleTickCount

        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - tickInterval / 2
        preferredHighlightEnd: width / 2 + tickInterval / 2

        highlightMoveDuration: 300

        onCurrentIndexChanged: root.currentIndex = currentIndex

        delegate: Item {
            id: tickItem
            width: rulerView.tickInterval
            height: rulerView.height

            required property var modelData

            readonly property real displacement: {
                let center = rulerView.contentX + rulerView.width / 2
                let itemCenter = x + width / 2
                return Math.abs((itemCenter - center) / width)
            }
            readonly property bool isLabeled: root.labeledValues.includes(modelData)

            Label {
                id: tickLabel
                visible: tickItem.isLabeled && root.showLabels
                anchors.horizontalCenter: parent.horizontalCenter
                y: centerValueLabel.y
                text: tickItem.modelData
                font.pixelSize: 26
                style: Text.Outline
                styleColor: "#40000000"
                property real restFade: 1

                opacity: {
                    var centerFade = tickItem.displacement < 0.5
                                    ? 0
                                    : Math.min(1, (tickItem.displacement - 0.5) * 0.5)
                    var distFade = Math.max(0, 1.0 - tickItem.displacement * 0.21)
                    return centerFade * distFade * restFade
                }

                states: State {
                    name: "resting"
                    when: !rulerView.moving && tickItem.displacement < 1.5
                    PropertyChanges { target: tickLabel; restFade: 0 }
                }
                transitions: Transition {
                    NumberAnimation { property: "restFade"; duration: 100 }
                }
            }

            Rectangle {
                id: tickMark
                anchors.horizontalCenter: parent.horizontalCenter
                y: centerIndicator.y + centerIndicator.height - height
                width: 3
                height: 26
                color: "#e1ffffff"
                opacity: Math.max(0, 1.0 - tickItem.displacement * 0.21)
            }
        }

        highlight: Item {}
        onMovementStarted: root.movementStarted()
    }

    Label {
        id: centerValueLabel
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.displayText
        anchors.top: parent.top
        font.pixelSize: 26
        color: Material.accent
        font.capitalization: Font.AllUppercase
        font.weight: Font.Normal
    }

    Rectangle {
        id: centerIndicator
        visible: root.showIndicator
        width: 6
        height: 44
        color: Material.accent
        anchors.top: centerValueLabel.bottom
        anchors.topMargin: 7
        anchors.horizontalCenter: parent.horizontalCenter
    }


    states: [
        State {
            name: "manual"

            PropertyChanges {
                target: root
                showLabels: true
                showIndicator: true
            }
        }
    ]
}


