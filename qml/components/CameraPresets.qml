pragma Singleton
import QtQuick

QtObject {
    readonly property var isoValues: [100, 200, 400, 800, 1600, 3200, 6400, 12800]
    readonly property var shutterAngles: [11, 22, 45, 72, 90, 144, 172, 180, 270, 360]
    readonly property var fpsOptions: [24, 25, 30, 48, 50, 60]
    readonly property var whiteBalancePresets: [
        { label: "AUTO", value: 0 },
        { label: "2800K", value: 2800 },
        { label: "3200K", value: 3200 },
        { label: "4000K", value: 4000 },
        { label: "4500K", value: 4500 },
        { label: "5600K", value: 5600 },
        { label: "6500K", value: 6500 },
        { label: "7500K", value: 7500 },
        { label: "9000K", value: 9000 }
    ]
    readonly property var compressionOptions: [
        { label: "None", value: 0 },
        { label: "Lossy", value: 1 },
        { label: "Lossless", value: 2 }
    ]
}
