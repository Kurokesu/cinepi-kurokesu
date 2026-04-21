// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QApplication>
#include <QQmlApplicationEngine>

#include "autogen/environment.h"

int main(int argc, char *argv[])
{
    set_qt_environment();
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // Load QML from disk when CINEPI_UI_QML_ROOT is set (live iteration).
    QUrl url(mainQmlFile);
    if (qEnvironmentVariableIsSet("CINEPI_UI_QML_ROOT")) {
        const QString root = qEnvironmentVariable("CINEPI_UI_QML_ROOT");
        engine.addImportPath(root);
        url = QUrl::fromLocalFile(root + "/CinePiUiContent/App.qml");
    }

    QObject::connect(
                &engine, &QQmlApplicationEngine::objectCreated, &app,
                [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.addImportPath(QCoreApplication::applicationDirPath() + "/qml");
    engine.addImportPath(":/");
    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
