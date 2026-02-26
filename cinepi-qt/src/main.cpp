#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDebug>

#include "redisbridge.h"
#include "mjpegclient.h"
#include "frameprovider.h"
#include "configmanager.h"
#include "dmabufpreview.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("CinePI-Qt");
    app.setOrganizationName("Kurokesu");

    // Use a minimal style suitable for embedded
    QQuickStyle::setStyle("Default");

    // Register DmaBufPreview QML type (zero-copy GPU preview)
    qmlRegisterType<DmaBufPreview>("CinePI", 1, 0, "DmaBufPreview");

    // Create backend objects
    RedisBridge redisBridge;
    MjpegClient mjpegClient;
    FrameProvider *frameProvider = new FrameProvider(); // engine takes ownership
    ConfigManager configManager("/home/pi");

    // Connect MJPEG to frame provider (fallback when DMA-BUF is not available)
    QObject::connect(&mjpegClient, &MjpegClient::frameReady,
                     frameProvider, &FrameProvider::onNewFrame);

    // Set up QML engine
    QQmlApplicationEngine engine;

    // Register image provider (engine takes ownership of frameProvider)
    engine.addImageProvider("frames", frameProvider);

    // Expose C++ objects to QML
    engine.rootContext()->setContextProperty("redis", &redisBridge);
    engine.rootContext()->setContextProperty("mjpeg", &mjpegClient);
    engine.rootContext()->setContextProperty("frameProvider", frameProvider);
    engine.rootContext()->setContextProperty("config", &configManager);

    // Load main QML
    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    // Start MJPEG as fallback (remote access + fallback when DMA-BUF unavailable)
    mjpegClient.start("http://127.0.0.1:8000/stream");

    return app.exec();
}
