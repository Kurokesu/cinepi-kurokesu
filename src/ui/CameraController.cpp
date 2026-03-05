#include "CameraController.h"
#include "CameraWorker.h"
#include "logging.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.camera");
    return l;
}

CameraController::CameraController(CameraWorker *worker, QObject *parent)
    : QObject(parent), m_worker(worker)
{
    loadInitialSettings();
    connect(m_worker, &CameraWorker::statsUpdate,
            this, &CameraController::onStatsUpdate);
    connect(m_worker, &CameraWorker::streamInfoUpdate,
            this, &CameraController::onStreamInfo);
    connect(m_worker, &CameraWorker::cameraError,
            this, &CameraController::onCameraError);

    connect(this, &CameraController::controlRequested,
            m_worker, &CameraWorker::handleControl);

    connect(m_worker, &CameraWorker::settingsLoaded,
            this, &CameraController::onSettingsLoaded, Qt::QueuedConnection);

    connect(m_worker, &QThread::started, this, [this]() {
        m_connected = true;
        logger()->info("Camera connected");
        Q_EMIT connectedChanged();
    });
    connect(m_worker, &QThread::finished, this, [this]() {
        m_connected = false;
        logger()->info("Camera disconnected");
        Q_EMIT connectedChanged();
    });
}

void CameraController::sendControl(const QString &key, const QString &value)
{
    logger()->debug("Control: {} = {}", key.toStdString(), value.toStdString());
    Q_EMIT controlRequested(key, value);
}

void CameraController::setISO(int value)
{
    sendControl("iso", QString::number(value));
    if (value != m_iso) {
        m_iso = value;
        Q_EMIT isoChanged();
    }
}

void CameraController::setShutterAngle(int value)
{
    sendControl("shutter_a", QString::number(value));
    if (value != m_shutterAngle) {
        m_shutterAngle = value;
        Q_EMIT shutterAngleChanged();
    }
}

void CameraController::setFPS(int value)
{
    sendControl("fps", QString::number(value));
    if (value != m_fps) {
        m_fps = value;
        Q_EMIT fpsChanged();
    }
}

void CameraController::setWhiteBalance(int value)
{
    sendControl("awb", QString::number(value));
    if (value != m_whiteBalance) {
        m_whiteBalance = value;
        Q_EMIT whiteBalanceChanged();
    }
}

void CameraController::setRecording(bool value)
{
    logger()->info("Recording: {}", value ? "START" : "STOP");
    sendControl("is_recording", value ? "1" : "0");
    if (value != m_recording) {
        m_recording = value;
        Q_EMIT recordingChanged();
    }
}

void CameraController::setCompression(int value)
{
    sendControl("compress", QString::number(value));
    if (value != m_compression) {
        m_compression = value;
        Q_EMIT compressionChanged();
    }
}

void CameraController::setColorGains(double r, double b)
{
    sendControl("cg_rb", QString("%1,%2").arg(r).arg(b));
    m_colorGainR = r;
    m_colorGainB = b;
    Q_EMIT colorGainsChanged();
}

void CameraController::onStatsUpdate(float framerate, int colorTemp,
                                      float focus, int frameCount,
                                      int bufferSize)
{
    int newFps = static_cast<int>(framerate + 0.5f);
    if (newFps != m_fps) {
        m_fps = newFps;
        Q_EMIT fpsChanged();
    }

    if (frameCount != m_frameCount || bufferSize != m_bufferSize) {
        m_frameCount = frameCount;
        m_bufferSize = bufferSize;
        Q_EMIT statsChanged();
    }

    if (!m_connected) {
        m_connected = true;
        Q_EMIT connectedChanged();
    }
}

void CameraController::onStreamInfo(int w, int h)
{
    if (w != m_width || h != m_height) {
        logger()->info("Stream resolution: {}x{}", w, h);
        m_width = w;
        m_height = h;
        Q_EMIT resolutionChanged();
    }
}

void CameraController::loadInitialSettings()
{
    QString path = m_worker->configDir() + "/settings.json";
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QJsonObject root = QJsonDocument::fromJson(file.readAll()).object();

    int gain = root.value("iso").toInt(4);
    m_iso = gain * 100;
    m_shutterAngle = static_cast<int>(root.value("shutter_a").toDouble(180.0));
    m_fps = static_cast<int>(root.value("fps").toDouble(30.0));
    m_whiteBalance = root.value("awb").toInt(0);

    logger()->info("Initial settings: ISO={} SHT={}° FPS={} WB={}",
                 m_iso, m_shutterAngle, m_fps, m_whiteBalance);
}

void CameraController::onSettingsLoaded(int iso, int shutterAngle, int fps, int wb)
{
    logger()->info("Settings sync: ISO={} SHT={}° FPS={} WB={}",
                 iso, shutterAngle, fps, wb);
    if (iso != m_iso)           { m_iso = iso;                   Q_EMIT isoChanged(); }
    if (shutterAngle != m_shutterAngle) { m_shutterAngle = shutterAngle; Q_EMIT shutterAngleChanged(); }
    if (fps != m_fps)           { m_fps = fps;                   Q_EMIT fpsChanged(); }
    if (wb != m_whiteBalance)   { m_whiteBalance = wb;           Q_EMIT whiteBalanceChanged(); }
}

void CameraController::onCameraError(const QString &msg)
{
    logger()->error("Camera error: {}", msg.toStdString());
    m_connected = false;
    Q_EMIT connectedChanged();
}
