import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "components"

ApplicationWindow {
    id: root
    visible: true
    width: 720
    height: 720
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint
    title: "CinePI-Qt"
    color: "#000000"

    MainLayout {
        anchors.fill: parent

        CameraPreview {
            id: cameraPreview
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
        }

        ShaderEffectSource {
            id: previewTexture
            sourceItem: cameraPreview
            live: true
            hideSource: false
        }

        ShaderOverlays {
            id: shaderOverlays
            anchors.fill: parent
            source: previewTexture
        }
    }
}
