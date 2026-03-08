import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AbstractButton {
    id: root

    property string label: ""
    property string value: ""
    property var values: []
    property var currentValue
    property var setter

    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.margins: 4

    background: Rectangle {
        radius: Theme.radiusMedium
        color: Theme.surfaceHover
        scale: root.pressed ? Theme.pressScale : 1.0

        Behavior on scale {
            SpringAnimation { spring: 4; damping: 0.6 }
        }
    }

    contentItem: Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontLabel
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.value
            color: Theme.textPrimary
            font.pixelSize: 20
            font.family: Theme.fontValue
            font.weight: Font.Bold
        }
    }

    DragHandler {
        target: null
        yAxis.enabled: true
        xAxis.enabled: false
        onTranslationChanged: {
            if (!root.values || root.values.length === 0 || !root.setter) return
            var idx = root.values.indexOf(root.currentValue)
            if (idx < 0) return
            var steps = Math.round(-translation.y / 80)
            var newIdx = Math.max(0, Math.min(root.values.length - 1, idx + steps))
            if (newIdx !== idx) root.setter(root.values[newIdx])
        }
    }
}
