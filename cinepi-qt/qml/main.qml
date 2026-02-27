import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    visible: true
    width: 720
    height: 720
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint
    title: "CinePI-Qt"
    color: "#000000"

    // Track settings panel state
    property bool settingsVisible: false

    // Full-screen camera preview with overlays
    Item {
        id: viewArea
        anchors.fill: parent

        // Camera preview (MJPEG stream)
        CameraPreview {
            id: cameraPreview
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
        }

        // Capture preview as a texture for shader overlays
        ShaderEffectSource {
            id: previewTexture
            sourceItem: cameraPreview
            live: true
            hideSource: false
        }

        // Shader-based overlays (zebra, false color, focus peaking)
        ShaderOverlays {
            id: shaderOverlays
            anchors.fill: parent
            source: previewTexture
        }

        // Grid/guide overlays (thirds, crosshair, cinematic guides)
        GridOverlays {
            id: gridOverlays
            anchors.fill: parent
        }

        // Top status bar
        StatusBar {
            id: statusBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48
        }

        // Bottom camera controls
        CameraControls {
            id: cameraControls
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 80
            onSettingsRequested: {
                root.settingsVisible = !root.settingsVisible
            }
        }

        // Recording indicator (big red dot)
        Rectangle {
            visible: redis.recording
            anchors.top: statusBar.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: 16
            height: 16
            radius: 8
            color: "#FF0000"

            SequentialAnimation on opacity {
                running: redis.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }
    }

    // Dark overlay behind settings panel (must be BEFORE SettingsPanel for z-order)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: root.settingsVisible ? 0.4 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.settingsVisible = false
        }
    }

    // Settings panel (slides in from right, on top of dark overlay)
    SettingsPanel {
        id: settingsPanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: Math.min(320, parent.width * 0.5)
        visible: root.settingsVisible

        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            root.settingsVisible = false
        }
    }

    // Connection status toast
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 90
        anchors.horizontalCenter: parent.horizontalCenter
        width: connLabel.width + 24
        height: 28
        radius: 14
        color: redis.connected ? "#44008800" : "#AACC0000"
        visible: !redis.connected || !mjpeg.connected

        Label {
            id: connLabel
            anchors.centerIn: parent
            text: {
                if (!redis.connected) return "Redis disconnected"
                if (!mjpeg.connected) return "No camera stream"
                return "Connected"
            }
            color: "#FFFFFF"
            font.pixelSize: 11
        }
    }
}
