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
    property string displayText: currentValue
    signal manualModeRequested()

    readonly property real delegateWidth: rulerView.width / visibleItemCount
    readonly property real tickHeight: height * 0.27
    readonly property real indicatorHeight: height * 0.45
    readonly property real labelFontSize: height * 0.22
    readonly property real centerFontSize: height * 0.25
    readonly property real labelSpacing: height * 0.07
    readonly property real groupHeight: centerFontSize * 1.2 + labelSpacing + indicatorHeight
    readonly property real tickBottomY: (height + groupHeight) / 2
    readonly property real labelBottomY: tickBottomY - indicatorHeight - labelSpacing
    readonly property string currentValue: values[currentIndex] !== undefined
                                           ? values[currentIndex].toString() : ""

    ListView {
        id: rulerView
        anchors.fill: parent
        clip: true
        orientation: ListView.Horizontal
        model: root.values
        currentIndex: root.currentIndex

        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - root.delegateWidth / 2
        preferredHighlightEnd: width / 2 + root.delegateWidth / 2

        highlightMoveDuration: 300

        onCurrentIndexChanged: root.currentIndex = currentIndex

        delegate: Item {
            id: delegateItem
            width: root.delegateWidth
            height: rulerView.height

            required property int index
            required property var modelData

            readonly property real displacement: {
                let center = rulerView.contentX + rulerView.width / 2
                let itemCenter = x + width / 2
                return Math.abs((itemCenter - center) / width)
            }
            readonly property bool isLabeled: root.labeledValues.includes(modelData)

            Label {
                visible: delegateItem.isLabeled && !root.autoMode
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.labelBottomY - implicitHeight
                text: delegateItem.modelData
                font.pixelSize: root.labelFontSize
                opacity: {
                    var centerFade = delegateItem.displacement < 0.3
                                     ? 0
                                     : Math.min(1, (delegateItem.displacement - 0.3) * 1.5)
                    var distFade = Math.max(0.1, 1.0 - delegateItem.displacement * 0.18)
                    return centerFade * distFade
                }
            }

            Rectangle {
                id: tickMark
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.tickBottomY - height
                width: 2
                height: root.tickHeight
                color: Constants.textSecondaryColor
                opacity: Math.max(0.1, 1.0 - delegateItem.displacement * 0.18)
            }
        }

        highlight: Item {}
        onMovementStarted: root.manualModeRequested()
    }

    Label {
        id: centerValueLabel
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.labelBottomY - implicitHeight
        text: root.displayText
        font.pixelSize: 26
        color: Material.accent
        font.capitalization: Font.AllUppercase
        font.weight: Font.Normal
    }

    Rectangle {
        id: centerIndicator
        visible: !root.autoMode
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.tickBottomY - height
        width: 3
        height: root.indicatorHeight
        color: Material.accent
    }
}
