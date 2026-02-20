#pragma once

#include <QQuickFramebufferObject>
#include <QTimer>
#include <cstdint>
#include <sys/ipc.h>
#include <sys/shm.h>

/**
 * DmaBufPreview - Zero-copy camera preview via EGL DMA-BUF import.
 *
 * Reads the ISP stream's DMA-BUF file descriptor from cinepi-raw's shared
 * memory segment and imports it as an EGL image / GL texture on the GPU.
 * The GPU handles YUV→RGB conversion and scaling — zero CPU cost for preview.
 *
 * This matches the approach used by the original ALTCINECAM (cinepi-gui).
 */

// Shared memory structs — must match cinepi-raw's sharedContextStage.cpp
// Note: these use libcamera types for pixel_format and colour_space fields
struct alignas(8) ShmStreamInfo {
    unsigned int width;
    unsigned int height;
    unsigned int stride;
    uint32_t _pad0;
    char pixel_format[16];
    char colour_space[20];
    uint32_t _pad1;
};

struct ShmMetadata {
    float exposure_time;
    float analogue_gain;
    float digital_gain;
    unsigned int colorTemp;
    int64_t ts;
    float colour_gains[2];
    float focus;
    float fps;
    bool aelock;
    float lens_position;
    int af_state;
};

struct ShmBuffer {
    int fd_raw;
    int fd_isp;
    int fd_lores;
    ShmStreamInfo raw;
    ShmStreamInfo isp;
    ShmStreamInfo lores;
    size_t raw_length;
    size_t isp_length;
    size_t lores_length;
    int procid;
    uint64_t frame;
    uint64_t ts;
    ShmMetadata metadata;
    unsigned int sequence;
    float framerate;
    uint8_t stats[23200];
};

class DmaBufPreview : public QQuickFramebufferObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int sourceWidth READ sourceWidth NOTIFY sourceSizeChanged)
    Q_PROPERTY(int sourceHeight READ sourceHeight NOTIFY sourceSizeChanged)
    Q_PROPERTY(float fps READ fps NOTIFY metadataChanged)

public:
    explicit DmaBufPreview(QQuickItem *parent = nullptr);
    ~DmaBufPreview() override;

    Renderer *createRenderer() const override;

    bool available() const { return m_available; }
    int sourceWidth() const { return m_sourceWidth; }
    int sourceHeight() const { return m_sourceHeight; }
    float fps() const { return m_fps; }

    // Called by renderer to get current frame info
    struct FrameInfo {
        int pid = -1;
        int fd = -1;
        unsigned int width = 0;
        unsigned int height = 0;
        unsigned int stride = 0;
        uint64_t frame = 0;
    };
    FrameInfo currentFrame() const { return m_currentFrame; }

signals:
    void availableChanged();
    void sourceSizeChanged();
    void metadataChanged();

private slots:
    void pollSharedMemory();

private:
    bool attachSharedMemory();
    void detachSharedMemory();

    QTimer m_pollTimer;
    ShmBuffer *m_sharedData = nullptr;
    int m_segmentId = -1;
    bool m_available = false;
    uint64_t m_lastFrame = 0;

    int m_sourceWidth = 0;
    int m_sourceHeight = 0;
    float m_fps = 0;

    FrameInfo m_currentFrame;
};
