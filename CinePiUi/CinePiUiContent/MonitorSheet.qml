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

    property bool zebraEnabled: false
    property bool focusPeakingEnabled: false
    property bool falseColorEnabled: false
    property bool grayscaleEnabled: false

    function setActiveEffect(effect) {
        zebraEnabled = (effect === "zebra")
        focusPeakingEnabled = (effect === "focusPeaking")
        falseColorEnabled = (effect === "falseColor")
        grayscaleEnabled = (effect === "grayscale")
        zebraToggle.checked = zebraEnabled
        focusPeakingToggle.checked = focusPeakingEnabled
        falseColorToggle.checked = falseColorEnabled
        grayscaleToggle.checked = grayscaleEnabled
    }

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
            id: zebraToggle
            icon.source: "images/texture_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Zebra"
            checked: sheet.zebraEnabled
            onClicked: sheet.setActiveEffect(checked ? "zebra" : "")
        }

        IconToggle {
            id: focusPeakingToggle
            icon.source: "images/center_focus_weak_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Focus Peaking"
            checked: sheet.focusPeakingEnabled
            onClicked: sheet.setActiveEffect(checked ? "focusPeaking" : "")
        }

        IconToggle {
            id: falseColorToggle
            icon.source: "images/palette_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "False Color"
            checked: sheet.falseColorEnabled
            onClicked: sheet.setActiveEffect(checked ? "falseColor" : "")
        }

        IconToggle {
            id: grayscaleToggle
            icon.source: "images/filter_b_and_w_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
            text: "Grayscale"
            checked: sheet.grayscaleEnabled
            onClicked: sheet.setActiveEffect(checked ? "grayscale" : "")
        }
    }
}
