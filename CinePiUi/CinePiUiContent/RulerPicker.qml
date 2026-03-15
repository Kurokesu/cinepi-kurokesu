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
    property int visibleItemCount: 11
    property bool autoMode: true
    property string centerText: "A 160"
    signal manualModeRequested()

    readonly property string currentValue: values[currentIndex] !== undefined
                                           ? values[currentIndex].toString() : ""

    ListView {
        id: rulerView
        anchors.fill: parent
        clip: true
        orientation: ListView.Horizontal
        model: root.values
        currentIndex: root.currentIndex

        readonly property real tickInterval: width / root.visibleItemCount

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
                visible: tickItem.isLabeled && !root.autoMode
                anchors.horizontalCenter: parent.horizontalCenter
                y: centerIndicator.y - 7 - implicitHeight
                text: tickItem.modelData
                font.pixelSize: 26
                style: Text.Outline
                styleColor: "#40000000"
                opacity: {
                    var centerFade = tickItem.displacement < 0.3
                                     ? 0
                                     : Math.min(1, (tickItem.displacement - 0.3) * 1.5)
                    var distFade = Math.max(0.1, 1.0 - tickItem.displacement * 0.18)
                    return centerFade * distFade
                }
            }

            Rectangle {
                id: tickMark
                anchors.horizontalCenter: parent.horizontalCenter
                y: centerIndicator.y + centerIndicator.height - height
                width: 2
                height: 26
                color: Constants.textSecondaryColor
                border.color: "#40000000"
                border.width: 1
                opacity: Math.max(0.1, 1.0 - tickItem.displacement * 0.18)
            }
        }

        highlight: Item {}
        onMovementStarted: root.manualModeRequested()
    }

    Label {
        id: centerValueLabel
        anchors.horizontalCenter: parent.horizontalCenter
        y: centerIndicator.y - 7 - implicitHeight
        text: root.centerText
        font.pixelSize: 26
        color: Material.accent
        font.capitalization: Font.AllUppercase
        font.weight: Font.Normal
    }

    Rectangle {
        id: centerIndicator
        visible: !root.autoMode
        width: 3
        height: 44
        color: Material.accent
        border.color: "#40000000"
        border.width: 1
        anchors.verticalCenterOffset: 12
        anchors.centerIn: parent
    }
    states: [
        State {
            name: "manual"

            PropertyChanges {
                target: root
                autoMode: false
            }
        }
    ]
}
