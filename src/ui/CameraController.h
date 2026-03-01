#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

class CameraWorker;

class CameraController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int iso READ iso NOTIFY isoChanged)
    Q_PROPERTY(int shutterAngle READ shutterAngle NOTIFY shutterAngleChanged)
    Q_PROPERTY(double shutterSpeed READ shutterSpeed NOTIFY shutterSpeedChanged)
    Q_PROPERTY(int fps READ fps NOTIFY fpsChanged)
    Q_PROPERTY(int whiteBalance READ whiteBalance NOTIFY whiteBalanceChanged)
    Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)
    Q_PROPERTY(int width READ width NOTIFY resolutionChanged)
    Q_PROPERTY(int height READ height NOTIFY resolutionChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(double colorGainR READ colorGainR NOTIFY colorGainsChanged)
    Q_PROPERTY(double colorGainB READ colorGainB NOTIFY colorGainsChanged)
    Q_PROPERTY(int compression READ compression NOTIFY compressionChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY statsChanged)
    Q_PROPERTY(int bufferSize READ bufferSize NOTIFY statsChanged)

public:
    explicit CameraController(CameraWorker *worker, QObject *parent = nullptr);

    int iso() const { return m_iso; }
    int shutterAngle() const { return m_shutterAngle; }
    double shutterSpeed() const { return m_shutterSpeed; }
    int fps() const { return m_fps; }
    int whiteBalance() const { return m_whiteBalance; }
    bool recording() const { return m_recording; }
    int width() const { return m_width; }
    int height() const { return m_height; }
    bool connected() const { return m_connected; }
    double colorGainR() const { return m_colorGainR; }
    double colorGainB() const { return m_colorGainB; }
    int compression() const { return m_compression; }
    int frameCount() const { return m_frameCount; }
    int bufferSize() const { return m_bufferSize; }

    Q_INVOKABLE void setISO(int value);
    Q_INVOKABLE void setShutterAngle(int value);
    Q_INVOKABLE void setFPS(int value);
    Q_INVOKABLE void setWhiteBalance(int value);
    Q_INVOKABLE void setRecording(bool value);
    Q_INVOKABLE void setCompression(int value);
    Q_INVOKABLE void setColorGains(double r, double b);

Q_SIGNALS:
    void isoChanged();
    void shutterAngleChanged();
    void shutterSpeedChanged();
    void fpsChanged();
    void whiteBalanceChanged();
    void recordingChanged();
    void resolutionChanged();
    void connectedChanged();
    void colorGainsChanged();
    void compressionChanged();
    void statsChanged();

    void controlRequested(const QString &key, const QString &value);

private Q_SLOTS:
    void onStatsUpdate(float framerate, int colorTemp, float focus,
                       int frameCount, int bufferSize);
    void onStreamInfo(int w, int h);
    void onCameraError(const QString &msg);

private:
    void sendControl(const QString &key, const QString &value);

    CameraWorker *m_worker;

    int m_iso = 100;
    int m_shutterAngle = 180;
    double m_shutterSpeed = 0.0;
    int m_fps = 24;
    int m_whiteBalance = 0;
    bool m_recording = false;
    int m_width = 0;
    int m_height = 0;
    bool m_connected = false;
    double m_colorGainR = 1.0;
    double m_colorGainB = 1.0;
    int m_compression = 0;
    int m_frameCount = 0;
    int m_bufferSize = 0;
};
