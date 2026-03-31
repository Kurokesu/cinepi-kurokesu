#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDir>
#include <QFileInfo>
#include "quickstudioapplication.h"

int main(int argc, char *argv[])
{
    QString projectDir;
    for (int i = 1; i < argc; ++i)
        projectDir = argv[i];
    if (projectDir.isEmpty())
        projectDir = QDir::currentPath();
    projectDir = QFileInfo(projectDir).absoluteFilePath();

    qputenv("QT_QUICK_CONTROLS_CONF",
            (projectDir + "/qtquickcontrols2.conf").toUtf8());

    QGuiApplication app(argc, argv);

    qmlRegisterType<QuickStudioApplication>(
        "QtQuick.Studio.Application", 1, 0, "StudioApplication");

    QQmlApplicationEngine engine;
    engine.addImportPath(projectDir);
    engine.addImportPath(projectDir + "/Dependencies/Components/imports");
    engine.load(QUrl::fromLocalFile(projectDir + "/CinePiUiContent/App.qml"));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
