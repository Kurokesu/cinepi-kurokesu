import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import CinePiUi

Pane {
    id: sheet
    implicitHeight: 98
    padding: 0
    leftPadding: Constants.spacingLarge
    rightPadding: Constants.spacingLarge
    background: Rectangle {
        color: "#40000000"
    }

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
        id: sheetRow
        anchors.fill: parent

        Button {
            id: autoButton
            visible: sheet.showAutoButton
            text: sheet.autoMode ? qsTr("AUTO") : qsTr("MANUAL")
            Layout.preferredWidth: 108
            checkable: true
            checked: sheet.autoMode
            background: Rectangle {
                color: "#2b000000"
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
            onClicked: sheet.autoMode = !sheet.autoMode
        }

        RulerPicker {
            id: picker
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.rightMargin: sheet.showAutoButton ? autoButton.width + sheetRow.spacing : 0
            values: sheet.effectiveValues
            labeledValues: sheet.labeledValues
            currentIndex: sheet.currentIndex
            visibleTickCount: sheet.visibleTickCount
            displayText: (sheet.autoMode ? "A " : "") + sheet.currentValue
            displaySuffix: sheet.suffix
            showLabels: !sheet.autoMode
            showIndicator: !sheet.autoMode
            centered: sheet.autoMode
            onCurrentIndexChanged: sheet.currentIndex = currentIndex
            onMovementStarted: sheet.autoMode = false
        }
    }
}
