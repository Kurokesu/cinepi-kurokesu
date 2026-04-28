// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026, UAB Kurokesu

import QtQuick
import QtQuick.Controls.Material

RoundButton {
    id: recordButton
    implicitWidth: 89
    implicitHeight: 89
    checkable: true
    flat: true

    readonly property real dotScale: 0.38
    readonly property real dotRecordingScale: 0.27

    background: Rectangle {
        id: recordButtonFill
        radius: width / 2
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2
            border.color: "#ffffff"
        }
    }

    contentItem: Item {
        Rectangle {
            id: recordButtonDot
            anchors.centerIn: parent
            width: recordButton.width * dotScale
            height: width
            radius: width / 2
            color: Material.accent
        }
    }

    states: State {
        name: "recording"
        when: recordButton.checked
        PropertyChanges {
            target: recordButtonFill
            color: Material.accent
        }
        PropertyChanges {
            target: recordButtonDot
            width: recordButton.width * dotRecordingScale
            radius: width / 6
            color: "#ffffff"
        }
    }

    transitions: Transition {
        ColorAnimation {
            duration: 200
        }
        NumberAnimation {
            properties: "width,height,radius"
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }
}
