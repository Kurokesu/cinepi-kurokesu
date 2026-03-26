#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QCursor>
#include <QtQml/qqmlextensionplugin.h>

#include "logging.h"
#include "CameraWorker.h"
#include "ui/CameraController.h"
#include "ui/DmaBufPreview.h"
#include "ui/FrameProvider.h"
#include "ui/ConfigManager.h"
#include "studio_app_compat.h"

Q_IMPORT_QML_PLUGIN(CinePiUiPlugin)
Q_IMPORT_QML_PLUGIN(CinePiUiContentPlugin)

static void qtMessageHandler(QtMsgType type, const QMessageLogContext &ctx, const QString &msg)
{
    Q_UNUSED(ctx)
    auto logger = cinepi::getLogger("qt");
    std::string m = msg.toStdString();
    switch (type) {
    case QtDebugMsg:    logger->debug("{}", m); break;
    case QtInfoMsg:     logger->info("{}", m); break;
    case QtWarningMsg:  logger->warn("{}", m); break;
    case QtCriticalMsg: logger->error("{}", m); break;
    case QtFatalMsg:    logger->critical("{}", m); break;
    }
}

int main(int argc, char *argv[])
{
    cinepi::initLogging();
    qInstallMessageHandler(qtMessageHandler);

    auto log = cinepi::getLogger("main");
    log->info("CinePI v{} starting", PROJECT_VERSION);

    QGuiApplication app(argc, argv);
    app.setApplicationName("CinePI");
    app.setOrganizationName("Kurokesu");
    app.setOverrideCursor(QCursor(Qt::BlankCursor));

    QQuickStyle::setStyle("Material");

    registerStudioApplication();
    qmlRegisterType<DmaBufPreview>("CinePI", 1, 0, "DmaBufPreview");

    QString configDir = qEnvironmentVariable("CINEPI_CONFIG_DIR",
        QCoreApplication::applicationDirPath() + "/../../config");
    log->info("Config dir: {}", configDir.toStdString());

    CameraWorker cameraWorker(configDir);
    CameraController cameraController(&cameraWorker);
    FrameProvider *frameProvider = new FrameProvider();
    ConfigManager configManager(configDir);

    QQmlApplicationEngine engine;

    engine.addImageProvider("frames", frameProvider);

    engine.rootContext()->setContextProperty("camera", &cameraController);
    engine.rootContext()->setContextProperty("frameProvider", frameProvider);
    engine.rootContext()->setContextProperty("config", &configManager);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    auto rootObjects = engine.rootObjects();
    for (auto *obj : rootObjects) {
        auto previews = obj->findChildren<DmaBufPreview *>();
        for (auto *preview : previews) {
            QObject::connect(&cameraWorker, &CameraWorker::frameReady,
                             preview, &DmaBufPreview::onFrameReady);
        }
    }

    cameraWorker.start();
    log->info("Camera worker started");

    int ret = app.exec();

    log->info("Shutting down...");
    cameraWorker.requestStop();
    cameraWorker.wait();
    log->info("CinePI stopped (exit code {})", ret);

    return ret;
}
