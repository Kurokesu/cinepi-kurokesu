#include "camera_adapter.hpp"
#include "camera_session.hpp"
#include "logging.hpp"

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.adapter");
    return l;
}

CameraAdapter::CameraAdapter(CameraSession *session, QObject *parent)
    : QObject(parent), session_(session)
{
    connect(session_, &CameraSession::statsUpdated,
            this, &CameraAdapter::onStatsUpdated);
    connect(session_, &CameraSession::streamInfoUpdated,
            this, &CameraAdapter::onStreamInfo);
    connect(session_, &CameraSession::cameraError,
            this, &CameraAdapter::onCameraError);

    connect(this, &CameraAdapter::controlRequested,
            session_, &CameraSession::handleControl);

    connect(session_, &CameraSession::settingsLoaded,
            this, &CameraAdapter::onSettingsLoaded, Qt::QueuedConnection);

    displayTimer_.setSingleShot(true);
    displayTimer_.setInterval(143);
    connect(&displayTimer_, &QTimer::timeout,
            this, &CameraAdapter::flushDisplayUpdates);

    connect(session_, &QThread::started, this, [this]() {
        connected_ = true;
        logger()->info("Camera connected");
        Q_EMIT connectedChanged();
    });
    connect(session_, &QThread::finished, this, [this]() {
        connected_ = false;
        logger()->info("Camera disconnected");
        Q_EMIT connectedChanged();
    });
}

void CameraAdapter::sendControl(const QString &key, const QString &value)
{
    logger()->debug("Control: {} = {}", key.toStdString(), value.toStdString());
    Q_EMIT controlRequested(key, value);
}

void CameraAdapter::setInitialProperties(int iso, int shutterAngle,
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

void CameraAdapter::setIsoSensitivity(int value)
{
    sendControl("iso", QString::number(value));
}

void CameraAdapter::setShutterAngle(int value)
{
    sendControl("shutter_a", QString::number(value));
}

void CameraAdapter::setFrameRate(int value)
{
    sendControl("fps", QString::number(value));
}

void CameraAdapter::setColorTemperature(int value)
{
    sendControl("awb", QString::number(value));
}

void CameraAdapter::setRecording(bool value)
{
    logger()->info("Recording: {}", value ? "START" : "STOP");
    sendControl("is_recording", value ? "1" : "0");
    if (value != recording_) {
        recording_ = value;
        Q_EMIT recordingChanged();
    }
}

void CameraAdapter::setCompression(int value)
{
    sendControl("compress", QString::number(value));
    if (value != compression_) {
        compression_ = value;
        Q_EMIT compressionChanged();
    }
}

void CameraAdapter::onStatsUpdated(float framerate, int colorTemp,
                                      float focus, int frameCount,
                                      int bufferSize,
                                      float exposureTime, float analogueGain)
{
    Q_UNUSED(focus)

    int actualIso = static_cast<int>(analogueGain * 100 + 0.5f);
    if (actualIso != isoSensitivity_) {
        isoSensitivity_ = actualIso;
        isoDirty_ = true;
    }

    if (framerate > 0 && exposureTime > 0) {
        int actualAngle = static_cast<int>(
            360.0f * framerate * exposureTime / 1e6f + 0.5f);
        if (actualAngle != shutterAngle_) {
            shutterAngle_ = actualAngle;
            shutterDirty_ = true;
        }
    }

    if (colorTemp != colorTemperature_) {
        colorTemperature_ = colorTemp;
        wbDirty_ = true;
    }

    if ((isoDirty_ || shutterDirty_ || wbDirty_) && !displayTimer_.isActive())
        displayTimer_.start();

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

void CameraAdapter::onStreamInfo(int w, int h)
{
    if (w != width_ || h != height_) {
        logger()->info("Stream resolution: {}x{}", w, h);
        width_ = w;
        height_ = h;
        Q_EMIT resolutionChanged();
    }
}

void CameraAdapter::onSettingsLoaded(int iso, int shutterAngle, int fps, int wb)
{
    if (iso != isoSensitivity_) {
        isoSensitivity_ = iso;
        Q_EMIT isoSensitivityChanged();
    }
    if (shutterAngle != shutterAngle_) {
        shutterAngle_ = shutterAngle;
        Q_EMIT shutterAngleChanged();
    }
    if (fps != frameRate_) {
        frameRate_ = fps;
        Q_EMIT frameRateChanged();
    }
    if (wb != colorTemperature_) {
        colorTemperature_ = wb;
        Q_EMIT colorTemperatureChanged();
    }

    logger()->info("Settings sync: ISO={} SHT={} FPS={} WB={}",
                   iso, shutterAngle, fps, wb);

    Q_EMIT initialized(iso, shutterAngle, fps, wb);
}

void CameraAdapter::flushDisplayUpdates()
{
    if (isoDirty_) {
        isoDirty_ = false;
        Q_EMIT isoSensitivityChanged();
    }
    if (shutterDirty_) {
        shutterDirty_ = false;
        Q_EMIT shutterAngleChanged();
    }
    if (wbDirty_) {
        wbDirty_ = false;
        Q_EMIT colorTemperatureChanged();
    }
}

void CameraAdapter::onCameraError(const QString &msg)
{
    logger()->error("Camera error: {}", msg.toStdString());
    errorString_ = msg;
    connected_ = false;
    Q_EMIT errorChanged();
    Q_EMIT connectedChanged();
}
