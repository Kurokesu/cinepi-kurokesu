import QtQuick
import CinePiUi
import QtQuick.Controls
import QtQuick.VirtualKeyboard

ApplicationWindow {
    id: applicationWindow
    width: mainScreen.width
    height: mainScreen.height

    visible: true
    title: "CinePiUi"
    font.family: Constants.fontFamily

    Main {
        id: mainScreen

        anchors.centerIn: parent

        viewfinderArea.onClicked: mainScreen.state = ""
    }

    Connections {
        target: mainScreen.recordButton
        function onCheckedChanged() {
            if (mainScreen.recordButton.checked
                    && (mainScreen.state === "formatOpen"
                        || mainScreen.state === "aspectOpen"
                        || mainScreen.state === "guideOpen"
                        || mainScreen.state === "monitorOpen"))
                mainScreen.state = ""
        }
    }

    Connections {
        target: mainScreen.settingsView.item
        function onClosed() {
            mainScreen.state = ""
        }
    }

    ButtonGroup {
        exclusive: false
        buttons: [mainScreen.formatButton, mainScreen.aspectButton, mainScreen.guideButton, mainScreen.monitorButton, mainScreen.isoButton, mainScreen.shutterButton, mainScreen.wbButton, mainScreen.menuButton]
        onClicked: button => mainScreen.state = mainScreen.state
                   === button.objectName ? "" : button.objectName
    }

    InputPanel {
        id: inputPanel
        property bool showKeyboard: active
        visible: active
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
