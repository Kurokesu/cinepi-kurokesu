#include "frameprovider.h"
#include <QDebug>

FrameProvider::FrameProvider(QObject *parent)
    : QObject(parent)
    , QQuickImageProvider(QQuickImageProvider::Image)
{
    // Create a placeholder frame (dark grey)
    m_currentFrame = QImage(960, 540, QImage::Format_RGB888);
    m_currentFrame.fill(QColor(30, 30, 30));
}

QImage FrameProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)
    QMutexLocker lock(&m_mutex);

    if (size) {
        *size = m_currentFrame.size();
    }

    if (requestedSize.isValid() && !requestedSize.isNull()) {
        return m_currentFrame.scaled(requestedSize, Qt::KeepAspectRatio, Qt::FastTransformation);
    }

    return m_currentFrame;
}

void FrameProvider::onNewFrame(const QImage &frame)
{
    if (frame.isNull()) return;

    {
        QMutexLocker lock(&m_mutex);
        bool sizeChanged = (frame.size() != m_currentFrame.size());
        m_currentFrame = frame;
        m_frameNumber++;

        if (sizeChanged) {
            emit frameSizeChanged();
        }
    }

    emit frameUpdated();
}
