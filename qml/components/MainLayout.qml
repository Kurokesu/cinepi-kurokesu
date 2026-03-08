import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    default property alias previewContent: previewContainer.data

    property var camera: QtObject {
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
    property var config: QtObject {
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

    property bool overlayVisible: true

    Item {
        id: viewArea
        anchors.fill: parent

        // --- Zoomable preview container ---
        Item {
            id: previewContainer
            anchors.fill: parent

            property real zoomScale: 1.0
            property real panX: 0.0
            property real panY: 0.0

            transform: [
                Scale {
                    origin.x: previewContainer.width / 2
                    origin.y: previewContainer.height / 2
                    xScale: previewContainer.zoomScale
                    yScale: previewContainer.zoomScale
                },
                Translate {
                    x: previewContainer.panX
                    y: previewContainer.panY
                }
            ]

            PinchHandler {
                target: null
                onScaleChanged: function(delta) {
                    var raw = previewContainer.zoomScale * delta
                    previewContainer.zoomScale = Math.max(0.85, Math.min(5.5, raw))
                }
                onTranslationChanged: function(delta) {
                    if (previewContainer.zoomScale > 1.0) {
                        previewContainer.panX += delta.x
                        previewContainer.panY += delta.y
                    }
                }
                onActiveChanged: {
                    if (!active) {
                        if (previewContainer.zoomScale < 1.0)
                            previewContainer.zoomScale = 1.0
                        else if (previewContainer.zoomScale > 5.0)
                            previewContainer.zoomScale = 5.0
                        if (previewContainer.zoomScale <= 1.0) {
                            previewContainer.panX = 0
                            previewContainer.panY = 0
                        }
                        zoomIndicatorTimer.restart()
                    }
                }
            }

            Behavior on zoomScale {
                SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
            }
            Behavior on panX {
                SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
            }
            Behavior on panY {
                SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
            }
        }

        // --- Zoom level indicator ---
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.controlBarHeight + Theme.recordButtonSize + 24
            width: zoomLabel.implicitWidth + 24
            height: 32
            radius: 16
            color: Theme.surface
            visible: previewContainer.zoomScale > 1.01

            Text {
                id: zoomLabel
                anchors.centerIn: parent
                text: previewContainer.zoomScale.toFixed(1) + "x"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.family: Theme.fontValue
                font.weight: Font.Bold
            }
        }

        Timer {
            id: zoomIndicatorTimer
            interval: 1500
        }

        // --- Grid overlays (fixed, don't zoom) ---
        GridOverlays {
            id: gridOverlays
            anchors.fill: parent
            thirdsGridEnabled: root.config ? root.config.thirdsGridEnabled : false
            crosshairEnabled: root.config ? root.config.crosshairEnabled : false
            cinematicGuideEnabled: root.config ? root.config.cinematicGuideEnabled : false
            cinematicGuide185Enabled: root.config ? root.config.cinematicGuide185Enabled : false
            cinematicGuide43Enabled: root.config ? root.config.cinematicGuide43Enabled : false
        }

        // --- Recording border pulse ---
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: root.camera && root.camera.recording ? Theme.recording : "transparent"
            border.width: root.camera && root.camera.recording ? 2 : 0
            z: 1

            SequentialAnimation on border.color {
                running: root.camera ? root.camera.recording : false
                loops: Animation.Infinite
                ColorAnimation { to: Qt.rgba(Theme.recording.r, Theme.recording.g, Theme.recording.b, 0.3); duration: 800; easing.type: Easing.InOutSine }
                ColorAnimation { to: Theme.recording; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        // --- Double-tap to toggle overlay ---
        TapHandler {
            onDoubleTapped: root.overlayVisible = !root.overlayVisible
        }

        // --- StatusBar ---
        StatusBar {
            id: statusBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: root.overlayVisible ? 0 : -height
            height: Theme.statusBarHeight
            z: 2

            Behavior on anchors.topMargin {
                SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
            }

            resWidth: root.camera ? root.camera.width : 0
            resHeight: root.camera ? root.camera.height : 0
            fps: root.camera ? root.camera.fps : 0
        }

        // --- Recording info pill ---
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: statusBar.bottom
            anchors.topMargin: 8
            width: recInfoRow.implicitWidth + 24
            height: 28
            radius: 14
            color: Theme.surface
            visible: root.camera ? root.camera.recording : false
            z: 2

            Row {
                id: recInfoRow
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: Theme.recording
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        running: root.camera ? root.camera.recording : false
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 600 }
                        NumberAnimation { to: 1.0; duration: 600 }
                    }
                }

                Text {
                    text: "REC"
                    color: Theme.recording
                    font.pixelSize: 13
                    font.family: Theme.fontLabel
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.camera && root.camera.frameCount > 0 ? root.camera.frameCount + " frames" : ""
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.family: Theme.fontValue
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                }
            }
        }

        // --- CameraControls ---
        CameraControls {
            id: cameraControls
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.overlayVisible ? 0 : -height
            height: Theme.controlBarHeight
            z: 2

            Behavior on anchors.bottomMargin {
                SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
            }

            iso: root.camera ? root.camera.iso : 800
            shutterAngle: root.camera ? root.camera.shutterAngle : 180
            whiteBalance: root.camera ? root.camera.whiteBalance : 0

            onIsoChangeRequested: function(val) { if (root.camera) root.camera.setISO(val) }
            onShutterAngleChangeRequested: function(val) { if (root.camera) root.camera.setShutterAngle(val) }
            onWhiteBalanceChangeRequested: function(val) { if (root.camera) root.camera.setWhiteBalance(val) }
            onGearClicked: settingsDrawer.open()
        }
    }

    // --- Floating record button ---
    RoundButton {
        id: recordButton

        readonly property bool isRecording: root.camera ? root.camera.recording : false

        width: Theme.recordButtonSize
        height: Theme.recordButtonSize
        radius: Theme.recordButtonSize / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.overlayVisible ? Theme.controlBarHeight + 12 : 16
        z: 3
        flat: true
        padding: 0

        Behavior on anchors.bottomMargin {
            SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
        }

        visible: root.camera ? root.camera.connected : false
        onClicked: { if (root.camera) root.camera.setRecording(!isRecording) }

        background: Rectangle {
            radius: recordButton.radius
            color: recordButton.isRecording ? Theme.recording : Theme.surfaceHover
            Behavior on color { ColorAnimation { duration: Theme.durationNormal } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2.5
                border.color: Theme.textPrimary
            }
        }

        contentItem: Item {
            Rectangle {
                anchors.centerIn: parent
                width: recordButton.isRecording ? 24 : 32
                height: recordButton.isRecording ? 24 : 32
                radius: recordButton.isRecording ? 4 : 16
                color: recordButton.isRecording ? Theme.textPrimary : Theme.recording

                Behavior on width { SpringAnimation { spring: 4; damping: 0.6 } }
                Behavior on height { SpringAnimation { spring: 4; damping: 0.6 } }
                Behavior on radius { SpringAnimation { spring: 4; damping: 0.6 } }
            }
        }

        scale: pressed ? Theme.pressScaleHeavy : 1.0
        Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }

        TapHandler {
            onLongPressed: recordOptionsPopup.open()
        }
    }

    // --- Long-press record options ---
    Popup {
        id: recordOptionsPopup
        x: (root.width - width) / 2
        y: recordButton.y - height - 12
        width: 200
        height: 180
        modal: true

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120; easing.type: Easing.InCubic }
            }
        }

        background: Rectangle { color: "#EE" + Theme.surface.toString().substring(1); radius: Theme.radiusMedium }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Text {
                text: "TIMED RECORDING"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontLabel
                font.letterSpacing: 1.5
            }

            Repeater {
                model: [
                    { label: "Record 10s", seconds: 10 },
                    { label: "Record 30s", seconds: 30 },
                    { label: "Record 60s", seconds: 60 }
                ]

                delegate: Button {
                    width: parent.width
                    height: 40
                    flat: true

                    background: Rectangle {
                        radius: Theme.radiusMedium
                        color: parent.pressed ? Theme.surfacePressed : Theme.surfaceHover
                        scale: parent.pressed ? Theme.pressScale : 1.0
                        Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }
                    }

                    contentItem: Text {
                        text: modelData.label
                        color: Theme.textPrimary
                        font.pixelSize: 15
                        font.family: Theme.fontBody
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        if (root.camera) root.camera.setRecording(true)
                        timedRecordTimer.interval = modelData.seconds * 1000
                        timedRecordTimer.start()
                        recordOptionsPopup.close()
                    }
                }
            }
        }
    }

    Timer {
        id: timedRecordTimer
        repeat: false
        onTriggered: { if (root.camera) root.camera.setRecording(false) }
    }

    // --- Settings drawer ---
    Drawer {
        id: settingsDrawer
        edge: Qt.RightEdge
        width: Math.min(320, root.width * 0.5)
        height: root.height

        background: Rectangle {
            color: Theme.surface
        }

        SettingsPanel {
            anchors.fill: parent

            fps: root.camera ? root.camera.fps : 30
            compression: root.camera ? root.camera.compression : 0
            cameraConnected: root.camera ? root.camera.connected : false
            cameraWidth: root.camera ? root.camera.width : 0
            cameraHeight: root.camera ? root.camera.height : 0

            zebraEnabled: root.config ? root.config.zebraEnabled : false
            zebraThreshold: root.config ? root.config.zebraThreshold : 0.95
            falseColorEnabled: root.config ? root.config.falseColorEnabled : false
            focusPeakingEnabled: root.config ? root.config.focusPeakingEnabled : false
            grayscaleEnabled: root.config ? root.config.grayscaleEnabled : false
            thirdsGridEnabled: root.config ? root.config.thirdsGridEnabled : false
            crosshairEnabled: root.config ? root.config.crosshairEnabled : false
            cinematicGuideEnabled: root.config ? root.config.cinematicGuideEnabled : false
            cinematicGuide185Enabled: root.config ? root.config.cinematicGuide185Enabled : false
            cinematicGuide43Enabled: root.config ? root.config.cinematicGuide43Enabled : false

            onFpsChangeRequested: function(val) { if (root.camera) root.camera.setFPS(val) }
            onCompressionChangeRequested: function(val) { if (root.camera) root.camera.setCompression(val) }
            onZebraEnabledToggled: function(val) { if (root.config) root.config.zebraEnabled = val }
            onZebraThresholdChangeRequested: function(val) { if (root.config) root.config.zebraThreshold = val }
            onFalseColorEnabledToggled: function(val) { if (root.config) root.config.falseColorEnabled = val }
            onFocusPeakingEnabledToggled: function(val) { if (root.config) root.config.focusPeakingEnabled = val }
            onGrayscaleEnabledToggled: function(val) { if (root.config) root.config.grayscaleEnabled = val }
            onThirdsGridEnabledToggled: function(val) { if (root.config) root.config.thirdsGridEnabled = val }
            onCrosshairEnabledToggled: function(val) { if (root.config) root.config.crosshairEnabled = val }
            onCinematicGuideEnabledToggled: function(val) { if (root.config) root.config.cinematicGuideEnabled = val }
            onCinematicGuide185EnabledToggled: function(val) { if (root.config) root.config.cinematicGuide185Enabled = val }
            onCinematicGuide43EnabledToggled: function(val) { if (root.config) root.config.cinematicGuide43Enabled = val }
            onCloseRequested: settingsDrawer.close()
        }
    }

    // --- Connection toast ---
    Rectangle {
        id: connectionToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.camera && root.camera.connected ? -height - 20 : 100
        width: connLabel.implicitWidth + 32
        height: 36
        radius: 18
        color: root.camera && root.camera.connected ? "#44" + Theme.success.toString().substring(1) : "#CC" + Theme.danger.toString().substring(1)
        visible: root.camera ? !root.camera.connected : false
        z: 10

        Behavior on anchors.bottomMargin {
            SpringAnimation { spring: 2.5; damping: 0.7 }
        }

        Text {
            id: connLabel
            anchors.centerIn: parent
            text: root.camera && root.camera.connected ? "Connected" : "Camera disconnected"
            color: Theme.textPrimary
            font.pixelSize: 13
            font.family: Theme.fontBody
            font.weight: Font.Medium
        }
    }
}
