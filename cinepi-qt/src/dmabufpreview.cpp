#include "dmabufpreview.h"

#include <QDebug>
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>
#include <QQuickWindow>

#include <sys/syscall.h>
#include <sys/mman.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <cstring>
#include <cerrno>

#define PROJECT_ID 0x43494E45  // ASCII for "CINE"

// ─── Helper: get fd from another process via pidfd ───────────────────────────

static int getSharedProcFd(int procid, int fd)
{
    int pid_fd = syscall(SYS_pidfd_open, procid, 0);
    if (pid_fd == -1)
        return -1;
    int new_fd = syscall(SYS_pidfd_getfd, pid_fd, fd, 0);
    close(pid_fd);
    return new_fd;
}

// ─── Vertex/Fragment shaders (3-plane YUV420 → RGB) ─────────────────────────
// Uses standard GL_TEXTURE_2D — works on both desktop GL and GLES

static const char *vertexShaderSrc =
    "#version 100\n"
    "attribute vec2 aPos;\n"
    "attribute vec2 aTexCoord;\n"
    "varying vec2 vTexCoord;\n"
    "void main() {\n"
    "    gl_Position = vec4(aPos, 0.0, 1.0);\n"
    "    vTexCoord = aTexCoord;\n"
    "}\n";

static const char *fragmentShaderSrc =
    "#version 100\n"
    "precision mediump float;\n"
    "varying vec2 vTexCoord;\n"
    "uniform sampler2D texY;\n"
    "uniform sampler2D texU;\n"
    "uniform sampler2D texV;\n"
    "void main() {\n"
    "    float y = texture2D(texY, vTexCoord).r;\n"
    "    float u = texture2D(texU, vTexCoord).r - 0.5;\n"
    "    float v = texture2D(texV, vTexCoord).r - 0.5;\n"
    "    // BT.601 full-range YUV→RGB\n"
    "    float r = y + 1.402 * v;\n"
    "    float g = y - 0.344136 * u - 0.714136 * v;\n"
    "    float b = y + 1.772 * u;\n"
    "    gl_FragColor = vec4(r, g, b, 1.0);\n"
    "}\n";

// ─── Renderer ────────────────────────────────────────────────────────────────

class DmaBufRenderer : public QQuickFramebufferObject::Renderer, protected QOpenGLFunctions
{
public:
    DmaBufRenderer(const DmaBufPreview *item);
    ~DmaBufRenderer();

    void render() override;
    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override;
    void synchronize(QQuickFramebufferObject *item) override;

private:
    bool initGL();
    bool uploadFrame();
    void cleanup();
    GLuint compileShader(GLenum type, const char *source);

    const DmaBufPreview *m_item;

    // GL state
    bool m_glInitialized = false;
    bool m_glFailed = false;
    GLuint m_program = 0;
    GLuint m_vbo = 0;
    GLuint m_texY = 0, m_texU = 0, m_texV = 0;

    // Current frame info from the QML item
    DmaBufPreview::FrameInfo m_frameInfo;
    uint64_t m_lastRenderedFrame = 0;

    // Viewport
    QSize m_viewportSize;
};

DmaBufRenderer::DmaBufRenderer(const DmaBufPreview *item)
    : m_item(item)
{
}

DmaBufRenderer::~DmaBufRenderer()
{
    cleanup();
}

void DmaBufRenderer::cleanup()
{
    if (m_texY) { glDeleteTextures(1, &m_texY); m_texY = 0; }
    if (m_texU) { glDeleteTextures(1, &m_texU); m_texU = 0; }
    if (m_texV) { glDeleteTextures(1, &m_texV); m_texV = 0; }
    if (m_vbo) { glDeleteBuffers(1, &m_vbo); m_vbo = 0; }
    if (m_program) { glDeleteProgram(m_program); m_program = 0; }
}

GLuint DmaBufRenderer::compileShader(GLenum type, const char *source)
{
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);
    GLint ok;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char log[512];
        glGetShaderInfoLog(shader, sizeof(log), nullptr, log);
        qWarning() << "Shader compile error:" << log;
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

