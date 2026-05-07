// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026, UAB Kurokesu

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

    property bool thirdsEnabled: false
    property bool goldenEnabled: false
    property bool crosshairEnabled: false
    property bool centerDotEnabled: false

    RowLayout {
        spacing: 34

        Label {
            text: "GUIDES"
            font.pixelSize: 21
            font.weight: Font.Medium
            color: "#999999"
            Layout.alignment: Qt.AlignVCenter
        }

        IconToggle {
            icon.source: "images/grid_3x3_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Thirds"
            checked: sheet.thirdsEnabled
            onClicked: sheet.thirdsEnabled = checked
        }

        IconToggle {
            icon.source: "images/grid_goldenratio_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Golden"
            checked: sheet.goldenEnabled
            onClicked: sheet.goldenEnabled = checked
        }

        IconToggle {
            icon.source: "images/point_scan_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Crosshair"
            checked: sheet.crosshairEnabled
            onClicked: sheet.crosshairEnabled = checked
        }

        IconToggle {
            icon.source: "images/adjust_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Center"
            checked: sheet.centerDotEnabled
            onClicked: sheet.centerDotEnabled = checked
        }
    }
}
