import QtQuick

Item {
    id: root
    property var source: null

    property bool zebraEnabled: false
    property real zebraThreshold: 0.95
    property bool falseColorEnabled: false
    property bool focusPeakingEnabled: false
    property bool grayscaleEnabled: false

    // Animated time for zebra stripe movement (NumberAnimation offloads to animation thread)
    property real elapsedTime: 0.0
    NumberAnimation on elapsedTime {
        running: root.zebraEnabled && !root.falseColorEnabled
        from: 0; to: 3600
        duration: 3600000
        loops: Animation.Infinite
    }

    ShaderEffect {
        id: zebraEffect
        anchors.fill: parent
        visible: root.zebraEnabled && !root.falseColorEnabled
        property var source: root.source
        property real zebraThreshold: root.zebraThreshold
        property real time: root.elapsedTime
        fragmentShader: "qrc:/shaders/zebra.frag.qsb"
    }

    ShaderEffect {
        id: falseColorEffect
        anchors.fill: parent
        visible: root.falseColorEnabled
        property var source: root.source
        fragmentShader: "qrc:/shaders/falsecolor.frag.qsb"
    }

    ShaderEffect {
        id: focusPeakingEffect
        anchors.fill: parent
        visible: root.focusPeakingEnabled && !root.falseColorEnabled
        property var source: root.source
        property real texWidth: root.width > 0 ? root.width : 960.0
        property real texHeight: root.height > 0 ? root.height : 540.0
        property real threshold: 0.08
        fragmentShader: "qrc:/shaders/focuspeaking.frag.qsb"
    }

    ShaderEffect {
        id: grayscaleEffect
        anchors.fill: parent
        visible: root.grayscaleEnabled && !root.falseColorEnabled
        property var source: root.source
        fragmentShader: "qrc:/shaders/grayscale.frag.qsb"
    }
}
