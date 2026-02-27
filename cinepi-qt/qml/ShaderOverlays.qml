import QtQuick

/**
 * ShaderOverlays - GPU-accelerated image analysis overlays.
 *
 * Provides zebra (overexposure), false color, and focus peaking
 * as ShaderEffect items layered over the camera preview.
 *
 * Controlled via ConfigManager properties.
 */
Item {
    id: root
    property var source: null

    // Animated time for zebra stripe movement
    property real elapsedTime: 0.0
    Timer {
        interval: 33  // ~30fps update
        running: config.zebraEnabled
        repeat: true
        onTriggered: root.elapsedTime += 0.033
    }

    // Zebra pattern overlay (overexposure indicator)
    ShaderEffect {
        id: zebraEffect
        anchors.fill: parent
        visible: config.zebraEnabled && !config.falseColorEnabled
        property var source: root.source
        property real zebraThreshold: config.zebraThreshold
        property real time: root.elapsedTime
        fragmentShader: "qrc:/shaders/zebra.frag.qsb"

    }

    // False color overlay
    ShaderEffect {
        id: falseColorEffect
        anchors.fill: parent
        visible: config.falseColorEnabled
        property var source: root.source
        fragmentShader: "qrc:/shaders/falsecolor.frag.qsb"
    }

    // Focus peaking overlay
    ShaderEffect {
        id: focusPeakingEffect
        anchors.fill: parent
        visible: config.focusPeakingEnabled && !config.falseColorEnabled
        property var source: root.source
        property real texWidth: root.width > 0 ? root.width : 960.0
        property real texHeight: root.height > 0 ? root.height : 540.0
        property real threshold: 0.08
        fragmentShader: "qrc:/shaders/focuspeaking.frag.qsb"
    }

    // Grayscale effect (applied via simple desaturation shader)
    ShaderEffect {
        id: grayscaleEffect
        anchors.fill: parent
        visible: config.grayscaleEnabled && !config.falseColorEnabled
        property var source: root.source
        fragmentShader: "qrc:/shaders/grayscale.frag.qsb"
    }
}
