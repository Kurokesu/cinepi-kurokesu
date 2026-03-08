import QtQuick
import QtQuick.Layouts

Column {
    id: root

    property string label: ""
    property string value: ""
    property bool highlight: false
    property string _prevValue: ""

    Layout.alignment: Qt.AlignVCenter
    spacing: 1

    Text {
        text: root.label
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
            text: root._prevValue
            color: root.highlight ? Theme.accent : Theme.textPrimary
            font.pixelSize: 17
            font.family: Theme.fontValue
            font.weight: Font.Bold
            opacity: 0
        }

        Text {
            id: valCurrent
            anchors.fill: parent
            text: root.value
            color: root.highlight ? Theme.accent : Theme.textPrimary
            font.pixelSize: 17
            font.family: Theme.fontValue
            font.weight: Font.Bold
            opacity: 1
        }
    }

    onValueChanged: {
        if (_prevValue !== "" && _prevValue !== value)
            crossfadeAnim.restart()
        _prevValue = value
    }

    SequentialAnimation {
        id: crossfadeAnim
        NumberAnimation { target: valCurrent; property: "opacity"; from: 0; to: 1; duration: Theme.durationFast }
    }
}
