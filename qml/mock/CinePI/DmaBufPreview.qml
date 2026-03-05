import QtQuick

/**
 * Stub DmaBufPreview for Design Studio.
 * Provides the same QML interface as the C++ DmaBufPreview so
 * CameraPreview.qml can be parsed without errors on Windows.
 */
Item {
    property bool available: false
    property int sourceWidth: 0
    property int sourceHeight: 0
}
