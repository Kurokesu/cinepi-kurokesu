// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026, UAB Kurokesu

import QtQuick

Item {
    id: root

    property bool thirdsEnabled: false
    property bool goldenEnabled: false
    property bool crosshairEnabled: false
    property bool centerDotEnabled: false

    property color guideColor: "#999999"
    property real lineWidth: 1

    Repeater {
        model: root.thirdsEnabled ? 2 : 0
        Rectangle {
            x: root.width * (index + 1) / 3
            width: root.lineWidth
            height: root.height
            color: root.guideColor
        }
    }
    Repeater {
        model: root.thirdsEnabled ? 2 : 0
        Rectangle {
            y: root.height * (index + 1) / 3
            width: root.width
            height: root.lineWidth
            color: root.guideColor
        }
    }

    readonly property real phi: 0.6180339887

    Repeater {
        model: root.goldenEnabled ? 2 : 0
        Rectangle {
            x: root.width * (index === 0 ? 1 - root.phi : root.phi)
            width: root.lineWidth
            height: root.height
            color: root.guideColor
        }
    }
    Repeater {
        model: root.goldenEnabled ? 2 : 0
        Rectangle {
            y: root.height * (index === 0 ? 1 - root.phi : root.phi)
            width: root.width
            height: root.lineWidth
            color: root.guideColor
        }
    }

    readonly property real crosshairSize: Math.min(root.width, root.height) * 0.06

    Rectangle {
        visible: root.crosshairEnabled
        x: root.width / 2 - root.lineWidth / 2
        y: root.height / 2 - root.crosshairSize
        width: root.lineWidth
        height: root.crosshairSize * 2
        color: root.guideColor
    }
    Rectangle {
        visible: root.crosshairEnabled
        x: root.width / 2 - root.crosshairSize
        y: root.height / 2 - root.lineWidth / 2
        width: root.crosshairSize * 2
        height: root.lineWidth
        color: root.guideColor
    }

    Rectangle {
        visible: root.centerDotEnabled
        width: 8
        height: 8
        radius: 4
        color: root.guideColor
        x: root.width / 2 - 4
        y: root.height / 2 - 4
    }
}
