

/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
It is supposed to be strictly declarative and only uses a subset of QML. If you edit
this file manually, you might introduce QML code that is not supported by Qt Design Studio.
Check out https://doc.qt.io/qtcreator/creator-quick-ui-forms.html for details on .ui.qml files.
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import CinePiUi

Rectangle {
    id: root
    width: Constants.width
    height: Constants.height
    color: Constants.backgroundColor
    border.width: 0
    property alias previewArea: previewArea
    property alias isoButton: isoButton
    property alias isoModeButton: isoModeButton
    property alias rulerPicker: rulerPicker
    property string isoDisplayText: isoAuto ? "A "
                                              + rulerPicker.currentValue : rulerPicker.currentValue
    property bool isoAuto: true
    property int isoValue: rulerPicker.currentIndex
                           >= 0 ? rulerPicker.values[rulerPicker.currentIndex] : 0

    Pane {
        id: statusBar
        height: 100
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
    }

    Rectangle {
        id: preview
        color: Constants.backgroundColor
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: statusBar.bottom
        anchors.bottom: controlsBar.top

        MouseArea {
            id: previewArea
            anchors.fill: parent
        }
    }

    Pane {
        id: isoPanel
        height: 60
        opacity: 0
        visible: opacity > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: controlsBar.top
        z: 1
        topPadding: 0
        bottomPadding: 0

        Button {
            id: isoModeButton
            text: checked ? qsTr("MANUAL") : qsTr("AUTO")
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            implicitWidth: manualMetrics.width + leftPadding + rightPadding
            flat: true
            checkable: true
            checked: !root.isoAuto
            background: Item {}
            contentItem: Label {
                text: isoModeButton.text
                color: isoModeButton.checked ? Constants.textColor : Constants.accentColor
                font: manualMetrics.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            TextMetrics {
                id: manualMetrics
                font.bold: true
                font.pixelSize: 13
                text: qsTr("MANUAL")
            }
        }

        RulerPicker {
            id: rulerPicker
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: isoModeButton.right
            anchors.right: parent.right
            autoMode: root.isoAuto
            displayText: root.isoDisplayText
        }
    }

    Pane {
        id: controlsBar
        height: 100
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Button {
            id: isoButton
            width: 86
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            flat: true
            checkable: true
            background: Item {}
            Material.foreground: isoButton.checked
                                 || !root.isoAuto ? Constants.accentColor : Constants.textColor
            contentItem: Column {
                id: column
                anchors.centerIn: parent

                Label {
                    id: isoLabel
                    text: qsTr("ISO")
                    font.weight: Font.DemiBold
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Label {
                    id: isoValueLabel
                    text: root.isoDisplayText
                    font.styleName: "Bold"
                    font.pointSize: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        RoundButton {
            id: recordButton
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            checkable: true
            display: AbstractButton.IconOnly
        }
    }
    states: [
        State {
            name: "iso"
            when: isoButton.checked

            PropertyChanges {
                target: isoPanel
                opacity: 1
            }
        }
    ]
    transitions: [
        Transition {
            id: transition
            ParallelAnimation {
                SequentialAnimation {
                    PauseAnimation {
                        duration: 0
                    }

                    PropertyAnimation {
                        target: isoPanel
                        property: "opacity"
                        duration: 250
                    }
                }
            }
            to: "*"
            from: "*"
        }
    ]
}

/*##^##
Designer {
    D{i:0}D{i:19;transitionDuration:2000}
}
##^##*/

