import QtQuick 2.15

/**
 * GridOverlays - QML-drawn composition guides and grids.
 *
 * Includes:
 *  - Rule of thirds grid
 *  - Center crosshair
 *  - Cinematic aspect ratio guides (16:9, 1.85:1, 4:3)
 *
 * Controlled via ConfigManager properties.
 */
Item {
    id: root

    property color lineColor: "#88FFFFFF"
    property color guideColor: "#66FFFFFF"
    property real lineWidth: 1

    // Rule of thirds grid
    Canvas {
        id: thirdsGrid
        anchors.fill: parent
        visible: config.thirdsGridEnabled
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.strokeStyle = root.lineColor
            ctx.lineWidth = root.lineWidth

            // Vertical lines at 1/3 and 2/3
            var x1 = width / 3
            var x2 = 2 * width / 3
            ctx.beginPath()
            ctx.moveTo(x1, 0); ctx.lineTo(x1, height)
            ctx.moveTo(x2, 0); ctx.lineTo(x2, height)

            // Horizontal lines at 1/3 and 2/3
            var y1 = height / 3
            var y2 = 2 * height / 3
            ctx.moveTo(0, y1); ctx.lineTo(width, y1)
            ctx.moveTo(0, y2); ctx.lineTo(width, y2)
            ctx.stroke()
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
    }

    // Center crosshair
    Item {
        id: crosshair
        anchors.fill: parent
        visible: config.crosshairEnabled

        Rectangle {
            anchors.centerIn: parent
            width: 40
            height: root.lineWidth
            color: root.lineColor
        }
        Rectangle {
            anchors.centerIn: parent
            width: root.lineWidth
            height: 40
            color: root.lineColor
        }
        // Small center circle
        Rectangle {
            anchors.centerIn: parent
            width: 8
            height: 8
            radius: 4
            color: "transparent"
            border.color: root.lineColor
            border.width: root.lineWidth
        }
    }

    // 16:9 cinematic guide (letterbox on square display)
    Canvas {
        id: cinematicGuide169
        anchors.fill: parent
        visible: config.cinematicGuideEnabled
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // 16:9 aspect ratio bars
            var targetHeight = width * 9.0 / 16.0
            var barHeight = (height - targetHeight) / 2.0

            if (barHeight > 0) {
                ctx.fillStyle = "#AA000000"
                ctx.fillRect(0, 0, width, barHeight)
                ctx.fillRect(0, height - barHeight, width, barHeight)

                // Guide lines at the edge of the active area
                ctx.strokeStyle = root.guideColor
                ctx.lineWidth = root.lineWidth
                ctx.setLineDash([4, 4])
                ctx.beginPath()
                ctx.moveTo(0, barHeight); ctx.lineTo(width, barHeight)
                ctx.moveTo(0, height - barHeight); ctx.lineTo(width, height - barHeight)
                ctx.stroke()
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
    }

    // 1.85:1 cinematic guide
    Canvas {
        id: cinematicGuide185
        anchors.fill: parent
        visible: config.cinematicGuide185Enabled
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var targetHeight = width / 1.85
            var barHeight = (height - targetHeight) / 2.0

            if (barHeight > 0) {
                ctx.fillStyle = "#AA000000"
                ctx.fillRect(0, 0, width, barHeight)
                ctx.fillRect(0, height - barHeight, width, barHeight)

                ctx.strokeStyle = root.guideColor
                ctx.lineWidth = root.lineWidth
                ctx.setLineDash([4, 4])
                ctx.beginPath()
                ctx.moveTo(0, barHeight); ctx.lineTo(width, barHeight)
                ctx.moveTo(0, height - barHeight); ctx.lineTo(width, height - barHeight)
                ctx.stroke()
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
    }

    // 4:3 cinematic guide (pillarbox on widescreen, letterbox on square)
    Canvas {
        id: cinematicGuide43
        anchors.fill: parent
        visible: config.cinematicGuide43Enabled
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // On a square display (720x720), 4:3 is letterboxed
            var targetHeight = width * 3.0 / 4.0
            var barHeight = (height - targetHeight) / 2.0

            if (barHeight > 0) {
                // Letterbox (top/bottom bars)
                ctx.fillStyle = "#AA000000"
                ctx.fillRect(0, 0, width, barHeight)
                ctx.fillRect(0, height - barHeight, width, barHeight)

                ctx.strokeStyle = root.guideColor
                ctx.lineWidth = root.lineWidth
                ctx.setLineDash([4, 4])
                ctx.beginPath()
                ctx.moveTo(0, barHeight); ctx.lineTo(width, barHeight)
                ctx.moveTo(0, height - barHeight); ctx.lineTo(width, height - barHeight)
                ctx.stroke()
            } else {
                // Pillarbox (side bars) if wider than 4:3
                var targetWidth = height * 4.0 / 3.0
                var barWidth = (width - targetWidth) / 2.0
                if (barWidth > 0) {
                    ctx.fillStyle = "#AA000000"
                    ctx.fillRect(0, 0, barWidth, height)
                    ctx.fillRect(width - barWidth, 0, barWidth, height)

                    ctx.strokeStyle = root.guideColor
                    ctx.lineWidth = root.lineWidth
                    ctx.setLineDash([4, 4])
                    ctx.beginPath()
                    ctx.moveTo(barWidth, 0); ctx.lineTo(barWidth, height)
                    ctx.moveTo(width - barWidth, 0); ctx.lineTo(width - barWidth, height)
                    ctx.stroke()
                }
            }
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
    }
}
