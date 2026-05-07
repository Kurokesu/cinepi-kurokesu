// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026, UAB Kurokesu

import QtQuick
import QtQuick.Controls.Material

Button {
    id: controlButton
    flat: true
    implicitWidth: 89

    property string label: "LABEL"
    property string value: "- ---"

    Material.foreground: controlButton.checked
                         || controlButton.highlighted ? Material.accent : controlButton.parent.Material.foreground

    background: Item {}

    contentItem: Column {
        spacing: 5
        anchors.centerIn: parent

        Label {
            text: controlButton.label
            font.pixelSize: 24
            font.weight: Font.Normal
            font.capitalization: Font.AllUppercase
            style: Text.Outline
            styleColor: "#40000000"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: controlButton.value
            font.pixelSize: 22
            font.weight: Font.Bold
            font.capitalization: Font.AllUppercase
            style: Text.Outline
            styleColor: "#40000000"
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
