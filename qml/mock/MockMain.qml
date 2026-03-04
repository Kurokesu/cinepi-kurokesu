import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

/**
 * MockMain.qml — Open this file in Qt Design Studio to preview the UI.
 *
 * Provides mock camera and config objects so all QML components render
 * with realistic placeholder values at 720x720 (HyperPixel display).
 *
 * The DmaBufPreview C++ type is replaced by a simple grey rectangle
 * via MockDmaBufPreview.qml.
 */
ApplicationWindow {
    id: mockRoot
    visible: true
    width: 720
    height: 720
    title: "CinePI — Mock Preview"
    color: "#000000"

    // ── Mock camera object ──────────────────────────────────────
    QtObject {
        id: camera

        property int iso: 800
        property int shutterAngle: 180
        property double shutterSpeed: 0.00555
        property int fps: 30
        property int whiteBalance: 0
        property bool recording: false
        property int width: 2736
        property int height: 1824
        property bool connected: true
        property double colorGainR: 1.90
        property double colorGainB: 1.57
        property int compression: 0
        property int frameCount: 1234
        property int bufferSize: 0

        function setISO(val) { iso = val }
        function setShutterAngle(val) { shutterAngle = val }
        function setFPS(val) { fps = val }
        function setWhiteBalance(val) { whiteBalance = val }
        function setRecording(val) { recording = val }
        function setCompression(val) { compression = val }
        function setColorGains(r, b) { colorGainR = r; colorGainB = b }
    }

    // ── Mock config object ──────────────────────────────────────
    QtObject {
        id: config

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

    // ── UI (same structure as real main.qml) ────────────────────
    property bool settingsVisible: false

    Item {
        id: viewArea
        anchors.fill: parent

        // Mock camera preview (grey rectangle instead of DmaBufPreview)
        Rectangle {
            anchors.fill: parent
            color: "#2A2A2A"

            Column {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "CAMERA PREVIEW"
                    color: "#555555"
                    font.pixelSize: 20
                    font.bold: true
                    font.family: "monospace"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: camera.width + "x" + camera.height + " @ " + camera.fps + "fps"
                    color: "#444444"
                    font.pixelSize: 14
                    font.family: "monospace"
                }
            }
        }

        // Grid overlays (work as-is, no C++ dependency)
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
                mockRoot.settingsVisible = !mockRoot.settingsVisible
            }
        }

        // Recording indicator
        Rectangle {
            visible: camera.recording
            anchors.top: statusBar.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            width: 16
            height: 16
            radius: 8
            color: "#FF0000"

            SequentialAnimation on opacity {
                running: camera.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 500 }
                NumberAnimation { to: 1.0; duration: 500 }
            }
        }
    }

    // Dark overlay behind settings
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: mockRoot.settingsVisible ? 0.4 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mockRoot.settingsVisible = false
        }
    }

    // Settings panel
    SettingsPanel {
        id: settingsPanel
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: Math.min(320, parent.width * 0.5)
        visible: mockRoot.settingsVisible

        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        onCloseRequested: {
            mockRoot.settingsVisible = false
        }
    }

    // Connection toast
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 90
        anchors.horizontalCenter: parent.horizontalCenter
        width: connLabel.width + 24
        height: 28
        radius: 14
        color: camera.connected ? "#44008800" : "#AACC0000"
        visible: !camera.connected

        Label {
            id: connLabel
            anchors.centerIn: parent
            text: camera.connected ? "Connected" : "Camera disconnected"
            color: "#FFFFFF"
            font.pixelSize: 11
        }
    }
}
