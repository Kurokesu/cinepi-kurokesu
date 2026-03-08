pragma Singleton
import QtQuick

QtObject {
    // --- Color Palette (cinema-inspired, high-contrast for outdoor use) ---
    readonly property color bg:             "#000000"
    readonly property color surface:        "#1A1A1A"
    readonly property color surfaceHover:   "#252525"
    readonly property color surfacePressed: "#333333"
    readonly property color barOverlay:     "#141414"
    readonly property color accent:         "#FF5722"
    readonly property color accentDim:      "#CC4400"
    readonly property color textPrimary:    "#F0F0F0"
    readonly property color textSecondary:  "#999999"
    readonly property color textTertiary:   "#666666"
    readonly property color recording:      "#FF2D2D"
    readonly property color success:        "#34C759"
    readonly property color danger:         "#FF3B30"
    readonly property color separator:      "#2A2A2A"

    // --- Typography ---
    readonly property string fontLabel: "sans-serif"
    readonly property string fontValue: "monospace"
    readonly property string fontBody:  "sans-serif"

    // --- Sizes (calibrated for HyperPixel 4.0 Square: 720px / 72mm) ---
    readonly property int statusBarHeight:   56
    readonly property int controlBarHeight:  88
    readonly property int recordButtonSize:  84
    readonly property int gearButtonSize:    64
    readonly property int popupItemWidth:    76
    readonly property int popupItemHeight:   48
    readonly property int popupItemWidthWB:  96
    readonly property int popupWidth:        340

    // --- Corner Radii ---
    readonly property int radiusSmall:  8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge:  16

    // --- Animation Durations ---
    readonly property int durationFast:   120
    readonly property int durationNormal: 200
    readonly property int durationSlow:   300

    // --- Spring Parameters ---
    readonly property real springRate:    3.0
    readonly property real springDamping: 0.7
    readonly property real pressScale:    0.92
    readonly property real pressScaleHeavy: 0.88
}
