import QtQuick
import QtQuick.Controls.Basic
import "../components"

Rectangle {
    id: mockRoot
    width: 720
    height: 720
    color: "#000000"


    QtObject {
        id: mockCamera
        property int iso: 800
        property int shutterAngle: 180
        property double shutterSpeed: 0.00555
        property int fps: 30
        property int whiteBalance: 0
        property bool recording: false
        property int width: 2736
        property int height: 1824
        property bool connected: true
        property int compression: 0
        property int frameCount: 1234
        property int bufferSize: 0

        function setISO(val) { iso = val }
        function setShutterAngle(val) { shutterAngle = val }
        function setFPS(val) { fps = val }
        function setWhiteBalance(val) { whiteBalance = val }
        function setRecording(val) { recording = val }
        function setCompression(val) { compression = val }
        function setColorGains(r, b) {}
    }

    QtObject {
        id: mockConfig
        property bool zebraEnabled: false
        property double zebraThreshold: 0.95
        property bool falseColorEnabled: false
        property bool focusPeakingEnabled: false
        property bool grayscaleEnabled: false
        property bool thirdsGridEnabled: false
        property bool crosshairEnabled: false
        property bool cinematicGuideEnabled: false
        property bool cinematicGuide185Enabled: false
        property bool cinematicGuide43Enabled: false
    }

    MainLayout {
        anchors.fill: parent
        camera: mockCamera
        config: mockConfig

        Rectangle {
            anchors.fill: parent
            color: "#1E1E1E"

            Column {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "CAMERA PREVIEW"
                    color: Theme.textTertiary
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    font.family: Theme.fontLabel
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: mockCamera.width + "x" + mockCamera.height + " @ " + mockCamera.fps + "fps"
                    color: Theme.surfacePressed
                    font.pixelSize: 14
                    font.family: Theme.fontValue
                }
            }
        }
    }

}

/*##^##
Designer {
    D{i:0}D{i:1;invisible:true}D{i:2;invisible:true}D{i:4;invisible:true}D{i:5;invisible:true}
}
##^##*/
