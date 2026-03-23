import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import CinePiUi

Rectangle {
    id: panel
    implicitHeight: 98
    color: "#40000000"

    property var values: []
    property var labeledValues: []
    property int currentIndex: 5
    property int visibleTickCount: 11
    property bool showAutoButton: true
    property bool autoMode: true
    property string suffix: ""

    property int minValue: 0
    property int maxValue: 0
    property int step: 0

    readonly property var effectiveValues: {
        if (step > 0 && maxValue > minValue) {
            let arr = []
            for (let v = minValue; v <= maxValue; v += step)
                arr.push(v)
            return arr
        }
        return values
    }

    readonly property string currentValue: picker.currentValue
    readonly property string displayText: (autoMode ? "A " : "") + currentValue + suffix

    RowLayout {
        id: panelRow
        anchors.fill: parent
        anchors.leftMargin: Constants.spacingLarge
        anchors.rightMargin: Constants.spacingLarge

        Button {
            id: autoButton
            visible: panel.showAutoButton
            text: panel.autoMode ? qsTr("AUTO") : qsTr("MANUAL")
            Layout.preferredWidth: 108
            checkable: true
            checked: panel.autoMode
            background: Rectangle {
                color: "#66545454"
                radius: height / 5
            }
            contentItem: Label {
                text: autoButton.text
                font.pixelSize: 22
                color: autoButton.checked ? Material.accent : Material.foreground
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.weight: Font.Medium
                font.capitalization: Font.AllUppercase
            }
            onClicked: panel.autoMode = !panel.autoMode
        }

        RulerPicker {
            id: picker
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: panel.showAutoButton ? autoButton.width + panelRow.spacing : 0
            values: panel.effectiveValues
            labeledValues: panel.labeledValues
            currentIndex: panel.currentIndex
            visibleTickCount: panel.visibleTickCount
            displayText: (panel.autoMode ? "A " : "") + panel.currentValue
            displaySuffix: panel.suffix
            showLabels: !panel.autoMode
            showIndicator: !panel.autoMode
            centered: panel.autoMode
            onCurrentIndexChanged: panel.currentIndex = currentIndex
            onMovementStarted: panel.autoMode = false
        }
    }
}
