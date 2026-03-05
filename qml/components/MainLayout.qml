import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    default property alias previewContent: previewContainer.data

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
            color: Theme.barOverlay
            opacity: zoomIndicatorVisible ? 1.0 : 0.0
            visible: opacity > 0

            property bool zoomIndicatorVisible: previewContainer.zoomScale > 1.01

            Behavior on opacity {
                NumberAnimation { duration: Theme.durationNormal }
            }

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
        }

        // --- Recording border pulse ---
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Theme.recording
            border.width: camera.recording ? 2 : 0
            z: 1

            SequentialAnimation on opacity {
                running: camera.recording
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }

            Component.onCompleted: opacity = 1.0
        }

        // --- Double-tap to toggle overlay ---
        TapHandler {
            onDoubleTapped: root.overlayVisible = !root.overlayVisible
        }

        // --- StatusBar (slides up when hidden) ---
        StatusBar {
            id: statusBar
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.overlayVisible ? 0 : -height
            height: Theme.statusBarHeight
            z: 2

            Behavior on y {
                SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
            }
        }

        // --- Recording info pill (below StatusBar, only during recording) ---
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: statusBar.bottom
            anchors.topMargin: 8
            width: recInfoRow.implicitWidth + 24
            height: 28
            radius: 14
            color: Theme.barOverlay
            opacity: camera.recording ? 1.0 : 0.0
            visible: opacity > 0
            z: 2

            Behavior on opacity {
                NumberAnimation { duration: Theme.durationNormal }
            }

            Row {
                id: recInfoRow
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: Theme.recording
                    anchors.verticalCenter: parent.verticalCenter

                    SequentialAnimation on opacity {
                        running: camera.recording
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
                    text: camera.frameCount > 0 ? camera.frameCount + " frames" : ""
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.family: Theme.fontValue
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                }
            }
        }

        // --- CameraControls (slides down when hidden) ---
        CameraControls {
            id: cameraControls
            anchors.left: parent.left
            anchors.right: parent.right
            y: root.overlayVisible ? (parent.height - height) : parent.height
            height: Theme.controlBarHeight
            z: 2

            Behavior on y {
                SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
            }

            onGearClicked: settingsDrawer.open()
        }
    }

    // --- Floating record button (always visible for safety) ---
    Rectangle {
        id: recordButton
        width: Theme.recordButtonSize
        height: Theme.recordButtonSize
        radius: Theme.recordButtonSize / 2
        color: camera.recording ? Theme.recording : Theme.surfaceHover
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.overlayVisible
            ? parent.height - Theme.controlBarHeight - Theme.recordButtonSize - 12
            : parent.height - Theme.recordButtonSize - 16
        z: 3

        Behavior on y {
            SpringAnimation { spring: Theme.springRate; damping: Theme.springDamping }
        }
        visible: camera.connected
        opacity: camera.connected ? 1.0 : 0.0
        scale: recordMouse.pressed ? Theme.pressScaleHeavy : 1.0

        Behavior on scale {
            SpringAnimation { spring: 4; damping: 0.6 }
        }
        Behavior on color {
            ColorAnimation { duration: Theme.durationNormal }
        }

        // White outer ring
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.width: 2.5
            border.color: Theme.textPrimary
        }

        // Inner dot / stop square
        Rectangle {
            anchors.centerIn: parent
            width: camera.recording ? 24 : 40
            height: camera.recording ? 24 : 40
            radius: camera.recording ? 4 : 20
            color: camera.recording ? Theme.textPrimary : Theme.recording

            Behavior on width { SpringAnimation { spring: 4; damping: 0.6 } }
            Behavior on height { SpringAnimation { spring: 4; damping: 0.6 } }
            Behavior on radius { SpringAnimation { spring: 4; damping: 0.6 } }
        }

        MouseArea {
            id: recordMouse
            anchors.fill: parent
            anchors.margins: -12
            onClicked: camera.setRecording(!camera.recording)
        }

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

                delegate: Rectangle {
                    width: parent.width
                    height: 40
                    radius: Theme.radiusMedium
                    color: timedMouse.pressed ? Theme.surfacePressed : Theme.surfaceHover
                    scale: timedMouse.pressed ? Theme.pressScale : 1.0

                    Behavior on scale {
                        SpringAnimation { spring: 4; damping: 0.6 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: Theme.textPrimary
                        font.pixelSize: 15
                        font.family: Theme.fontBody
                    }

                    MouseArea {
                        id: timedMouse
                        anchors.fill: parent
                        onClicked: {
                            camera.setRecording(true)
                            timedRecordTimer.interval = modelData.seconds * 1000
                            timedRecordTimer.start()
                            recordOptionsPopup.close()
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: timedRecordTimer
        repeat: false
        onTriggered: camera.setRecording(false)
    }

    // --- Settings drawer (swipe from right edge) ---
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
            onCloseRequested: settingsDrawer.close()
        }
    }

    // --- Connection toast (slide-up animation) ---
    Rectangle {
        id: connectionToast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: camera.connected ? -height - 20 : 100
        width: connLabel.implicitWidth + 32
        height: 36
        radius: 18
        color: camera.connected ? "#44" + Theme.success.toString().substring(1) : "#CC" + Theme.danger.toString().substring(1)
        opacity: camera.connected ? 0.0 : 1.0
        visible: opacity > 0 || !camera.connected
        z: 10

        Behavior on anchors.bottomMargin {
            SpringAnimation { spring: 2.5; damping: 0.7 }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.durationNormal }
        }

        Text {
            id: connLabel
            anchors.centerIn: parent
            text: camera.connected ? "Connected" : "Camera disconnected"
            color: Theme.textPrimary
            font.pixelSize: 13
            font.family: Theme.fontBody
            font.weight: Font.Medium
        }
    }
}
