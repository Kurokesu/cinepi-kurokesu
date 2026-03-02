#include "CameraController.h"
#include "CameraWorker.h"
#include "logging.h"

static auto logger = cinepi::getLogger("ui.camera");

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

    connect(m_worker, &QThread::started, this, [this]() {
        m_connected = true;
        logger->info("Camera connected");
        Q_EMIT connectedChanged();
    });
    connect(m_worker, &QThread::finished, this, [this]() {
        m_connected = false;
        logger->info("Camera disconnected");
        Q_EMIT connectedChanged();
    });
}

void CameraController::sendControl(const QString &key, const QString &value)
{
    logger->debug("Control: {} = {}", key.toStdString(), value.toStdString());
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
    logger->info("Recording: {}", value ? "START" : "STOP");
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
        logger->info("Stream resolution: {}x{}", w, h);
        m_width = w;
        m_height = h;
        Q_EMIT resolutionChanged();
    }
}

void CameraController::onCameraError(const QString &msg)
{
    logger->error("Camera error: {}", msg.toStdString());
    m_connected = false;
    Q_EMIT connectedChanged();
}
