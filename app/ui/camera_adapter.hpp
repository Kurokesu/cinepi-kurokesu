#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

class CameraSession;

class CameraAdapter : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int isoSensitivity READ isoSensitivity NOTIFY isoSensitivityChanged)
    Q_PROPERTY(int shutterAngle READ shutterAngle NOTIFY shutterAngleChanged)
    Q_PROPERTY(int frameRate READ frameRate NOTIFY frameRateChanged)
    Q_PROPERTY(int colorTemperature READ colorTemperature NOTIFY colorTemperatureChanged)
    Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)
    Q_PROPERTY(int width READ width NOTIFY resolutionChanged)
    Q_PROPERTY(int height READ height NOTIFY resolutionChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(int compression READ compression NOTIFY compressionChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY statsChanged)
    Q_PROPERTY(int bufferSize READ bufferSize NOTIFY statsChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorChanged)

public:
    explicit CameraAdapter(CameraSession *session, QObject *parent = nullptr);

    int isoSensitivity() const { return isoSensitivity_; }
    int shutterAngle() const { return shutterAngle_; }
    int frameRate() const { return frameRate_; }
    int colorTemperature() const { return colorTemperature_; }
    bool recording() const { return recording_; }
    int width() const { return width_; }
    int height() const { return height_; }
    bool connected() const { return connected_; }
    int compression() const { return compression_; }
    int frameCount() const { return frameCount_; }
    int bufferSize() const { return bufferSize_; }
    QString errorString() const { return errorString_; }

    Q_INVOKABLE void setIsoSensitivity(int value);
    Q_INVOKABLE void setShutterAngle(int value);
    Q_INVOKABLE void setFrameRate(int value);
    Q_INVOKABLE void setColorTemperature(int value);
    Q_INVOKABLE void setRecording(bool value);
    Q_INVOKABLE void setCompression(int value);
    Q_INVOKABLE void stopCamera();
    Q_INVOKABLE void startCamera();
    Q_INVOKABLE void powerOff();

    void setInitialProperties(int iso, int shutterAngle, int fps, int colorTemp);
    bool powerOffRequested() const { return powerOffRequested_; }

Q_SIGNALS:
    void isoSensitivityChanged();
    void shutterAngleChanged();
    void frameRateChanged();
    void colorTemperatureChanged();
    void recordingChanged();
    void resolutionChanged();
    void connectedChanged();
    void compressionChanged();
    void statsChanged();
    void errorChanged();

    void controlRequested(const QString &key, const QString &value);
    void initialized(int iso, int shutterAngle, int fps, int colorTemp);

private Q_SLOTS:
    void onStatsUpdated(float framerate, int colorTemp, float focus,
                       int frameCount, int bufferSize,
                       float exposureTime, float analogueGain);
    void onStreamInfo(int w, int h);
    void onSettingsLoaded(int iso, int shutterAngle, int fps, int wb);
    void onCameraError(const QString &msg);

private:
    void sendControl(const QString &key, const QString &value);
    void flushDisplayUpdates();

    CameraSession *session_;
    QTimer displayTimer_;
    bool isoDirty_ = false;
    bool shutterDirty_ = false;
    bool wbDirty_ = false;

    int isoSensitivity_ = 800;
    int shutterAngle_ = 180;
    int frameRate_ = 24;
    int colorTemperature_ = 0;
    bool recording_ = false;
    int width_ = 0;
    int height_ = 0;
    bool connected_ = false;
    int compression_ = 0;
    int frameCount_ = 0;
    int bufferSize_ = 0;
    QString errorString_;
    bool powerOffRequested_ = false;
};
