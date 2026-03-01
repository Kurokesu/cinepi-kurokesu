#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDebug>

#include "CameraWorker.h"
#include "ui/CameraController.h"
#include "ui/DmaBufPreview.h"
#include "ui/FrameProvider.h"
#include "ui/ConfigManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("CinePI");
    app.setOrganizationName("Kurokesu");

    QQuickStyle::setStyle("Default");

    qmlRegisterType<DmaBufPreview>("CinePI", 1, 0, "DmaBufPreview");

    QString configDir = qEnvironmentVariable("CINEPI_CONFIG_DIR",
        QCoreApplication::applicationDirPath() + "/../../config");

    CameraWorker cameraWorker(configDir);
    CameraController cameraController(&cameraWorker);
    FrameProvider *frameProvider = new FrameProvider();
    ConfigManager configManager(configDir);

    QQmlApplicationEngine engine;

    engine.addImageProvider("frames", frameProvider);

    engine.rootContext()->setContextProperty("camera", &cameraController);
    engine.rootContext()->setContextProperty("frameProvider", frameProvider);
    engine.rootContext()->setContextProperty("config", &configManager);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    // Connect camera preview frames to all DmaBufPreview instances.
    // The QML engine has loaded, so we can find the preview items.
    auto rootObjects = engine.rootObjects();
    for (auto *obj : rootObjects) {
        auto previews = obj->findChildren<DmaBufPreview *>();
        for (auto *preview : previews) {
            QObject::connect(&cameraWorker, &CameraWorker::frameReady,
                             preview, &DmaBufPreview::onFrameReady);
        }
    }

    cameraWorker.start();

    int ret = app.exec();

    cameraWorker.requestStop();
    cameraWorker.wait();

    return ret;
}
