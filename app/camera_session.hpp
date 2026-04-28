/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * camera_session.hpp - preview, recording and controls.
 */

#pragma once

#include <QThread>
#include <QString>
#include <atomic>
#include <condition_variable>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

class CameraSession : public QThread
{
    Q_OBJECT

public:
    enum class State { Paused, Running, Stopped };

    explicit CameraSession(const QString &configDir, QObject *parent = nullptr);
    ~CameraSession() override;

    void pause();
    void resume();
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
    void sessionPaused();
    void sessionResumed();

public Q_SLOTS:
    void handleControl(const QString &key, const QString &value);

protected:
    void run() override;

private:
    QString configDir_;

    std::mutex stateMutex_;
    std::condition_variable stateCV_;
    std::atomic<State> state_{State::Paused};

    std::mutex controlMutex_;
    std::vector<std::pair<std::string, std::string>> pendingControls_;

    int isoGain_ = 8;
    int shutterAngle_ = 180;
    int fps_ = 24;
    int colorTemp_ = 0;
};
