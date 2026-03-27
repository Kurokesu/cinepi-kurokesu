#pragma once

#include <QObject>
#include <QString>

class CameraWorker;

class CameraController : public QObject
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
    explicit CameraController(CameraWorker *worker, QObject *parent = nullptr);

    int isoSensitivity() const { return m_isoSensitivity; }
    int shutterAngle() const { return m_shutterAngle; }
    int frameRate() const { return m_frameRate; }
    int colorTemperature() const { return m_colorTemperature; }
    bool recording() const { return m_recording; }
    int width() const { return m_width; }
    int height() const { return m_height; }
    bool connected() const { return m_connected; }
    int compression() const { return m_compression; }
    int frameCount() const { return m_frameCount; }
    int bufferSize() const { return m_bufferSize; }
    QString errorString() const { return m_errorString; }

    Q_INVOKABLE void setIsoSensitivity(int value);
    Q_INVOKABLE void setShutterAngle(int value);
    Q_INVOKABLE void setFrameRate(int value);
    Q_INVOKABLE void setColorTemperature(int value);
    Q_INVOKABLE void setRecording(bool value);
    Q_INVOKABLE void setCompression(int value);

    void setInitialProperties(int iso, int shutterAngle, int fps, int colorTemp);

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

private Q_SLOTS:
    void onStatsUpdate(float framerate, int colorTemp, float focus,
                       int frameCount, int bufferSize,
                       float exposureTime, float analogueGain);
    void onStreamInfo(int w, int h);
    void onSettingsLoaded(int iso, int shutterAngle, int fps, int wb);
    void onCameraError(const QString &msg);

private:
    void sendControl(const QString &key, const QString &value);

    CameraWorker *m_worker;

    int m_isoSensitivity = 800;
    int m_shutterAngle = 180;
    int m_frameRate = 24;
    int m_colorTemperature = 0;
    bool m_recording = false;
    int m_width = 0;
    int m_height = 0;
    bool m_connected = false;
    int m_compression = 0;
    int m_frameCount = 0;
    int m_bufferSize = 0;
    QString m_errorString;
};
