import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "components"

ApplicationWindow {
    id: appWindow
    visible: true
    width: 720
    height: 720
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint
    title: "CinePI-Qt"
    color: "#000000"

    // Aliases to C++ context properties (avoid scope collision with MainLayout property names)
    property var cameraBackend: camera
    property var configBackend: config

    MainLayout {
        anchors.fill: parent
        camera: appWindow.cameraBackend
        config: appWindow.configBackend

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
            zebraEnabled: appWindow.configBackend.zebraEnabled
            zebraThreshold: appWindow.configBackend.zebraThreshold
            falseColorEnabled: appWindow.configBackend.falseColorEnabled
            focusPeakingEnabled: appWindow.configBackend.focusPeakingEnabled
            grayscaleEnabled: appWindow.configBackend.grayscaleEnabled
        }
    }
}
