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

    // ── Live camera preview ─────────────────────────────────────────────────

    DmaBufPreview {
        id: cameraPreview
        parent: mainScreen.viewfinder
        anchors.fill: parent
        visible: available
    }

    ShaderEffectSource {
        id: previewTexture
        sourceItem: cameraPreview
        live: true
        hideSource: false
    }

    ShaderOverlays {
        parent: mainScreen.viewfinder
        anchors.fill: parent
        source: previewTexture
        zebraEnabled: mainScreen.monitorControl.zebraEnabled
        zebraThreshold: config.zebraThreshold
        falseColorEnabled: mainScreen.monitorControl.falseColorEnabled
        focusPeakingEnabled: mainScreen.monitorControl.peakingEnabled
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

    // ── Camera control wiring ───────────────────────────────────────────────

    Connections {
        target: mainScreen
        function onIsoValueChanged() {
            if (!mainScreen.isoControl.autoMode && mainScreen.isoValue > 0)
                camera.setISO(mainScreen.isoValue)
        }
    }

    Connections {
        target: mainScreen.shutterControl
        function onCurrentIndexChanged() {
            if (!mainScreen.shutterControl.autoMode) {
                var angle = Math.round(
                    parseFloat(mainScreen.shutterControl.currentValue))
                if (angle > 0)
                    camera.setShutterAngle(angle)
            }
        }
    }

    // WB: the UI uses Kelvin (2300-10000) but the backend currently uses AWB
    // mode indices. A conversion layer in CameraController is needed before
    // this can be properly wired. For now, keep the WB picker functional in
    // the UI but don't send values to the backend.

    // ── Monitor sheet <-> config persistence ────────────────────────────────

    Connections {
        target: mainScreen.monitorControl
        function onZebraEnabledChanged() {
            config.zebraEnabled = mainScreen.monitorControl.zebraEnabled
        }
        function onPeakingEnabledChanged() {
            config.focusPeakingEnabled = mainScreen.monitorControl.peakingEnabled
        }
        function onFalseColorEnabledChanged() {
            config.falseColorEnabled = mainScreen.monitorControl.falseColorEnabled
        }
        function onGrayscaleEnabledChanged() {
            config.grayscaleEnabled = mainScreen.monitorControl.grayscaleEnabled
        }
    }

    // ── Guide sheet <-> config persistence ──────────────────────────────────

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

    // ── Initial sync from persisted config ──────────────────────────────────

    Component.onCompleted: {
        mainScreen.monitorControl.zebraEnabled = config.zebraEnabled
        mainScreen.monitorControl.peakingEnabled = config.focusPeakingEnabled
        mainScreen.monitorControl.falseColorEnabled = config.falseColorEnabled
        mainScreen.monitorControl.grayscaleEnabled = config.grayscaleEnabled

        mainScreen.guideControl.thirdsEnabled = config.thirdsGridEnabled
        mainScreen.guideControl.goldenEnabled = config.goldenEnabled
        mainScreen.guideControl.crosshairEnabled = config.crosshairEnabled
        mainScreen.guideControl.centerDotEnabled = config.centerDotEnabled
    }
}
