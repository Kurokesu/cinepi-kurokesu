#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QTimer>
#include <hiredis/hiredis.h>
#include <memory>

/**
 * RedisBridge - Provides QML-accessible interface to Redis for camera control.
 *
 * Mirrors the Redis keys used by cinepi-raw:
 *   iso, awb, fps, shutter_a, shutter_s, cg_rb, width, height,
 *   is_recording, compress, thumbnail, thumbnail_size, mic_gain, etc.
 *
 * Publishes control changes to "cp_controls" channel.
 * Polls stats from Redis keys periodically.
 */
class RedisBridge : public QObject
{
    Q_OBJECT

    // Camera parameters (read from Redis, writable via controls)
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

public:
    explicit RedisBridge(QObject *parent = nullptr);
    ~RedisBridge();

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

    // QML-callable methods
    Q_INVOKABLE void setISO(int value);
    Q_INVOKABLE void setShutterAngle(int value);
    Q_INVOKABLE void setFPS(int value);
    Q_INVOKABLE void setWhiteBalance(int value);
    Q_INVOKABLE void setRecording(bool value);
    Q_INVOKABLE void setCompression(int value);
    Q_INVOKABLE void setColorGains(double r, double b);
    Q_INVOKABLE QString getKey(const QString &key);
    Q_INVOKABLE void setKey(const QString &key, const QString &value);

signals:
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
    void statsReceived(const QVariantMap &stats);

private slots:
    void pollRedis();

private:
    void connectToRedis();
    void disconnectRedis();
    QString redisGet(const QString &key);
    void redisSet(const QString &key, const QString &value);
    void redisPublish(const QString &channel, const QString &message);
    void fetchAllValues();

    redisContext *m_ctx = nullptr;
    QTimer m_pollTimer;
    bool m_connected = false;

    int m_iso = 100;
    int m_shutterAngle = 180;
    double m_shutterSpeed = 0.0;
    int m_fps = 24;
    int m_whiteBalance = 0;
    bool m_recording = false;
    int m_width = 0;
    int m_height = 0;
    double m_colorGainR = 1.0;
    double m_colorGainB = 1.0;
    int m_compression = 0;
};
