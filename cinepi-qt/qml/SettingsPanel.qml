import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

/**
 * SettingsPanel - Slide-in panel for overlay and camera settings.
 *
 * Sections:
 *  - Image Analysis (zebra, false color, focus peaking, grayscale)
 *  - Composition Guides (thirds grid, crosshair, cinematic guides)
 *  - Camera Settings (compression, color gains)
 */
Rectangle {
    id: root
    color: "#EE1A1A1A"
    signal closeRequested()

    Flickable {
        anchors.fill: parent
        contentHeight: settingsColumn.height + 32
        clip: true

        Column {
            id: settingsColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 8

            // Header
            RowLayout {
                width: parent.width
                height: 48

                Text {
                    text: "SETTINGS"
                    color: "#FFFFFF"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "monospace"
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: closeMouse.pressed ? "#444444" : "#333333"
                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: "#AAAAAA"
                        font.pixelSize: 16
                    }
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        onClicked: root.closeRequested()
                    }
                }
            }

            SectionHeader { text: "IMAGE ANALYSIS" }

            SettingToggle {
                label: "Zebra (Overexposure)"
                checked: config.zebraEnabled
                onToggled: config.zebraEnabled = checked
            }

            // Zebra threshold slider
            RowLayout {
                width: parent.width
                visible: config.zebraEnabled
                spacing: 8

                Text {
                    text: "Threshold"
                    color: "#888888"
                    font.pixelSize: 11
                    Layout.preferredWidth: 70
                }

                Slider {
                    id: zebraSlider
                    Layout.fillWidth: true
                    from: 0.7; to: 1.0; stepSize: 0.01
                    value: config.zebraThreshold
                    onMoved: config.zebraThreshold = value

                    background: Rectangle {
                        x: zebraSlider.leftPadding
                        y: zebraSlider.topPadding + zebraSlider.availableHeight / 2 - height / 2
                        width: zebraSlider.availableWidth; height: 4; radius: 2
                        color: "#444444"
                        Rectangle {
                            width: zebraSlider.visualPosition * parent.width; height: parent.height
                            color: "#0078D7"; radius: 2
                        }
                    }
                    handle: Rectangle {
                        x: zebraSlider.leftPadding + zebraSlider.visualPosition * (zebraSlider.availableWidth - width)
                        y: zebraSlider.topPadding + zebraSlider.availableHeight / 2 - height / 2
                        width: 18; height: 18; radius: 9; color: "#FFFFFF"
                    }
                }

                Text {
                    text: (config.zebraThreshold * 100).toFixed(0) + "%"
                    color: "#AAAAAA"
                    font.pixelSize: 11
                    font.family: "monospace"
                    Layout.preferredWidth: 36
                }
            }

            SettingToggle {
                label: "False Color"
                checked: config.falseColorEnabled
                onToggled: config.falseColorEnabled = checked
            }

            SettingToggle {
                label: "Focus Peaking"
                checked: config.focusPeakingEnabled
                onToggled: config.focusPeakingEnabled = checked
            }

            SettingToggle {
                label: "Grayscale"
                checked: config.grayscaleEnabled
                onToggled: config.grayscaleEnabled = checked
            }

            SectionHeader { text: "COMPOSITION GUIDES" }

            SettingToggle {
                label: "Rule of Thirds"
                checked: config.thirdsGridEnabled
                onToggled: config.thirdsGridEnabled = checked
            }

            SettingToggle {
                label: "Center Crosshair"
                checked: config.crosshairEnabled
                onToggled: config.crosshairEnabled = checked
            }

            SettingToggle {
                label: "16:9 Guide"
                checked: config.cinematicGuideEnabled
                onToggled: config.cinematicGuideEnabled = checked
            }

            SettingToggle {
                label: "1.85:1 Guide"
                checked: config.cinematicGuide185Enabled
                onToggled: config.cinematicGuide185Enabled = checked
            }

            SettingToggle {
                label: "4:3 Guide"
                checked: config.cinematicGuide43Enabled
                onToggled: config.cinematicGuide43Enabled = checked
            }

            SectionHeader { text: "CAMERA" }

            // Compression mode
            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: "Compression"
                    color: "#CCCCCC"
                    font.pixelSize: 12
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 4
                    Repeater {
                        model: [
                            { label: "None", val: 0 },
                            { label: "Lossy", val: 1 },
                            { label: "Lossless", val: 2 }
                        ]
                        delegate: Rectangle {
                            width: 64; height: 28; radius: 4
                            color: redis.compression === modelData.val ? "#0078D7" : "#444444"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: "#FFFFFF"
                                font.pixelSize: 10
                                font.family: "monospace"
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: redis.setCompression(modelData.val)
                            }
                        }
                    }
                }
            }

            // Color gains
            Text {
                text: "Color Gains"
                color: "#CCCCCC"
                font.pixelSize: 12
                topPadding: 4
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Text { text: "R"; color: "#FF6666"; font.pixelSize: 11; Layout.preferredWidth: 16 }
                Slider {
                    id: cgRedSlider
                    Layout.fillWidth: true
                    from: 0.1; to: 4.0; stepSize: 0.01
                    value: redis.colorGainR
                    onMoved: redis.setColorGains(value, redis.colorGainB)
                    background: Rectangle {
                        x: cgRedSlider.leftPadding
                        y: cgRedSlider.topPadding + cgRedSlider.availableHeight / 2 - height / 2
                        width: cgRedSlider.availableWidth; height: 4; radius: 2; color: "#444444"
                        Rectangle { width: cgRedSlider.visualPosition * parent.width; height: parent.height; color: "#FF4444"; radius: 2 }
                    }
                    handle: Rectangle {
                        x: cgRedSlider.leftPadding + cgRedSlider.visualPosition * (cgRedSlider.availableWidth - width)
                        y: cgRedSlider.topPadding + cgRedSlider.availableHeight / 2 - height / 2
                        width: 16; height: 16; radius: 8; color: "#FFFFFF"
                    }
                }
                Text { text: redis.colorGainR.toFixed(2); color: "#AAAAAA"; font.pixelSize: 10; font.family: "monospace"; Layout.preferredWidth: 32 }
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Text { text: "B"; color: "#6666FF"; font.pixelSize: 11; Layout.preferredWidth: 16 }
                Slider {
                    id: cgBlueSlider
                    Layout.fillWidth: true
                    from: 0.1; to: 4.0; stepSize: 0.01
                    value: redis.colorGainB
                    onMoved: redis.setColorGains(redis.colorGainR, value)
                    background: Rectangle {
                        x: cgBlueSlider.leftPadding
                        y: cgBlueSlider.topPadding + cgBlueSlider.availableHeight / 2 - height / 2
                        width: cgBlueSlider.availableWidth; height: 4; radius: 2; color: "#444444"
                        Rectangle { width: cgBlueSlider.visualPosition * parent.width; height: parent.height; color: "#4444FF"; radius: 2 }
                    }
                    handle: Rectangle {
                        x: cgBlueSlider.leftPadding + cgBlueSlider.visualPosition * (cgBlueSlider.availableWidth - width)
                        y: cgBlueSlider.topPadding + cgBlueSlider.availableHeight / 2 - height / 2
                        width: 16; height: 16; radius: 8; color: "#FFFFFF"
                    }
                }
                Text { text: redis.colorGainB.toFixed(2); color: "#AAAAAA"; font.pixelSize: 10; font.family: "monospace"; Layout.preferredWidth: 32 }
            }

            // System info
            SectionHeader { text: "SYSTEM" }

            Text {
                text: "Stream: " + (mjpeg.connected ? "Connected" : "Disconnected")
                color: mjpeg.connected ? "#00CC00" : "#CC0000"
                font.pixelSize: 11
                font.family: "monospace"
            }

            Text {
                text: "Redis: " + (redis.connected ? "Connected" : "Disconnected")
                color: redis.connected ? "#00CC00" : "#CC0000"
                font.pixelSize: 11
                font.family: "monospace"
            }

            Text {
                text: "Resolution: " + (redis.width > 0 ? redis.width + "x" + redis.height : "N/A")
                color: "#AAAAAA"
                font.pixelSize: 11
                font.family: "monospace"
            }

            Text {
                text: "Frames: " + mjpeg.frameCount
                color: "#AAAAAA"
                font.pixelSize: 11
                font.family: "monospace"
            }

            // Spacer at bottom
            Item { width: 1; height: 32 }
        }
    }

    /** Section header */
    component SectionHeader: Item {
        property string text: ""
        width: parent.width
        height: 32

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#333333"
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.text
            color: "#666666"
            font.pixelSize: 10
            font.bold: true
            font.family: "monospace"
            font.letterSpacing: 2
        }
    }

    /** Toggle switch row */
    component SettingToggle: RowLayout {
        property string label: ""
        property bool checked: false
        signal toggled(bool checked)

        width: parent.width
        spacing: 8

        Text {
            text: label
            color: "#CCCCCC"
            font.pixelSize: 12
            Layout.fillWidth: true
        }

        Switch {
            checked: parent.checked
            onToggled: parent.toggled(checked)

            indicator: Rectangle {
                width: 40; height: 22; radius: 11
                color: parent.checked ? "#0078D7" : "#444444"
                x: parent.leftPadding
                y: parent.height / 2 - height / 2

                Rectangle {
                    x: parent.parent.checked ? parent.width - width - 3 : 3
                    y: 3
                    width: 16; height: 16; radius: 8
                    color: "#FFFFFF"
                    Behavior on x { NumberAnimation { duration: 120 } }
                }
            }
        }
    }
}
