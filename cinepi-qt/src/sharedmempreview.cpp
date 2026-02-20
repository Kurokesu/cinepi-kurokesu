#include "sharedmempreview.h"

#include <QDebug>

#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <signal.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>

#define PROJECT_ID 0x43494E45  // ASCII for "CINE" - must match cinepi-raw

SharedMemPreview::SharedMemPreview(QObject *parent)
    : QObject(parent)
{
    connect(&m_pollTimer, &QTimer::timeout, this, &SharedMemPreview::pollSharedMemory);
}

SharedMemPreview::~SharedMemPreview()
{
    stop();
}

void SharedMemPreview::start()
{
    if (!attachSharedMemory()) {
        qWarning() << "SharedMem: Failed to attach, will retry...";
    }

    // Poll at ~20fps for new frames (balances smoothness vs CPU on RPi5)
    m_pollTimer.start(50);
}

void SharedMemPreview::stop()
{
    m_pollTimer.stop();
    detachSharedMemory();
}

bool SharedMemPreview::attachSharedMemory()
{
    key_t key = ftok("/tmp", PROJECT_ID);
    if (key == -1) {
        qWarning() << "SharedMem: ftok failed";
        return false;
    }

    // Try to get existing shared memory segment (don't create new one)
    m_segmentId = shmget(key, sizeof(SharedMemoryBuffer), 0);
    if (m_segmentId == -1) {
        // Shared memory doesn't exist yet (cinepi-raw not running?)
        if (m_available) {
            m_available = false;
            emit availableChanged();
        }
        return false;
    }

    m_sharedData = (SharedMemoryBuffer *)shmat(m_segmentId, nullptr, SHM_RDONLY);
    if (m_sharedData == (void *)-1) {
        qWarning() << "SharedMem: shmat failed";
        m_sharedData = nullptr;
        if (m_available) {
            m_available = false;
            emit availableChanged();
        }
        return false;
    }

    if (!m_available) {
        m_available = true;
        emit availableChanged();
    }

    qDebug() << "SharedMem: Attached to shared memory, cinepi-raw PID:" << m_sharedData->procid;
    return true;
}

void SharedMemPreview::detachSharedMemory()
{
    if (m_sharedData) {
        shmdt(m_sharedData);
        m_sharedData = nullptr;
    }
    if (m_available) {
        m_available = false;
        emit availableChanged();
    }
}

void SharedMemPreview::pollSharedMemory()
{
    if (!m_sharedData) {
        // Try to attach
        attachSharedMemory();
        return;
    }

    // Check if cinepi-raw is still alive
    if (m_sharedData->procid > 0 && kill(m_sharedData->procid, 0) != 0) {
        qWarning() << "SharedMem: cinepi-raw process" << m_sharedData->procid << "not running";
        detachSharedMemory();
        return;
    }

    // Check for new frame
    if (m_sharedData->frame == m_lastFrame) {
        return;  // No new frame yet
    }

    m_lastFrame = m_sharedData->frame;

    // Update metadata
    bool metaChanged = false;
    if (m_exposureTime != m_sharedData->metadata.exposure_time) {
        m_exposureTime = m_sharedData->metadata.exposure_time;
        metaChanged = true;
    }
    if (m_analogueGain != m_sharedData->metadata.analogue_gain) {
        m_analogueGain = m_sharedData->metadata.analogue_gain;
        metaChanged = true;
    }
    if (m_colorTemp != m_sharedData->metadata.colorTemp) {
        m_colorTemp = m_sharedData->metadata.colorTemp;
        metaChanged = true;
    }
    if (qAbs(m_fps - m_sharedData->framerate) > 0.1f) {
        m_fps = m_sharedData->framerate;
        metaChanged = true;
    }
    if (metaChanged) {
        emit metadataChanged();
    }

    // Read the lores frame (low-resolution preview stream)
    // Falls back to ISP stream if lores is not available
    // The fd is in the cinepi-raw process space, so we access it via /proc/pid/fd/
    int pid = m_sharedData->procid;
    int fd, width, height, stride;
    size_t length;

    if (m_sharedData->fd_lores >= 0 && m_sharedData->lores.width > 0) {
        fd = m_sharedData->fd_lores;
        width = m_sharedData->lores.width;
        height = m_sharedData->lores.height;
        stride = m_sharedData->lores.stride;
        length = m_sharedData->lores_length;
    } else {
        fd = m_sharedData->fd_isp;
        width = m_sharedData->isp.width;
        height = m_sharedData->isp.height;
        stride = m_sharedData->isp.stride;
        length = m_sharedData->isp_length;
    }

    if (fd < 0 || width == 0 || height == 0 || length == 0) {
        return;  // No valid frame data
    }

    // Update frame size if changed
    if (width != m_frameWidth || height != m_frameHeight) {
        m_frameWidth = width;
        m_frameHeight = height;
        emit frameSizeChanged();
    }

    QImage frame = readFrameFromFd(pid, fd, width, height, stride, length);
    if (!frame.isNull()) {
        m_frameNumber++;
        emit frameReady(frame);
        emit frameUpdated();
    }
}

QImage SharedMemPreview::readFrameFromFd(int pid, int fd, int width, int height, int stride, size_t length)
{
    // Access the DMA-BUF fd from cinepi-raw's process via /proc/<pid>/fd/<fd>
    // This gives us a file descriptor we can mmap to read the frame data
    char fdPath[64];
    snprintf(fdPath, sizeof(fdPath), "/proc/%d/fd/%d", pid, fd);

    int localFd = open(fdPath, O_RDONLY);
    if (localFd < 0) {
        // This can fail if permissions are wrong or the fd is stale
        return QImage();
    }

    // Map the buffer into our address space
    void *data = mmap(nullptr, length, PROT_READ, MAP_SHARED, localFd, 0);
    close(localFd);

    if (data == MAP_FAILED) {
        return QImage();
    }

    // YUV420 (YU12/I420) -> RGB conversion using fixed-point integer math
    QImage result(width, height, QImage::Format_RGB888);

    const uint8_t *yPlane = (const uint8_t *)data;
    const int uvStride = stride / 2;
    const uint8_t *uPlane = yPlane + stride * height;
    const uint8_t *vPlane = uPlane + uvStride * (height / 2);

    for (int y = 0; y < height; y++) {
        const uint8_t *yRow = yPlane + y * stride;
        const uint8_t *uRow = uPlane + (y >> 1) * uvStride;
        const uint8_t *vRow = vPlane + (y >> 1) * uvStride;
        uint8_t *dest = result.scanLine(y);

        for (int x = 0; x < width; x++) {
            int Y = yRow[x];
            int U = uRow[x >> 1] - 128;
            int V = vRow[x >> 1] - 128;

            // Fixed-point: multiply by 256, shift right by 8
            int R = Y + ((359 * V) >> 8);
            int G = Y - ((88 * U + 183 * V) >> 8);
            int B = Y + ((454 * U) >> 8);

            dest[0] = (uint8_t)(R < 0 ? 0 : (R > 255 ? 255 : R));
            dest[1] = (uint8_t)(G < 0 ? 0 : (G > 255 ? 255 : G));
            dest[2] = (uint8_t)(B < 0 ? 0 : (B > 255 ? 255 : B));
            dest += 3;
        }
    }

    munmap(data, length);
    return result;
}
