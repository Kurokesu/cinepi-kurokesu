#pragma once

#include <QObject>
#include <QImage>
#include <QQuickImageProvider>
#include <QMutex>

/**
 * FrameProvider - Bridges MJPEG frames to QML Image elements.
 *
 * Acts as a QQuickImageProvider so QML can display frames via:
 *   Image { source: "image://frames/latest" }
 *
 * Also exposes a frameUpdated signal that QML can use to trigger repaints.
 */
class FrameProvider : public QQuickImageProvider
{
    Q_OBJECT
    Q_PROPERTY(int frameWidth READ frameWidth NOTIFY frameSizeChanged)
    Q_PROPERTY(int frameHeight READ frameHeight NOTIFY frameSizeChanged)
    Q_PROPERTY(int frameNumber READ frameNumber NOTIFY frameUpdated)

public:
    explicit FrameProvider();

    // QQuickImageProvider interface
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

    int frameWidth() const { return m_currentFrame.width(); }
    int frameHeight() const { return m_currentFrame.height(); }
    int frameNumber() const { return m_frameNumber; }

public slots:
    void onNewFrame(const QImage &frame);

signals:
    void frameUpdated();
    void frameSizeChanged();

private:
    QImage m_currentFrame;
    QMutex m_mutex;
    int m_frameNumber = 0;
};
