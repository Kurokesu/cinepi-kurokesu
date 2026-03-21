import QtQuick
import CinePiUi
import QtQuick.VirtualKeyboard

Window {
    width: mainScreen.width
    height: mainScreen.height

    visible: true
    title: "CinePiUi"

    Main {
        id: mainScreen

        anchors.centerIn: parent

        previewArea.onClicked: {
            isoButton.checked = false
            shutterButton.checked = false
            wbButton.checked = false
        }
    }

    InputPanel {
        id: inputPanel
        property bool showKeyboard: active
        y: showKeyboard ? parent.height - height : parent.height
        Behavior on y {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }
        anchors.leftMargin: Constants.width / 10
        anchors.rightMargin: Constants.width / 10
        anchors.left: parent.left
        anchors.right: parent.right
    }
}
