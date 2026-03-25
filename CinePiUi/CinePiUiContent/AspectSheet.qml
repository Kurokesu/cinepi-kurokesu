import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import CinePiUi

Pane {
    id: sheet
    implicitWidth: 720
    padding: 21
    leftPadding: Constants.spacingLarge
    rightPadding: Constants.spacingLarge
    background: Rectangle {
        color: "#40000000"
    }

    readonly property list<string> ratios: ["16:9", "2.39:1", "1.85:1", "4:3", "1:1"]
    property int selectedIndex: 0
    readonly property string selectedRatio: ratios[selectedIndex]

    RowLayout {
        spacing: 34

        Label {
            text: "ASPECT"
            font.pixelSize: 21
            font.weight: Font.Medium
            color: "#999999"
        }

        ButtonToggleGroup {
            values: sheet.ratios
            selectedIndex: sheet.selectedIndex
            onSelected: index => sheet.selectedIndex = index
        }
    }
}
