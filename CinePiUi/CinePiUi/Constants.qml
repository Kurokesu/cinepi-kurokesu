pragma Singleton
import QtQuick
import QtQuick.Studio.Application

QtObject {
    readonly property int width: 720
    readonly property int height: 720

    property string relativeFontDirectory: "fonts"

    /* Edit this comment to add your custom font */
    readonly property font font: Qt.font({
                                             family: Qt.application.font.family,
                                             pixelSize: Qt.application.font.pixelSize
                                         })
    readonly property font largeFont: Qt.font({
                                                  family: Qt.application.font.family,
                                                  pixelSize: Qt.application.font.pixelSize * 1.6
                                              })

    readonly property color backgroundColor: "#000000"
    readonly property color accentColor: "#CA2031"
    readonly property color textColor: "#FFFFFF"
    readonly property color textSecondaryColor: "#888888"


    property StudioApplication application: StudioApplication {
        fontPath: Qt.resolvedUrl("../CinePiUiContent/" + relativeFontDirectory)
    }
}
