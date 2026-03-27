#pragma once

#include <QThread>
#include <QString>
#include <atomic>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

class CameraWorker : public QThread
{
    Q_OBJECT

public:
    explicit CameraWorker(const QString &configDir, QObject *parent = nullptr);
    ~CameraWorker() override;

    void requestStop();
    void setInitialSettings(int isoGain, int shutterAngle, int fps, int colorTemp);

    const QString &configDir() const { return m_configDir; }

Q_SIGNALS:
    void frameReady(int fd, unsigned int width, unsigned int height,
                    unsigned int stride, quint64 frame);
    void statsUpdate(float framerate, int colorTemp, float focus,
                     int frameCount, int bufferSize,
                     float exposureTime, float analogueGain);
    void streamInfoUpdate(int width, int height);
    void settingsLoaded(int iso, int shutterAngle, int fps, int wb);
    void cameraError(const QString &message);

public Q_SLOTS:
    void handleControl(const QString &key, const QString &value);

protected:
    void run() override;

private:
    QString m_configDir;
    std::atomic<bool> m_stopRequested{false};

    std::mutex m_controlMutex;
    std::vector<std::pair<std::string, std::string>> m_pendingControls;

    int m_isoGain = 8;
    int m_shutterAngle = 180;
    int m_fps = 24;
    int m_colorTemp = 0;
};
