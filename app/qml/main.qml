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
        z: 10
        source: viewfinderTexture
        zebraEnabled: mainScreen.monitorControl.zebraEnabled
        zebraThreshold: config.zebraThreshold
        falseColorEnabled: mainScreen.monitorControl.falseColorEnabled
        focusPeakingEnabled: mainScreen.monitorControl.focusPeakingEnabled
        grayscaleEnabled: mainScreen.monitorControl.grayscaleEnabled
    }

    ViewfinderGuides {
        parent: mainScreen.viewfinder
        anchors.fill: parent
        thirdsEnabled: mainScreen.guideControl.thirdsEnabled
        goldenEnabled: mainScreen.guideControl.goldenEnabled
        crosshairEnabled: mainScreen.guideControl.crosshairEnabled
        centerDotEnabled: mainScreen.guideControl.centerDotEnabled
    }

    SettingsView {
        id: settingsView
        anchors.fill: parent
        visible: false
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
    property bool _autoTransitioning: false

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

    function onManualValue(control, value, cameraMethod, configKey) {
        if (!_initDone || _autoTransitioning) return
        var val = Math.round(value)
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
            _autoTransitioning = true
            var actual = camera[cameraProp]
            var idx = findClosestIndex(control, actual > 0 ? actual : 0)
            Qt.callLater(function() {
                _autoTransitioning = false
                control.currentIndex = idx
            })
        }
    }

    Connections {
        target: mainScreen.isoControl
        function onManualValueChanged(value) {
            onManualValue(mainScreen.isoControl, value,
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
        function onManualValueChanged(value) {
            onManualValue(mainScreen.shutterControl, value,
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
        function onManualValueChanged(value) {
            onManualValue(mainScreen.wbControl, value,
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

    Connections {
        target: camera
        function onInitialized(iso, shutterAngle, fps, colorTemp) {
            mainScreen.isoControl.autoMode = (iso < 0)
            if (iso > 0) {
                var isoIdx = findClosestIndex(mainScreen.isoControl, iso)
                mainScreen.isoControl.currentIndex = isoIdx
            }

            mainScreen.shutterControl.autoMode = (shutterAngle < 0)
            if (shutterAngle > 0) {
                var saIdx = findClosestIndex(mainScreen.shutterControl, shutterAngle)
                mainScreen.shutterControl.currentIndex = saIdx
            }

            mainScreen.wbControl.autoMode = (colorTemp === 0)
            if (colorTemp > 0) {
                var wbIdx = findClosestIndex(mainScreen.wbControl, colorTemp)
                mainScreen.wbControl.currentIndex = wbIdx
            }

            _initDone = true
        }
        function onErrorChanged() {
            if (!_initDone)
                _initDone = true
        }
    }

    Binding {
        target: mainScreen.isoControl
        property: "autoDisplayValue"
        value: camera.isoSensitivity
    }

    Binding {
        target: mainScreen.shutterControl
        property: "autoDisplayValue"
        value: camera.shutterAngle
    }

    Binding {
        target: mainScreen.wbControl
        property: "autoDisplayValue"
        value: camera.colorTemperature
    }

    Connections {
        target: mainScreen.menuButton
        function onClicked() {
            mainScreen.state = ""
            mainScreen.visible = false
            settingsView.visible = true
            camera.stopCamera()
        }
    }

    Connections {
        target: settingsView
        function onClosed() {
            settingsView.visible = false
            mainScreen.visible = true
            camera.startCamera()
        }
        function onPowerOffRequested() {
            camera.powerOff()
        }
    }

    Component.onCompleted: {
        mainScreen.monitorControl.zebraEnabled = config.zebraEnabled
        mainScreen.monitorControl.focusPeakingEnabled = config.focusPeakingEnabled
        mainScreen.monitorControl.falseColorEnabled = config.falseColorEnabled
        mainScreen.monitorControl.grayscaleEnabled = config.grayscaleEnabled

        mainScreen.guideControl.thirdsEnabled = config.thirdsGridEnabled
        mainScreen.guideControl.goldenEnabled = config.goldenEnabled
        mainScreen.guideControl.crosshairEnabled = config.crosshairEnabled
        mainScreen.guideControl.centerDotEnabled = config.centerDotEnabled
    }
}
