import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import CinePiUi

Page {
    id: root
    width: Constants.width
    height: Constants.height

    signal closed
    signal powerOffRequested

    Material.background: "#121212"

    header: ToolBar {
        Material.background: "#40000000"
        padding: 8
        implicitHeight: 64

        RowLayout {
            anchors.fill: parent
            spacing: Constants.spacingMedium

            ToolButton {
                icon.source: "images/chevron_backward_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
                icon.width: 48
                icon.height: 48
                onClicked: root.closed()
                background: Item {}
            }

            Label {
                text: "SETTINGS"
                font.pixelSize: 21
                font.weight: Font.Medium
                color: Material.foreground
                Layout.fillWidth: true
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 0

            SectionHeader {
                title: "Camera"
            }
            SectionPlaceholder {}

            SectionHeader {
                title: "Storage"
            }
            SectionPlaceholder {}

            SectionHeader {
                title: "Network"
            }
            SectionPlaceholder {}

            SectionHeader {
                title: "System"
            }

            ItemDelegate {
                Layout.fillWidth: true
                leftPadding: Constants.spacingLarge
                icon.source: "images/power_settings_new_48dp_E3E3E3_FILL0_wght300_GRAD0_opsz48.svg"
                icon.width: 32
                icon.height: 32
                icon.color: "#FF5252"
                text: "Power Off"
                font.pixelSize: 21
                onClicked: powerOffDialog.open()
            }
        }
    }

    Dialog {
        id: powerOffDialog
        anchors.centerIn: parent
        title: "Power Off"
        modal: true
        Material.background: "#1E1E1E"
        width: Math.min(root.width * 0.8, 480)

        Label {
            text: "Are you sure you want to power off?"
            font.pixelSize: 21
            color: Material.foreground
            wrapMode: Text.WordWrap
            width: parent.width
        }

        footer: DialogButtonBox {
            Button {
                text: "Cancel"
                font.pixelSize: 21
                implicitHeight: 56
                flat: true
                Material.foreground: "#999999"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
            Button {
                text: "Power Off"
                font.pixelSize: 21
                implicitHeight: 56
                flat: true
                Material.foreground: "#FF5252"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }

        onAccepted: root.powerOffRequested()
    }

    component SectionHeader: Pane {
        id: sectionPane
        property string title: ""
        Layout.fillWidth: true
        leftPadding: Constants.spacingLarge
        rightPadding: Constants.spacingLarge
        topPadding: 21
        bottomPadding: 4
        background: Item {}

        Label {
            text: sectionPane.title
            font.pixelSize: 18
            font.weight: Font.Medium
            color: "#999999"
        }
    }

    component SectionPlaceholder: ItemDelegate {
        Layout.fillWidth: true
        leftPadding: Constants.spacingLarge
        enabled: false
        text: "No settings available yet"
        font.pixelSize: 16
        Material.foreground: "#666666"
    }
}