bool DmaBufRenderer::initGL()
{
    if (m_glInitialized)
        return true;
    if (m_glFailed)
        return false;

    initializeOpenGLFunctions();

    // Compile shader program
    GLuint vs = compileShader(GL_VERTEX_SHADER, vertexShaderSrc);
    GLuint fs = compileShader(GL_FRAGMENT_SHADER, fragmentShaderSrc);
    if (!vs || !fs) {
        if (vs) glDeleteShader(vs);
        if (fs) glDeleteShader(fs);
        m_glFailed = true;
        return false;
    }

    m_program = glCreateProgram();
    glAttachShader(m_program, vs);
    glAttachShader(m_program, fs);
    glBindAttribLocation(m_program, 0, "aPos");
    glBindAttribLocation(m_program, 1, "aTexCoord");
    glLinkProgram(m_program);
    glDeleteShader(vs);
    glDeleteShader(fs);

    GLint ok;
    glGetProgramiv(m_program, GL_LINK_STATUS, &ok);
    if (!ok) {
        char log[512];
        glGetProgramInfoLog(m_program, sizeof(log), nullptr, log);
        qWarning() << "Program link error:" << log;
        glDeleteProgram(m_program);
        m_program = 0;
        m_glFailed = true;
        return false;
    }

    // Fullscreen quad (position + texcoord)
    // Y-flip for Qt's FBO coordinate system
    static const float quadVerts[] = {
        -1.f, -1.f,   0.f, 1.f,
         1.f, -1.f,   1.f, 1.f,
        -1.f,  1.f,   0.f, 0.f,
         1.f, -1.f,   1.f, 1.f,
         1.f,  1.f,   1.f, 0.f,
        -1.f,  1.f,   0.f, 0.f,
    };

    glGenBuffers(1, &m_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(quadVerts), quadVerts, GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    // Create Y/U/V textures (single-channel R8)
    auto createTex = [this]() -> GLuint {
        GLuint tex;
        glGenTextures(1, &tex);
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glBindTexture(GL_TEXTURE_2D, 0);
        return tex;
    };
    m_texY = createTex();
    m_texU = createTex();
    m_texV = createTex();

    m_glInitialized = true;
    qDebug() << "DmaBufRenderer: GL initialized (3-plane YUV shader)";
    return true;
}

bool DmaBufRenderer::uploadFrame()
{
    if (m_frameInfo.fd < 0 || m_frameInfo.width == 0 || m_frameInfo.height == 0)
        return false;

    // Get a local fd to the DMA-BUF via pidfd
    int localFd = getSharedProcFd(m_frameInfo.pid, m_frameInfo.fd);
    if (localFd < 0)
        return false;

    // Calculate buffer size for YUV420
    int w = m_frameInfo.width;
    int h = m_frameInfo.height;
    int stride = m_frameInfo.stride;
    size_t ySize = stride * h;
    size_t uvStride = stride / 2;
    size_t uvHeight = h / 2;
    size_t totalSize = ySize + 2 * (uvStride * uvHeight);

    // Map the DMA-BUF into our address space
    void *data = mmap(nullptr, totalSize, PROT_READ, MAP_SHARED, localFd, 0);
    close(localFd);

    if (data == MAP_FAILED)
        return false;

    const uint8_t *yPlane = (const uint8_t *)data;
    const uint8_t *uPlane = yPlane + ySize;
    const uint8_t *vPlane = uPlane + uvStride * uvHeight;

    // Upload Y plane
    glBindTexture(GL_TEXTURE_2D, m_texY);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, stride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yPlane);

    // Upload U plane
    glBindTexture(GL_TEXTURE_2D, m_texU);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, uvStride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w / 2, h / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, uPlane);

    // Upload V plane
    glBindTexture(GL_TEXTURE_2D, m_texV);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, uvStride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w / 2, h / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, vPlane);

    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glBindTexture(GL_TEXTURE_2D, 0);

    munmap(data, totalSize);
    return true;
}

void DmaBufRenderer::synchronize(QQuickFramebufferObject *item)
{
    auto *preview = static_cast<DmaBufPreview *>(item);
    m_frameInfo = preview->currentFrame();
    m_viewportSize = QSize(item->width(), item->height());
}

QOpenGLFramebufferObject *DmaBufRenderer::createFramebufferObject(const QSize &size)
{
    return new QOpenGLFramebufferObject(size);
}

