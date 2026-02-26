import QtQuick
import CinePI 1.0

/**
 * CameraPreview - Displays the live camera feed via zero-copy DMA-BUF GPU rendering.
 *
 * Uses DmaBufPreview which imports the camera's ISP stream DMA-BUF directly
 * as a GPU texture — the GPU handles YUV→RGB conversion and scaling with
 * zero CPU cost. Falls back to MJPEG if DMA-BUF is not available.
 */
Item {
    id: root

    // Expose the preview for shader overlays
    property alias previewImage: dmaBufPreview

    // Frame counter for MJPEG fallback
    property int frameNum: 0

    // DMA-BUF zero-copy preview (primary — shared memory from cinepi-raw)
    DmaBufPreview {
        id: dmaBufPreview
        anchors.fill: parent
        visible: available
    }

    // MJPEG fallback preview (used when DMA-BUF is not available)
    Connections {
        target: frameProvider
        function onFrameUpdated() {
            root.frameNum++
        }
    }

    Image {
        id: mjpegPreview
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        cache: false
        smooth: false
        asynchronous: false
        visible: !dmaBufPreview.available
        source: visible ? "image://frames/latest?" + root.frameNum : ""
    }

    // "No Signal" placeholder
    Rectangle {
        anchors.fill: parent
        color: "#1A1A1A"
        visible: !dmaBufPreview.available && !mjpeg.connected

        Column {
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "NO SIGNAL"
                color: "#666666"
                font.pixelSize: 24
                font.bold: true
                font.family: "monospace"
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Waiting for camera stream..."
                color: "#444444"
                font.pixelSize: 12
                font.family: "monospace"
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 32
                height: 32
                radius: 16
                color: "transparent"
                border.color: "#444444"
                border.width: 2

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: "#666666"
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: -2
                }

                RotationAnimation on rotation {
                    from: 0; to: 360
                    duration: 1500
                    loops: Animation.Infinite
                    running: !dmaBufPreview.available && !mjpeg.connected
                }
            }
        }
    }
}
