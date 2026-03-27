#include "CameraController.h"
#include "CameraWorker.h"
#include "logging.h"

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.controller");
    return l;
}

CameraController::CameraController(CameraWorker *worker, QObject *parent)
    : QObject(parent), worker_(worker)
{
    connect(worker_, &CameraWorker::statsUpdated,
            this, &CameraController::onStatsUpdated);
    connect(worker_, &CameraWorker::streamInfoUpdated,
            this, &CameraController::onStreamInfo);
    connect(worker_, &CameraWorker::cameraError,
            this, &CameraController::onCameraError);

    connect(this, &CameraController::controlRequested,
            worker_, &CameraWorker::handleControl);

    connect(worker_, &CameraWorker::settingsLoaded,
            this, &CameraController::onSettingsLoaded, Qt::QueuedConnection);

    connect(worker_, &QThread::started, this, [this]() {
        connected_ = true;
        logger()->info("Camera connected");
        Q_EMIT connectedChanged();
    });
    connect(worker_, &QThread::finished, this, [this]() {
        connected_ = false;
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
    isoSensitivity_ = iso;
    shutterAngle_ = shutterAngle;
    frameRate_ = fps;
    colorTemperature_ = colorTemp;

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
    if (value != recording_) {
        recording_ = value;
        Q_EMIT recordingChanged();
    }
}

void CameraController::setCompression(int value)
{
    sendControl("compress", QString::number(value));
    if (value != compression_) {
        compression_ = value;
        Q_EMIT compressionChanged();
    }
}

void CameraController::onStatsUpdated(float framerate, int colorTemp,
                                      float focus, int frameCount,
                                      int bufferSize,
                                      float exposureTime, float analogueGain)
{
    Q_UNUSED(focus)

    int actualIso = static_cast<int>(analogueGain * 100 + 0.5f);
    if (actualIso != isoSensitivity_) {
        isoSensitivity_ = actualIso;
        Q_EMIT isoSensitivityChanged();
    }

    if (framerate > 0 && exposureTime > 0) {
        int actualAngle = static_cast<int>(
            360.0f * framerate * exposureTime / 1e6f + 0.5f);
        if (actualAngle != shutterAngle_) {
            shutterAngle_ = actualAngle;
            Q_EMIT shutterAngleChanged();
        }
    }

    if (colorTemp != colorTemperature_) {
        colorTemperature_ = colorTemp;
        Q_EMIT colorTemperatureChanged();
    }

    int newFps = static_cast<int>(framerate + 0.5f);
    if (newFps != frameRate_) {
        frameRate_ = newFps;
        Q_EMIT frameRateChanged();
    }

    if (frameCount != frameCount_ || bufferSize != bufferSize_) {
        frameCount_ = frameCount;
        bufferSize_ = bufferSize;
        Q_EMIT statsChanged();
    }

    if (!connected_) {
        connected_ = true;
        Q_EMIT connectedChanged();
    }
}

void CameraController::onStreamInfo(int w, int h)
{
    if (w != width_ || h != height_) {
        logger()->info("Stream resolution: {}x{}", w, h);
        width_ = w;
        height_ = h;
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
    errorString_ = msg;
    connected_ = false;
    Q_EMIT errorChanged();
    Q_EMIT connectedChanged();
}
