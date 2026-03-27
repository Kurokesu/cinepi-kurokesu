import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Window
import CinePiUi
import CinePiUiContent
import CinePI 1.0

ApplicationWindow {
    id: appWindow
    visible: true
    width: Constants.width
    height: Constants.height
    visibility: Window.FullScreen
    flags: Qt.FramelessWindowHint
    title: "CinePI"
    font.family: Constants.fontFamily

    Main {
        id: mainScreen
        anchors.centerIn: parent

        viewfinderArea.onClicked: mainScreen.state = ""
    }

    DmaBufViewfinder {
        id: viewfinderFeed
        parent: mainScreen.viewfinder
        anchors.fill: parent
        visible: available
    }

    ShaderEffectSource {
        id: viewfinderTexture
        sourceItem: viewfinderFeed
        live: true
        hideSource: false
    }

    ShaderOverlays {
        parent: mainScreen.viewfinder
        anchors.fill: parent
        source: viewfinderTexture
        zebraEnabled: mainScreen.monitorControl.zebraEnabled
        zebraThreshold: config.zebraThreshold
        falseColorEnabled: mainScreen.monitorControl.falseColorEnabled
        focusPeakingEnabled: mainScreen.monitorControl.focusPeakingEnabled
        grayscaleEnabled: mainScreen.monitorControl.grayscaleEnabled
    }

    Connections {
        target: mainScreen.recordButton
        function onCheckedChanged() {
            if (mainScreen.recordButton.checked
                    && (mainScreen.state === "formatOpen"
                        || mainScreen.state === "aspectOpen"
                        || mainScreen.state === "guideOpen"
                        || mainScreen.state === "monitorOpen"))
                mainScreen.state = ""

            camera.setRecording(mainScreen.recordButton.checked)
        }
    }

    ButtonGroup {
        exclusive: false
        buttons: [mainScreen.formatButton, mainScreen.aspectButton,
                  mainScreen.guideButton, mainScreen.monitorButton,
                  mainScreen.isoButton, mainScreen.shutterButton,
                  mainScreen.wbButton]
        onClicked: button => mainScreen.state = mainScreen.state
                   === button.objectName ? "" : button.objectName
    }

    property bool _initDone: false

    function findClosestIndex(control, target) {
        var vals = control.effectiveValues
        var bestIdx = 0
        var bestDiff = Math.abs(vals[0] - target)
        for (var i = 1; i < vals.length; i++) {
            var diff = Math.abs(vals[i] - target)
            if (diff < bestDiff) {
                bestDiff = diff
                bestIdx = i
            }
        }
        return bestIdx
    }

    function onManualValue(control, cameraMethod, configKey) {
        if (!_initDone || control.autoMode) return
        var val = Math.round(parseFloat(control.currentValue))
        if (val > 0) {
            camera[cameraMethod](val)
            config[configKey] = val
        }
    }

    function onAutoToggle(control, sentinel, cameraMethod, cameraProp, configKey) {
        if (!_initDone) return
        if (control.autoMode) {
            camera[cameraMethod](sentinel)
            config[configKey] = sentinel
        } else {
            var actual = camera[cameraProp]
            if (actual > 0) {
                config[configKey] = actual
                camera[cameraMethod](actual)
            }
        }
    }

    Connections {
        target: mainScreen.isoControl
        function onCurrentIndexChanged() {
            onManualValue(mainScreen.isoControl,
                          "setIsoSensitivity", "manualIsoSensitivity")
        }
        function onAutoModeChanged() {
            onAutoToggle(mainScreen.isoControl, -1,
                         "setIsoSensitivity", "isoSensitivity",
                         "manualIsoSensitivity")
        }
    }

    Connections {
        target: mainScreen.shutterControl
        function onCurrentIndexChanged() {
            onManualValue(mainScreen.shutterControl,
                          "setShutterAngle", "manualShutterAngle")
        }
        function onAutoModeChanged() {
            onAutoToggle(mainScreen.shutterControl, -1,
                         "setShutterAngle", "shutterAngle",
                         "manualShutterAngle")
        }
    }

    Connections {
        target: mainScreen.wbControl
        function onCurrentIndexChanged() {
            onManualValue(mainScreen.wbControl,
                          "setColorTemperature", "colorTemperature")
        }
        function onAutoModeChanged() {
            onAutoToggle(mainScreen.wbControl, 0,
                         "setColorTemperature", "colorTemperature",
                         "colorTemperature")
        }
    }

    Connections {
        target: mainScreen.monitorControl
        function onZebraEnabledChanged() {
            config.zebraEnabled = mainScreen.monitorControl.zebraEnabled
        }
        function onFocusPeakingEnabledChanged() {
            config.focusPeakingEnabled = mainScreen.monitorControl.focusPeakingEnabled
        }
        function onFalseColorEnabledChanged() {
            config.falseColorEnabled = mainScreen.monitorControl.falseColorEnabled
        }
        function onGrayscaleEnabledChanged() {
            config.grayscaleEnabled = mainScreen.monitorControl.grayscaleEnabled
        }
    }

    Connections {
        target: mainScreen.guideControl
        function onThirdsEnabledChanged() {
            config.thirdsGridEnabled = mainScreen.guideControl.thirdsEnabled
        }
        function onGoldenEnabledChanged() {
            config.goldenEnabled = mainScreen.guideControl.goldenEnabled
        }
        function onCrosshairEnabledChanged() {
            config.crosshairEnabled = mainScreen.guideControl.crosshairEnabled
        }
        function onCenterDotEnabledChanged() {
            config.centerDotEnabled = mainScreen.guideControl.centerDotEnabled
        }
    }

    Component.onCompleted: {
        // Monitor overlays
        mainScreen.monitorControl.zebraEnabled = config.zebraEnabled
        mainScreen.monitorControl.focusPeakingEnabled = config.focusPeakingEnabled
        mainScreen.monitorControl.falseColorEnabled = config.falseColorEnabled
        mainScreen.monitorControl.grayscaleEnabled = config.grayscaleEnabled

        // Guide overlays
        mainScreen.guideControl.thirdsEnabled = config.thirdsGridEnabled
        mainScreen.guideControl.goldenEnabled = config.goldenEnabled
        mainScreen.guideControl.crosshairEnabled = config.crosshairEnabled
        mainScreen.guideControl.centerDotEnabled = config.centerDotEnabled

        // Camera ISO
        mainScreen.isoControl.autoMode = (config.manualIsoSensitivity < 0)
        if (config.manualIsoSensitivity > 0)
            mainScreen.isoControl.currentIndex =
                findClosestIndex(mainScreen.isoControl, config.manualIsoSensitivity)

        // Camera shutter
        mainScreen.shutterControl.autoMode = (config.manualShutterAngle < 0)
        if (config.manualShutterAngle > 0)
            mainScreen.shutterControl.currentIndex =
                findClosestIndex(mainScreen.shutterControl, config.manualShutterAngle)

        // Camera white balance
        mainScreen.wbControl.autoMode = (config.colorTemperature === 0)
        if (config.colorTemperature > 0)
            mainScreen.wbControl.currentIndex =
                findClosestIndex(mainScreen.wbControl, config.colorTemperature)

        _initDone = true
    }
}
