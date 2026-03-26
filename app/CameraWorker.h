#pragma once

#include <QThread>
#include <QMutex>
#include <QString>
#include <atomic>

class CinePIController;

class CameraWorker : public QThread
{
    Q_OBJECT

public:
    explicit CameraWorker(const QString &configDir, QObject *parent = nullptr);
    ~CameraWorker() override;

    void requestStop();

    CinePIController *controller() const { return controller_; }
    const QString &configDir() const { return m_configDir; }

Q_SIGNALS:
    void frameReady(int fd, unsigned int width, unsigned int height,
                    unsigned int stride, quint64 frame);
    void statsUpdate(float framerate, int colorTemp, float focus,
                     int frameCount, int bufferSize);
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
    CinePIController *controller_ = nullptr;
};
