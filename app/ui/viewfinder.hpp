/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * viewfinder.hpp - live camera viewfinder surface.
 */

#pragma once

#include <QQuickFramebufferObject>
#include <QMutex>
#include <cstdint>

class Viewfinder : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int sourceWidth READ sourceWidth NOTIFY sourceSizeChanged)
    Q_PROPERTY(int sourceHeight READ sourceHeight NOTIFY sourceSizeChanged)

public:
    explicit Viewfinder(QQuickItem *parent = nullptr);
    ~Viewfinder() override;

    Renderer *createRenderer() const override;

    bool available() const { return available_; }
    int sourceWidth() const { return sourceWidth_; }
    int sourceHeight() const { return sourceHeight_; }

    struct FrameInfo {
        int fd = -1;
        unsigned int width = 0;
        unsigned int height = 0;
        unsigned int stride = 0;
        uint64_t frame = 0;
    };
    FrameInfo currentFrame() const;

public Q_SLOTS:
    void onFrameReady(int fd, unsigned int width, unsigned int height,
                      unsigned int stride, quint64 frame);

Q_SIGNALS:
    void availableChanged();
    void sourceSizeChanged();

private:
    mutable QMutex mutex_;
    FrameInfo currentFrame_;
    bool available_ = false;
    int sourceWidth_ = 0;
    int sourceHeight_ = 0;
};
