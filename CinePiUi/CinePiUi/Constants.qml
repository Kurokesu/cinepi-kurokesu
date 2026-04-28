// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026, UAB Kurokesu

pragma Singleton
import QtQuick
import QtQuick.Studio.Application

QtObject {
    readonly property int width: 720
    readonly property int height: 720

    property string relativeFontDirectory: "fonts"

    readonly property string fontFamily: "Roboto"

    readonly property int fontSizeHeadlineSmall: 32
    readonly property int fontSizeTitleMedium: 28
    readonly property int fontSizeBodyLarge: 20
    readonly property int fontSizeBodyMedium: 18
    readonly property int fontSizeLabelLarge: 28
    readonly property int fontSizeLabelMedium: 16

    readonly property color textSecondaryColor: "#B3FFFFFF"
    readonly property color textDisabledColor: "#61FFFFFF"

    readonly property int touchTargetMin: 48
    readonly property int controlsBarHeight: 100
    readonly property int statusBarHeight: 100
    readonly property int panelHeight: 60
    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 16

    property StudioApplication application: StudioApplication {
        fontPath: Qt.resolvedUrl("../CinePiUiContent/" + relativeFontDirectory)
    }
}
