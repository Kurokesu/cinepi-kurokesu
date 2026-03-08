import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.surface

    // Camera state
    property int fps: 30
    property int compression: 0
    property bool cameraConnected: true
    property int cameraWidth: 1920
    property int cameraHeight: 1080

    // Config state
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

    // Signals
    signal fpsChangeRequested(int val)
    signal compressionChangeRequested(int val)
    signal zebraEnabledToggled(bool val)
    signal zebraThresholdChangeRequested(real val)
    signal falseColorEnabledToggled(bool val)
    signal focusPeakingEnabledToggled(bool val)
    signal grayscaleEnabledToggled(bool val)
    signal thirdsGridEnabledToggled(bool val)
    signal crosshairEnabledToggled(bool val)
    signal cinematicGuideEnabledToggled(bool val)
    signal cinematicGuide185EnabledToggled(bool val)
    signal cinematicGuide43EnabledToggled(bool val)
    signal closeRequested()

    Flickable {
        anchors.fill: parent
        contentHeight: settingsColumn.height + 32
        clip: true
        pressDelay: 80

        Column {
            id: settingsColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 8

            RowLayout {
                width: parent.width
                height: 56

                Text {
                    text: "SETTINGS"
                    color: Theme.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    font.family: Theme.fontLabel
                    font.letterSpacing: 1.5
                    Layout.fillWidth: true
                }

                RoundButton {
                    width: 40; height: 40
                    radius: 20
                    flat: true

                    background: Rectangle {
                        radius: 20
                        color: parent.pressed ? Theme.surfacePressed : Theme.surfaceHover
                        scale: parent.pressed ? Theme.pressScale : 1.0
                        Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }
                    }

                    contentItem: Text {
                        text: "\u2715"
                        color: Theme.textSecondary
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: root.closeRequested()
                }
            }

            SectionHeader { text: "IMAGE ANALYSIS" }

            SettingToggle {
                label: "Zebra (Overexposure)"
                checked: root.zebraEnabled
                onToggled: function(val) { root.zebraEnabledToggled(val) }
            }

            Item { width: 1; height: 4; visible: root.zebraEnabled }

            RowLayout {
                width: parent.width
                visible: root.zebraEnabled
                spacing: 8

                Text {
                    text: "Threshold"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.family: Theme.fontBody
                    Layout.preferredWidth: 70
                }

                Slider {
                    id: zebraSlider
                    Layout.fillWidth: true
                    from: 0.5; to: 1.0; stepSize: 0.01
                    value: root.zebraThreshold
                    onMoved: root.zebraThresholdChangeRequested(value)

                    background: Rectangle {
                        x: zebraSlider.leftPadding
                        y: zebraSlider.topPadding + zebraSlider.availableHeight / 2 - height / 2
                        width: zebraSlider.availableWidth; height: 4; radius: 2
                        color: Theme.surfacePressed
                        Rectangle {
                            width: zebraSlider.visualPosition * parent.width; height: parent.height
                            color: Theme.accent; radius: 2
                        }
                    }
                    handle: Rectangle {
                        x: zebraSlider.leftPadding + zebraSlider.visualPosition * (zebraSlider.availableWidth - width)
                        y: zebraSlider.topPadding + zebraSlider.availableHeight / 2 - height / 2
                        implicitWidth: 28; implicitHeight: 28
                        width: 22; height: 22; radius: 11; color: Theme.textPrimary
                    }
                }

                Text {
                    text: Math.round(root.zebraThreshold * 100) + "%"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.family: Theme.fontValue
                    Layout.preferredWidth: 36
                }
            }

            Item { width: 1; height: 4; visible: root.zebraEnabled }

            SettingToggle {
                label: "False Color"
                checked: root.falseColorEnabled
                onToggled: function(val) { root.falseColorEnabledToggled(val) }
            }

            SettingToggle {
                label: "Focus Peaking"
                checked: root.focusPeakingEnabled
                onToggled: function(val) { root.focusPeakingEnabledToggled(val) }
            }

            SettingToggle {
                label: "Grayscale"
                checked: root.grayscaleEnabled
                onToggled: function(val) { root.grayscaleEnabledToggled(val) }
            }

            SectionHeader { text: "COMPOSITION GUIDES" }

            SettingToggle {
                label: "Rule of Thirds"
                checked: root.thirdsGridEnabled
                onToggled: function(val) { root.thirdsGridEnabledToggled(val) }
            }

            SettingToggle {
                label: "Center Crosshair"
                checked: root.crosshairEnabled
                onToggled: function(val) { root.crosshairEnabledToggled(val) }
            }

            SettingToggle {
                label: "16:9 Guide"
                checked: root.cinematicGuideEnabled
                onToggled: function(val) { root.cinematicGuideEnabledToggled(val) }
            }

            SettingToggle {
                label: "1.85:1 Guide"
                checked: root.cinematicGuide185Enabled
                onToggled: function(val) { root.cinematicGuide185EnabledToggled(val) }
            }

            SettingToggle {
                label: "4:3 Guide"
                checked: root.cinematicGuide43Enabled
                onToggled: function(val) { root.cinematicGuide43EnabledToggled(val) }
            }

            SectionHeader { text: "CAMERA" }

            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Frame Rate"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    font.family: Theme.fontBody
                }

                Flickable {
                    width: parent.width
                    height: 40
                    contentWidth: fpsRow.implicitWidth
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: fpsRow
                        spacing: 6

                        Repeater {
                            model: CameraPresets.fpsOptions
                            delegate: Button {
                                width: 56; height: 40
                                checkable: true
                                checked: root.fps === modelData
                                flat: true

                                background: Rectangle {
                                    radius: 20
                                    color: parent.checked ? Theme.accent : Theme.surfaceHover
                                    scale: parent.pressed ? Theme.pressScale : 1.0
                                    Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }
                                }

                                contentItem: Text {
                                    text: modelData.toString()
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                    font.family: Theme.fontValue
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: root.fpsChangeRequested(modelData)
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 8

                Text {
                    text: "Compression"
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    font.family: Theme.fontBody
                }

                Flickable {
                    width: parent.width
                    height: 40
                    contentWidth: compRow.implicitWidth
                    clip: true
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: compRow
                        spacing: 6

                        Repeater {
                            model: CameraPresets.compressionOptions.length
                            delegate: Button {
                                width: compText.implicitWidth + 32; height: 40
                                checkable: true
                                checked: root.compression === CameraPresets.compressionOptions[index].value
                                flat: true

                                background: Rectangle {
                                    radius: 20
                                    color: parent.checked ? Theme.accent : Theme.surfaceHover
                                    scale: parent.pressed ? Theme.pressScale : 1.0
                                    Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }
                                }

                                contentItem: Text {
                                    id: compText
                                    text: CameraPresets.compressionOptions[index].label
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    font.family: Theme.fontBody
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: root.compressionChangeRequested(CameraPresets.compressionOptions[index].value)
                            }
                        }
                    }
                }
            }

            SectionHeader { text: "SYSTEM" }

            Text {
                text: "Camera: " + (root.cameraConnected ? "Connected" : "Disconnected")
                color: root.cameraConnected ? Theme.success : Theme.danger
                font.pixelSize: 13
                font.family: Theme.fontBody
            }

            Text {
                text: "Resolution: " + (root.cameraWidth > 0 ? root.cameraWidth + "x" + root.cameraHeight : "N/A")
                color: Theme.textSecondary
                font.pixelSize: 13
                font.family: Theme.fontBody
            }

            Item { width: 1; height: 16 }

            Button {
                width: parent.width
                height: 52
                flat: true

                background: Rectangle {
                    radius: Theme.radiusMedium
                    color: parent.pressed ? "#CC2222" : "#882222"
                    scale: parent.pressed ? Theme.pressScale : 1.0
                    Behavior on scale { SpringAnimation { spring: 4; damping: 0.6 } }
                }

                contentItem: Text {
                    text: "EXIT APPLICATION"
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    font.family: Theme.fontLabel
                    font.letterSpacing: 1.5
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: Qt.quit()
            }

            Item { width: 1; height: 32 }
        }
    }
}
