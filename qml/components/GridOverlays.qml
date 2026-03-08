import QtQuick

Item {
    id: root

    property bool thirdsGridEnabled: false
    property bool crosshairEnabled: false
    property bool cinematicGuideEnabled: false
    property bool cinematicGuide185Enabled: false
    property bool cinematicGuide43Enabled: false

    property color lineColor: "#88FFFFFF"
    property color guideColor: "#66FFFFFF"
    property real lineWidth: 1

    // Rule of thirds grid (4 Rectangles instead of Canvas)
    Item {
        anchors.fill: parent
        visible: root.thirdsGridEnabled

        Rectangle {
            x: parent.width / 3; y: 0
            width: root.lineWidth; height: parent.height
            color: root.lineColor
        }
        Rectangle {
            x: 2 * parent.width / 3; y: 0
            width: root.lineWidth; height: parent.height
            color: root.lineColor
        }
        Rectangle {
            x: 0; y: parent.height / 3
            width: parent.width; height: root.lineWidth
            color: root.lineColor
        }
        Rectangle {
            x: 0; y: 2 * parent.height / 3
            width: parent.width; height: root.lineWidth
            color: root.lineColor
        }
    }

    // Center crosshair
    Item {
        anchors.fill: parent
        visible: root.crosshairEnabled

        Rectangle {
            anchors.centerIn: parent
            width: 40; height: root.lineWidth
            color: root.lineColor
        }
        Rectangle {
            anchors.centerIn: parent
            width: root.lineWidth; height: 40
            color: root.lineColor
        }
        Rectangle {
            anchors.centerIn: parent
            width: 8; height: 8; radius: 4
            color: "transparent"
            border.color: root.lineColor
            border.width: root.lineWidth
        }
    }

    // 16:9 cinematic guide (letterbox on square display)
    Item {
        anchors.fill: parent
        visible: root.cinematicGuideEnabled

        property real targetHeight: parent.width * 9.0 / 16.0
        property real barHeight: Math.max(0, (parent.height - targetHeight) / 2.0)

        Rectangle {
            width: parent.width; height: parent.barHeight
            color: "#AA000000"
        }
        Rectangle {
            y: parent.height - parent.barHeight
            width: parent.width; height: parent.barHeight
            color: "#AA000000"
        }
        Rectangle {
            y: parent.barHeight
            width: parent.width; height: root.lineWidth
            color: root.guideColor
            visible: parent.barHeight > 0
        }
        Rectangle {
            y: parent.height - parent.barHeight
            width: parent.width; height: root.lineWidth
            color: root.guideColor
            visible: parent.barHeight > 0
        }
    }

    // 1.85:1 cinematic guide
    Item {
        anchors.fill: parent
        visible: root.cinematicGuide185Enabled

        property real targetHeight: parent.width / 1.85
        property real barHeight: Math.max(0, (parent.height - targetHeight) / 2.0)

        Rectangle {
            width: parent.width; height: parent.barHeight
            color: "#AA000000"
        }
        Rectangle {
            y: parent.height - parent.barHeight
            width: parent.width; height: parent.barHeight
            color: "#AA000000"
        }
        Rectangle {
            y: parent.barHeight
            width: parent.width; height: root.lineWidth
            color: root.guideColor
            visible: parent.barHeight > 0
        }
        Rectangle {
            y: parent.height - parent.barHeight
            width: parent.width; height: root.lineWidth
            color: root.guideColor
            visible: parent.barHeight > 0
        }
    }

    // 4:3 cinematic guide
    Item {
        anchors.fill: parent
        visible: root.cinematicGuide43Enabled

        property real targetHeight: parent.width * 3.0 / 4.0
        property real barHeight: Math.max(0, (parent.height - targetHeight) / 2.0)
        property real targetWidth: parent.height * 4.0 / 3.0
        property real barWidth: Math.max(0, (parent.width - targetWidth) / 2.0)
        property bool isLetterbox: barHeight > 0

        // Letterbox bars (top/bottom)
        Rectangle {
            width: parent.width; height: parent.barHeight
            color: "#AA000000"
            visible: parent.isLetterbox
        }
        Rectangle {
            y: parent.height - parent.barHeight
            width: parent.width; height: parent.barHeight
            color: "#AA000000"
            visible: parent.isLetterbox
        }
        Rectangle {
            y: parent.barHeight
            width: parent.width; height: root.lineWidth
            color: root.guideColor
            visible: parent.isLetterbox && parent.barHeight > 0
        }
        Rectangle {
            y: parent.height - parent.barHeight
            width: parent.width; height: root.lineWidth
            color: root.guideColor
            visible: parent.isLetterbox && parent.barHeight > 0
        }

        // Pillarbox bars (left/right) when wider than 4:3
        Rectangle {
            width: parent.barWidth; height: parent.height
            color: "#AA000000"
            visible: !parent.isLetterbox && parent.barWidth > 0
        }
        Rectangle {
            x: parent.width - parent.barWidth
            width: parent.barWidth; height: parent.height
            color: "#AA000000"
            visible: !parent.isLetterbox && parent.barWidth > 0
        }
        Rectangle {
            x: parent.barWidth; y: 0
            width: root.lineWidth; height: parent.height
            color: root.guideColor
            visible: !parent.isLetterbox && parent.barWidth > 0
        }
        Rectangle {
            x: parent.width - parent.barWidth; y: 0
            width: root.lineWidth; height: parent.height
            color: root.guideColor
            visible: !parent.isLetterbox && parent.barWidth > 0
        }
    }
}
