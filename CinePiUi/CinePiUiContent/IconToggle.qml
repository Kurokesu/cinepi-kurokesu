// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026, UAB Kurokesu

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: root
    text: "Guide"
    rightPadding: 16
    leftPadding: 16
    topPadding: 25
    bottomPadding: 15
    checkable: true
    display: AbstractButton.IconOnly
    icon.source: "images/grid_3x3_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
    icon.color: checked ? Material.accent : Material.foreground
    icon.width: 62
    icon.height: 62
    background: Label {
        color: "#999999"
        text: parent.text
        anchors.fill: parent
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
    }
}
