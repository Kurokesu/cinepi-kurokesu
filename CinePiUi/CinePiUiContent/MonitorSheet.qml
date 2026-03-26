import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import CinePiUi

Pane {
    id: sheet
    implicitWidth: 720
    topPadding: 21
    bottomPadding: 0
    leftPadding: Constants.spacingLarge
    rightPadding: Constants.spacingLarge
    background: Rectangle {
        color: "#40000000"
    }

    property bool zebraEnabled: false
    property bool peakingEnabled: false
    property bool falseColorEnabled: false
    property bool grayscaleEnabled: false

    RowLayout {
        spacing: 34

        Label {
            text: "MONITOR"
            font.pixelSize: 21
            font.weight: Font.Medium
            color: "#999999"
            Layout.alignment: Qt.AlignVCenter
        }

        IconToggle {
            icon.source: "images/texture_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Zebra"
            checked: sheet.zebraEnabled
            onClicked: sheet.zebraEnabled = checked
        }

        IconToggle {
            icon.source: "images/center_focus_weak_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Focus Peaking"
            checked: sheet.peakingEnabled
            onClicked: sheet.peakingEnabled = checked
        }

        IconToggle {
            icon.source: "images/palette_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "False Color"
            checked: sheet.falseColorEnabled
            onClicked: sheet.falseColorEnabled = checked
        }

        IconToggle {
            icon.source: "images/filter_b_and_w_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Grayscale"
            checked: sheet.grayscaleEnabled
            onClicked: sheet.grayscaleEnabled = checked
        }
    }
}
