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

    readonly property var formats: [{
            "res": "5.5K",
            "maxFps": 30
        }, {
            "res": "4K",
            "maxFps": 60
        }, {
            "res": "2K",
            "maxFps": 60
        }]

    readonly property list<int> fpsOptions: [60, 50, 30, 25, 24]

    property int selectedResolutionIndex: 0
    property int selectedFps: 24

    readonly property var resolutions: formats.map(f => f.res)
    readonly property var _filteredFps: fpsOptions.filter(
                                            fps => fps <= formats[selectedResolutionIndex].maxFps)
    readonly property var currentFpsOptions: _filteredFps || fpsOptions
    onCurrentFpsOptionsChanged: {
        if (currentFpsOptions.indexOf(selectedFps) < 0)
            selectedFps = currentFpsOptions[0]
    }
    readonly property string selectedResolution: formats[selectedResolutionIndex].res
    readonly property int selectedFpsIndex: Math.max(0,
                                                     currentFpsOptions.indexOf(
                                                         selectedFps))

    ColumnLayout {
        spacing: 21

        RowLayout {
            spacing: 34
            Layout.alignment: Qt.AlignLeft

            Label {
                text: "RES"
                font.pixelSize: 21
                font.weight: Font.Medium
                color: "#999999"
            }

            ButtonToggleGroup {
                values: sheet.resolutions
                selectedIndex: sheet.selectedResolutionIndex
                onSelected: index => sheet.selectedResolutionIndex = index
            }
        }

        RowLayout {
            spacing: 34
            Layout.alignment: Qt.AlignLeft

            Label {
                text: "FPS"
                font.pixelSize: 21
                font.weight: Font.Medium
                color: "#999999"
            }

            ButtonToggleGroup {
                values: sheet.currentFpsOptions
                selectedIndex: sheet.selectedFpsIndex
                onSelected: index => sheet.selectedFps = values[index]
            }
        }
    }
}
