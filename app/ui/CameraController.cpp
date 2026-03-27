#include "CameraController.h"
#include "CameraWorker.h"
#include "logging.h"

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.camera");
    return l;
}

CameraController::CameraController(CameraWorker *worker, QObject *parent)
    : QObject(parent), m_worker(worker)
{
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

void CameraController::setInitialProperties(int iso, int shutterAngle,
                                              int fps, int colorTemp)
{
    m_isoSensitivity = iso;
    m_shutterAngle = shutterAngle;
    m_frameRate = fps;
    m_colorTemperature = colorTemp;

    Q_EMIT isoSensitivityChanged();
    Q_EMIT shutterAngleChanged();
    Q_EMIT frameRateChanged();
    Q_EMIT colorTemperatureChanged();

    logger()->info("Initial properties: ISO={} SHT={} FPS={} CT={}",
                   iso, shutterAngle, fps, colorTemp);
}

void CameraController::setIsoSensitivity(int value)
{
    sendControl("iso", QString::number(value));
}

void CameraController::setShutterAngle(int value)
{
    sendControl("shutter_a", QString::number(value));
}

void CameraController::setFrameRate(int value)
{
    sendControl("fps", QString::number(value));
}

void CameraController::setColorTemperature(int value)
{
    sendControl("awb", QString::number(value));
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

void CameraController::onStatsUpdate(float framerate, int colorTemp,
                                      float focus, int frameCount,
                                      int bufferSize,
                                      float exposureTime, float analogueGain)
{
    Q_UNUSED(focus)

    int actualIso = static_cast<int>(analogueGain * 100 + 0.5f);
    if (actualIso != m_isoSensitivity) {
        m_isoSensitivity = actualIso;
        Q_EMIT isoSensitivityChanged();
    }

    if (framerate > 0 && exposureTime > 0) {
        int actualAngle = static_cast<int>(
            360.0f * framerate * exposureTime / 1e6f + 0.5f);
        if (actualAngle != m_shutterAngle) {
            m_shutterAngle = actualAngle;
            Q_EMIT shutterAngleChanged();
        }
    }

    if (colorTemp != m_colorTemperature) {
        m_colorTemperature = colorTemp;
        Q_EMIT colorTemperatureChanged();
    }

    int newFps = static_cast<int>(framerate + 0.5f);
    if (newFps != m_frameRate) {
        m_frameRate = newFps;
        Q_EMIT frameRateChanged();
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

void CameraController::onSettingsLoaded(int iso, int shutterAngle, int fps, int wb)
{
    logger()->info("Settings sync: ISO={} SHT={} FPS={} WB={}",
                   iso, shutterAngle, fps, wb);
}

void CameraController::onCameraError(const QString &msg)
{
    logger()->error("Camera error: {}", msg.toStdString());
    m_errorString = msg;
    m_connected = false;
    Q_EMIT errorChanged();
    Q_EMIT connectedChanged();
}
