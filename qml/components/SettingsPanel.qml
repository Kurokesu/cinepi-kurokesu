import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    color: Theme.surface
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

                Rectangle {
                    width: 40; height: 40; radius: 20
                    color: closeMouse.pressed ? Theme.surfacePressed : Theme.surfaceHover
                    scale: closeMouse.pressed ? Theme.pressScale : 1.0

                    Behavior on scale {
                        SpringAnimation { spring: 4; damping: 0.6 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: Theme.textSecondary
                        font.pixelSize: 18
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
                onToggled: function(val) { config.zebraEnabled = val }
            }

            Item { width: 1; height: 4; visible: config.zebraEnabled }

            RowLayout {
                width: parent.width
                visible: config.zebraEnabled
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
                    value: config.zebraThreshold
                    onMoved: config.zebraThreshold = value

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
                    text: (config.zebraThreshold * 100).toFixed(0) + "%"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.family: Theme.fontValue
                    Layout.preferredWidth: 36
                }
            }

            Item { width: 1; height: 4; visible: config.zebraEnabled }

            SettingToggle {
                label: "False Color"
                checked: config.falseColorEnabled
                onToggled: function(val) { config.falseColorEnabled = val }
            }

            SettingToggle {
                label: "Focus Peaking"
                checked: config.focusPeakingEnabled
                onToggled: function(val) { config.focusPeakingEnabled = val }
            }

            SettingToggle {
                label: "Grayscale"
                checked: config.grayscaleEnabled
                onToggled: function(val) { config.grayscaleEnabled = val }
            }

            SectionHeader { text: "COMPOSITION GUIDES" }

            SettingToggle {
                label: "Rule of Thirds"
                checked: config.thirdsGridEnabled
                onToggled: function(val) { config.thirdsGridEnabled = val }
            }

            SettingToggle {
                label: "Center Crosshair"
                checked: config.crosshairEnabled
                onToggled: function(val) { config.crosshairEnabled = val }
            }

            SettingToggle {
                label: "16:9 Guide"
                checked: config.cinematicGuideEnabled
                onToggled: function(val) { config.cinematicGuideEnabled = val }
            }

            SettingToggle {
                label: "1.85:1 Guide"
                checked: config.cinematicGuide185Enabled
                onToggled: function(val) { config.cinematicGuide185Enabled = val }
            }

            SettingToggle {
                label: "4:3 Guide"
                checked: config.cinematicGuide43Enabled
                onToggled: function(val) { config.cinematicGuide43Enabled = val }
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
                            model: [24, 25, 30, 48, 50, 60]
                            delegate: Rectangle {
                                width: 56; height: 40
                                radius: 20
                                color: camera.fps === modelData ? Theme.accent : Theme.surfaceHover
                                scale: fpsMouse.pressed ? Theme.pressScale : 1.0

                                Behavior on scale {
                                    SpringAnimation { spring: 4; damping: 0.6 }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                    font.family: Theme.fontValue
                                    font.weight: Font.Medium
                                }
                                MouseArea {
                                    id: fpsMouse
                                    anchors.fill: parent
                                    onClicked: camera.setFPS(modelData)
                                }
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
                            model: [
                                { label: "None", val: 0 },
                                { label: "Lossy", val: 1 },
                                { label: "Lossless", val: 2 }
                            ]
                            delegate: Rectangle {
                                width: compLabel.implicitWidth + 32; height: 40
                                radius: 20
                                color: camera.compression === modelData.val ? Theme.accent : Theme.surfaceHover
                                scale: compMouse.pressed ? Theme.pressScale : 1.0

                                Behavior on scale {
                                    SpringAnimation { spring: 4; damping: 0.6 }
                                }

                                Text {
                                    id: compLabel
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    color: Theme.textPrimary
                                    font.pixelSize: 13
                                    font.family: Theme.fontBody
                                    font.weight: Font.Medium
                                }
                                MouseArea {
                                    id: compMouse
                                    anchors.fill: parent
                                    onClicked: camera.setCompression(modelData.val)
                                }
                            }
                        }
                    }
                }
            }

            SectionHeader { text: "SYSTEM" }

            Text {
                text: "Camera: " + (camera.connected ? "Connected" : "Disconnected")
                color: camera.connected ? Theme.success : Theme.danger
                font.pixelSize: 13
                font.family: Theme.fontBody
            }

            Text {
                text: "Resolution: " + (camera.width > 0 ? camera.width + "x" + camera.height : "N/A")
                color: Theme.textSecondary
                font.pixelSize: 13
                font.family: Theme.fontBody
            }

            Item { width: 1; height: 16 }

            Rectangle {
                width: parent.width
                height: 52
                radius: Theme.radiusMedium
                color: exitMouse.pressed ? "#CC2222" : "#882222"
                scale: exitMouse.pressed ? Theme.pressScale : 1.0

                Behavior on scale {
                    SpringAnimation { spring: 4; damping: 0.6 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "EXIT APPLICATION"
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    font.family: Theme.fontLabel
                    font.letterSpacing: 1.5
                }

                MouseArea {
                    id: exitMouse
                    anchors.fill: parent
                    onClicked: Qt.quit()
                }
            }

            Item { width: 1; height: 32 }
        }
    }

    component SectionHeader: Item {
        property string text: ""
        width: parent.width
        height: 36

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.separator
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.text
            color: Theme.textTertiary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.family: Theme.fontLabel
            font.letterSpacing: 2
        }
    }

    component SettingToggle: RowLayout {
        property string label: ""
        property bool checked: false
        signal toggled(bool newValue)

        width: parent.width
        spacing: 8

        Text {
            text: label
            color: Theme.textPrimary
            font.pixelSize: 13
            font.family: Theme.fontBody
            Layout.fillWidth: true
        }

        Switch {
            checked: parent.checked
            onToggled: function() { parent.toggled(checked) }

            indicator: Rectangle {
                width: 48; height: 28; radius: 14
                color: parent.checked ? Theme.accent : Theme.surfacePressed
                x: parent.leftPadding
                y: parent.height / 2 - height / 2

                Rectangle {
                    x: parent.parent.checked ? parent.width - width - 3 : 3
                    y: 3
                    width: 22; height: 22; radius: 11
                    color: Theme.textPrimary
                    Behavior on x { SpringAnimation { spring: 4; damping: 0.6 } }
                }
            }
        }
    }
}
