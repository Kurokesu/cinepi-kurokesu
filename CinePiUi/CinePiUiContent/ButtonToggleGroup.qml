// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026, UAB Kurokesu

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Item {
    id: root

    property var values: [1, 2, 3]
    property int selectedIndex: 0

    signal selected(int index)

    implicitWidth: buttonRow.implicitWidth
    implicitHeight: buttonRow.implicitHeight

    Rectangle {
        anchors.fill: parent
        color: "#2b000000"
        radius: height / 2
    }

    Row {
        id: buttonRow

        ButtonGroup {
            buttons: buttonRow.children.filter(
                         child => child !== buttonRepeater)
        }

        Repeater {
            id: buttonRepeater
            model: root.values
            Button {
                required property var modelData
                required property int index

                text: modelData
                font.pixelSize: 21
                font.weight: checked ? Font.Bold : Font.Normal
                checkable: true
                checked: index === root.selectedIndex
                onClicked: root.selected(index)

                background: Rectangle {
                    color: parent.checked ? "#40000000" : "transparent"
                    anchors.fill: parent
                    topLeftRadius: parent.Positioner.isFirstItem ? height / 2 : 0
                    topRightRadius: parent.Positioner.isLastItem ? height / 2 : 0
                    bottomLeftRadius: parent.Positioner.isFirstItem ? height / 2 : 0
                    bottomRightRadius: parent.Positioner.isLastItem ? height / 2 : 0
                }
            }
        }
    }
}
