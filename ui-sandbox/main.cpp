/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * main.cpp - UI sandbox harness for iterating on CinePiUi QML without the
 * camera backend. Loads QML from disk via CINEPI_UI_QML_ROOT so edits on
 * host sync straight through. Forces fullscreen.
 */

#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>

#include "quickstudioapplication.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QString projectDir = qEnvironmentVariable("CINEPI_UI_QML_ROOT");
    if (projectDir.isEmpty() && argc > 1)
        projectDir = argv[1];
    if (projectDir.isEmpty()) {
        qFatal("No QML root. Set CINEPI_UI_QML_ROOT or pass a path argument.");
        return -1;
    }
    projectDir = QFileInfo(projectDir).absoluteFilePath();

    qputenv("QT_QUICK_CONTROLS_CONF",
            (projectDir + "/qtquickcontrols2.conf").toUtf8());

    qmlRegisterType<QuickStudioApplication>(
        "QtQuick.Studio.Application", 1, 0, "StudioApplication");

    QQmlApplicationEngine engine;
    engine.addImportPath(projectDir);
    engine.addImportPath(projectDir + "/Dependencies/Components/imports");
    engine.load(QUrl::fromLocalFile(projectDir + "/CinePiUiContent/App.qml"));

    if (engine.rootObjects().isEmpty())
        return -1;

    for (QObject *root : engine.rootObjects()) {
        if (auto *win = qobject_cast<QQuickWindow *>(root))
            win->showFullScreen();
    }

    return app.exec();
}
