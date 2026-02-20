#pragma once

#include <QObject>
#include <QImage>
#include <QTimer>
#include <QSize>
#include <cstdint>

/**
 * SharedMemPreview - Zero-copy camera preview via POSIX shared memory.
 *
 * cinepi-raw writes camera frame file descriptors and metadata to a shared
 * memory segment created with ftok("/tmp", 0x43494E45). The struct layout
 * matches SharedMemoryBuffer from cinepi-raw/cinepi/sharedContextStage.cpp.
 *
 * This class reads the shared memory to get frame metadata and DMA-BUF fds,
 * then uses /proc/<pid>/fd/<fd> to mmap the actual frame data for display.
 *
 * For Qt Quick integration, frames are converted to QImage and provided to
 * the FrameProvider. A future version could use EGL image import for true
 * zero-copy GPU rendering.
 */

// Must match cinepi-raw's StreamInfo struct (total 56 bytes, 8-byte aligned)
// Layout: width(4) height(4) stride(4) pad(4) pixel_format(16) colour_space(20) pad(4)
struct alignas(8) ShmStreamInfo {
    unsigned int width;
    unsigned int height;
    unsigned int stride;
    uint32_t _pad0;             // alignment padding before pixel_format
    char pixel_format[16];      // libcamera::PixelFormat (8-byte aligned, 16 bytes)
    char colour_space[20];      // std::optional<libcamera::ColorSpace> (4-byte aligned, 20 bytes)
    uint32_t _pad1;             // tail padding to reach 56 bytes
};

// Must match cinepi-raw's SharedMetadata struct
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

// Must match cinepi-raw's SharedMemoryBuffer struct
struct SharedMemoryBuffer {
    int fd_raw;
    int fd_isp;
    int fd_lores;
    ShmStreamInfo raw;
    ShmStreamInfo isp;
    ShmStreamInfo lores;
    size_t raw_length;
    size_t isp_length;
    size_t lores_length;
    int procid;         // PID of cinepi-raw process
    uint64_t frame;
    uint64_t ts;
    ShmMetadata metadata;
    unsigned int sequence;
    float framerate;
    uint8_t stats[23200];
};

class SharedMemPreview : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(int frameWidth READ frameWidth NOTIFY frameSizeChanged)
    Q_PROPERTY(int frameHeight READ frameHeight NOTIFY frameSizeChanged)
    Q_PROPERTY(float exposureTime READ exposureTime NOTIFY metadataChanged)
    Q_PROPERTY(float analogueGain READ analogueGain NOTIFY metadataChanged)
    Q_PROPERTY(float fps READ fps NOTIFY metadataChanged)
    Q_PROPERTY(unsigned int colorTemp READ colorTemp NOTIFY metadataChanged)
    Q_PROPERTY(int frameNumber READ frameNumber NOTIFY frameUpdated)

public:
    explicit SharedMemPreview(QObject *parent = nullptr);
    ~SharedMemPreview();

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();

    bool available() const { return m_available; }
    int frameWidth() const { return m_frameWidth; }
    int frameHeight() const { return m_frameHeight; }
    float exposureTime() const { return m_exposureTime; }
    float analogueGain() const { return m_analogueGain; }
    float fps() const { return m_fps; }
    unsigned int colorTemp() const { return m_colorTemp; }
    int frameNumber() const { return m_frameNumber; }

signals:
    void frameReady(const QImage &frame);
    void availableChanged();
    void frameSizeChanged();
    void metadataChanged();
    void frameUpdated();

private slots:
    void pollSharedMemory();

private:
    bool attachSharedMemory();
    void detachSharedMemory();
    QImage readFrameFromFd(int pid, int fd, int width, int height, int stride, size_t length);

    QTimer m_pollTimer;
    SharedMemoryBuffer *m_sharedData = nullptr;
    int m_segmentId = -1;
    bool m_available = false;
    uint64_t m_lastFrame = 0;

    int m_frameWidth = 0;
    int m_frameHeight = 0;
    float m_exposureTime = 0;
    float m_analogueGain = 0;
    float m_fps = 0;
    unsigned int m_colorTemp = 0;
    int m_frameNumber = 0;
};
