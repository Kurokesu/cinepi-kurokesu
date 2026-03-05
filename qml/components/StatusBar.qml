import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    color: Theme.barOverlay

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        StatusItem {
            label: "RES"
            value: camera.width > 0 ? (camera.width + "x" + camera.height) : "---"
        }

        Rectangle {
            width: 1; height: 28
            color: Theme.separator
            Layout.alignment: Qt.AlignVCenter
        }

        StatusItem {
            label: "FPS"
            value: camera.fps > 0 ? camera.fps.toString() : "---"
        }

        Item { Layout.fillWidth: true }
    }

    component StatusItem: Column {
        property string label: ""
        property string value: ""
        property bool highlight: false
        property string _prevValue: ""

        Layout.alignment: Qt.AlignVCenter
        spacing: 1

        Text {
            text: parent.label
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontLabel
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
        }

        Item {
            width: Math.max(valCurrent.implicitWidth, valPrev.implicitWidth)
            height: valCurrent.implicitHeight

            Text {
                id: valPrev
                anchors.fill: parent
                text: parent.parent._prevValue
                color: parent.parent.highlight ? Theme.accent : Theme.textPrimary
                font.pixelSize: 17
                font.family: Theme.fontValue
                font.weight: Font.Bold
                opacity: 0
            }

            Text {
                id: valCurrent
                anchors.fill: parent
                text: parent.parent.value
                color: parent.parent.highlight ? Theme.accent : Theme.textPrimary
                font.pixelSize: 17
                font.family: Theme.fontValue
                font.weight: Font.Bold
                opacity: 1
            }
        }

        onValueChanged: {
            if (_prevValue !== "" && _prevValue !== value) {
                crossfadeAnim.restart()
            }
            _prevValue = value
        }

        SequentialAnimation {
            id: crossfadeAnim
            NumberAnimation { target: valCurrent; property: "opacity"; from: 0; to: 1; duration: Theme.durationFast }
        }
    }
}
