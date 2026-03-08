pragma Singleton
import QtQuick

QtObject {
    property int iso: 800
    property int shutterAngle: 180
    property double shutterSpeed: 0.00555
    property int fps: 30
    property int whiteBalance: 0
    property bool recording: false
    property int width: 2736
    property int height: 1824
    property bool connected: true
    property int compression: 0
    property int frameCount: 1234
    property int bufferSize: 0

    function setISO(val) { iso = val }
    function setShutterAngle(val) { shutterAngle = val }
    function setFPS(val) { fps = val }
    function setWhiteBalance(val) { whiteBalance = val }
    function setRecording(val) { recording = val }
    function setCompression(val) { compression = val }
    function setColorGains(r, b) {}
}
