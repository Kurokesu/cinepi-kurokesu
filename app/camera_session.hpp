#pragma once

#include <QThread>
#include <QString>
#include <atomic>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

class CameraSession : public QThread
{
    Q_OBJECT

public:
    explicit CameraSession(const QString &configDir, QObject *parent = nullptr);
    ~CameraSession() override;

    void requestStop();
    void setInitialSettings(int isoGain, int shutterAngle, int fps, int colorTemp);

    const QString &configDir() const { return configDir_; }

Q_SIGNALS:
    void frameReady(int fd, unsigned int width, unsigned int height,
                    unsigned int stride, quint64 frame);
    void statsUpdated(float framerate, int colorTemp, float focus,
                     int frameCount, int bufferSize,
                     float exposureTime, float analogueGain);
    void streamInfoUpdated(int width, int height);
    void settingsLoaded(int iso, int shutterAngle, int fps, int wb);
    void cameraError(const QString &message);

public Q_SLOTS:
    void handleControl(const QString &key, const QString &value);

protected:
    void run() override;

private:
    QString configDir_;
    std::atomic<bool> stopRequested_{false};

    std::mutex controlMutex_;
    std::vector<std::pair<std::string, std::string>> pendingControls_;

    int isoGain_ = 8;
    int shutterAngle_ = 180;
    int fps_ = 24;
    int colorTemp_ = 0;
};