void DmaBufRenderer::render()
{
    if (!initGL())
        return;

    if (m_frameInfo.frame == m_lastRenderedFrame)
        return;  // No new frame

    if (!uploadFrame())
        return;

    m_lastRenderedFrame = m_frameInfo.frame;

    // Calculate aspect-preserving crop viewport (fill the FBO, crop sides)
    int fboW = m_viewportSize.width();
    int fboH = m_viewportSize.height();
    float srcAspect = (float)m_frameInfo.width / m_frameInfo.height;
    float dstAspect = (float)fboW / fboH;

    int vpX = 0, vpY = 0, vpW = fboW, vpH = fboH;
    if (srcAspect > dstAspect) {
        // Source wider — crop left/right
        vpW = (int)(fboH * srcAspect);
        vpX = (fboW - vpW) / 2;
    } else {
        // Source taller — crop top/bottom
        vpH = (int)(fboW / srcAspect);
        vpY = (fboH - vpH) / 2;
    }

    // Clear to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);

    glViewport(vpX, vpY, vpW, vpH);

    // Draw
    glUseProgram(m_program);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_texY);
    glUniform1i(glGetUniformLocation(m_program, "texY"), 0);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, m_texU);
    glUniform1i(glGetUniformLocation(m_program, "texU"), 1);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, m_texV);
    glUniform1i(glGetUniformLocation(m_program, "texV"), 2);

    glBindBuffer(GL_ARRAY_BUFFER, m_vbo);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void *)0);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float), (void *)(2 * sizeof(float)));

    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);

    // Reset viewport
    glViewport(0, 0, fboW, fboH);

    // Request continuous updates
    update();
}

// ─── DmaBufPreview (QML item) ────────────────────────────────────────────────

DmaBufPreview::DmaBufPreview(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
{
    setMirrorVertically(true);
    setTextureFollowsItemSize(true);

    connect(&m_pollTimer, &QTimer::timeout, this, &DmaBufPreview::pollSharedMemory);
    m_pollTimer.start(16);  // ~60fps polling
}

DmaBufPreview::~DmaBufPreview()
{
    m_pollTimer.stop();
    detachSharedMemory();
}

QQuickFramebufferObject::Renderer *DmaBufPreview::createRenderer() const
{
    return new DmaBufRenderer(this);
}

bool DmaBufPreview::attachSharedMemory()
{
    key_t key = ftok("/tmp", PROJECT_ID);
    if (key == -1)
        return false;

    m_segmentId = shmget(key, sizeof(ShmBuffer), 0);
    if (m_segmentId == -1) {
        static bool logged = false;
        if (!logged) {
            logged = true;
            qWarning() << "DmaBufPreview: no shared memory segment (shmget failed, errno:" << errno
                       << "- is cinepi-raw running and past OpenCamera()?)";
        }
        if (m_available) {
            m_available = false;
            emit availableChanged();
        }
        return false;
    }

    m_sharedData = (ShmBuffer *)shmat(m_segmentId, nullptr, SHM_RDONLY);
    if (m_sharedData == (void *)-1) {
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

    qDebug() << "DmaBufPreview: Attached, cinepi-raw PID:" << m_sharedData->procid;
    return true;
}

void DmaBufPreview::detachSharedMemory()
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

void DmaBufPreview::pollSharedMemory()
{
    if (!m_sharedData) {
        attachSharedMemory();
        return;
    }

    // Check cinepi-raw is alive
    if (m_sharedData->procid > 0 && kill(m_sharedData->procid, 0) != 0) {
        qWarning() << "DmaBufPreview: cinepi-raw not running";
        detachSharedMemory();
        m_currentFrame = FrameInfo{};
        return;
    }

    // Check for new frame
    if (m_sharedData->frame == m_lastFrame)
        return;
    m_lastFrame = m_sharedData->frame;

    // Prefer lores stream (smaller upload, lower CPU) when available; else use ISP
    int fd;
    unsigned int w, h, s;
    if (m_sharedData->fd_lores >= 0 && m_sharedData->lores.width > 0) {
        fd = m_sharedData->fd_lores;
        w = m_sharedData->lores.width;
        h = m_sharedData->lores.height;
        s = m_sharedData->lores.stride;
    } else {
        fd = m_sharedData->fd_isp;
        w = m_sharedData->isp.width;
        h = m_sharedData->isp.height;
        s = m_sharedData->isp.stride;
    }

    if (fd < 0 || w == 0 || h == 0)
        return;

    // Update frame info for the renderer
    m_currentFrame.pid = m_sharedData->procid;
    m_currentFrame.fd = fd;
    m_currentFrame.width = w;
    m_currentFrame.height = h;
    m_currentFrame.stride = s;
    m_currentFrame.frame = m_sharedData->frame;

    // Update source size
    if ((int)w != m_sourceWidth || (int)h != m_sourceHeight) {
        m_sourceWidth = w;
        m_sourceHeight = h;
        emit sourceSizeChanged();
        qDebug() << "DmaBufPreview: stream" << w << "x" << h << "stride" << s;
    }

    // Update FPS
    if (qAbs(m_fps - m_sharedData->framerate) > 0.1f) {
        m_fps = m_sharedData->framerate;
        emit metadataChanged();
    }

    // Trigger redraw
    update();
}
