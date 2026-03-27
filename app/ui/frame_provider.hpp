#pragma once

#include <QObject>
#include <QImage>
#include <QQuickImageProvider>
#include <QMutex>

class FrameProvider : public QQuickImageProvider
{
    Q_OBJECT
    Q_PROPERTY(int frameWidth READ frameWidth NOTIFY frameSizeChanged)
    Q_PROPERTY(int frameHeight READ frameHeight NOTIFY frameSizeChanged)
    Q_PROPERTY(int frameNumber READ frameNumber NOTIFY frameNumberChanged)

public:
    explicit FrameProvider();

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

    int frameWidth() const { return currentFrame_.width(); }
    int frameHeight() const { return currentFrame_.height(); }
    int frameNumber() const { return frameNumber_; }

public Q_SLOTS:
    void onNewFrame(const QImage &frame);

Q_SIGNALS:
    void frameNumberChanged();
    void frameSizeChanged();

private:
    QImage currentFrame_;
    QMutex mutex_;
    int frameNumber_ = 0;
};
