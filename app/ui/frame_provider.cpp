/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * frame_provider.cpp - viewfinder frame provider.
 */

#include "frame_provider.hpp"
#include "logging.hpp"

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.frames");
    return l;
}

FrameProvider::FrameProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
    currentFrame_ = QImage(960, 540, QImage::Format_RGB888);
    currentFrame_.fill(QColor(30, 30, 30));
    logger()->debug("FrameProvider initialized (placeholder {}x{})",
               currentFrame_.width(), currentFrame_.height());
}

QImage FrameProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)
    QMutexLocker lock(&mutex_);

    if (size) {
        *size = currentFrame_.size();
    }

    if (requestedSize.isValid() && !requestedSize.isNull()) {
        return currentFrame_.scaled(requestedSize, Qt::KeepAspectRatio, Qt::FastTransformation);
    }

    return currentFrame_;
}

void FrameProvider::onNewFrame(const QImage &frame)
{
    if (frame.isNull()) return;

    {
        QMutexLocker lock(&mutex_);
        bool sizeChanged = (frame.size() != currentFrame_.size());
        currentFrame_ = frame;
        frameNumber_++;

        if (sizeChanged) {
            logger()->info("Frame size changed to {}x{}", frame.width(), frame.height());
            Q_EMIT frameSizeChanged();
        }
    }

    Q_EMIT frameNumberChanged();
}
