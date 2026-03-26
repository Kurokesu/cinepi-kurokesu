#pragma once

#include <QQuickFramebufferObject>
#include <QMutex>
#include <cstdint>

class DmaBufPreview : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int sourceWidth READ sourceWidth NOTIFY sourceSizeChanged)
    Q_PROPERTY(int sourceHeight READ sourceHeight NOTIFY sourceSizeChanged)

public:
    explicit DmaBufPreview(QQuickItem *parent = nullptr);
    ~DmaBufPreview() override;

    Renderer *createRenderer() const override;

    bool available() const { return m_available; }
    int sourceWidth() const { return m_sourceWidth; }
    int sourceHeight() const { return m_sourceHeight; }

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
    mutable QMutex m_mutex;
    FrameInfo m_currentFrame;
    bool m_available = false;
    int m_sourceWidth = 0;
    int m_sourceHeight = 0;
};
