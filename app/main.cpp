#include <QGuiApplication>
#include <QProcess>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QCursor>
#include <QtQml/qqmlextensionplugin.h>

#include "logging.hpp"
#include "camera_session.hpp"
#include "ui/camera_adapter.hpp"
#include "ui/viewfinder.hpp"
#include "ui/frame_provider.hpp"
#include "ui/config_manager.hpp"
#include "studio_app_compat.hpp"
#include "camera/camera_backend.hpp"

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
    qmlRegisterType<Viewfinder>("CinePI", 1, 0, "Viewfinder");

    QString configDir = qEnvironmentVariable("CINEPI_CONFIG_DIR",
        QCoreApplication::applicationDirPath() + "/../../config");
    log->info("Config dir: {}", configDir.toStdString());

    ConfigManager configManager;

    int iso = configManager.value("manualIsoSensitivity").toInt();
    int sht = configManager.value("manualShutterAngle").toInt();
    int fps = configManager.value("frameRate").toInt();
    int ct  = configManager.value("colorTemperature").toInt();

    CameraSession cameraSession(configDir);
    cameraSession.setInitialSettings(
        isoToGain(iso),
        sht > 0 ? sht : -1,
        fps,
        ct
    );

    CameraAdapter cameraAdapter(&cameraSession);
    cameraAdapter.setInitialProperties(iso, sht, fps, ct);

    FrameProvider *frameProvider = new FrameProvider();

    QQmlApplicationEngine engine;

    engine.addImageProvider("frames", frameProvider);

    engine.rootContext()->setContextProperty("camera", &cameraAdapter);
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
        auto viewfinders = obj->findChildren<Viewfinder *>();
        for (auto *viewfinder : viewfinders) {
            QObject::connect(&cameraSession, &CameraSession::frameReady,
                             viewfinder, &Viewfinder::onFrameReady);
        }
    }

    cameraSession.start();
    cameraSession.resume();
    log->info("Camera session started");

    int ret = app.exec();

    log->info("Shutting down...");
    configManager.save();
    cameraSession.requestStop();

    if (cameraAdapter.powerOffRequested()) {
        log->info("System power off requested");
        if (!QProcess::startDetached("sudo", {"poweroff"}))
            log->error("Failed to execute 'sudo poweroff'");
        log->info("CinePI stopped, powering off");
        return 0;
    }

    cameraSession.wait();
    log->info("CinePI stopped (exit code {})", ret);
    return ret;
}
