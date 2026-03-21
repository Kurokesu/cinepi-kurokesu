import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import CinePiUi

Rectangle {
    id: panel
    implicitHeight: 98
    color: "#40000000"

    property list<int> values
    property list<int> labeledValues
    property int currentIndex: 5
    property int visibleTickCount: 11
    property bool showAutoButton: true
    property bool autoMode: true
    property string suffix: ""

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
            values: panel.values
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
