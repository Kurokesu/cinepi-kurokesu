#include "DmaBufPreview.h"

#include <QDebug>
#include <QOpenGLFramebufferObject>
#include <QOpenGLFunctions>
#include <QQuickWindow>

#include <sys/mman.h>
#include <unistd.h>
#include <cstring>

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
    "    float r = y + 1.402 * v;\n"
    "    float g = y - 0.344136 * u - 0.714136 * v;\n"
    "    float b = y + 1.772 * u;\n"
    "    gl_FragColor = vec4(r, g, b, 1.0);\n"
    "}\n";

class DmaBufRenderer : public QQuickFramebufferObject::Renderer,
                       protected QOpenGLFunctions
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

    bool m_glInitialized = false;
    bool m_glFailed = false;
    GLuint m_program = 0;
    GLuint m_vbo = 0;
    GLuint m_texY = 0, m_texU = 0, m_texV = 0;

    DmaBufPreview::FrameInfo m_frameInfo;
    uint64_t m_lastRenderedFrame = 0;
    QSize m_viewportSize;
};

DmaBufRenderer::DmaBufRenderer(const DmaBufPreview *item)
    : m_item(item) {}

DmaBufRenderer::~DmaBufRenderer() { cleanup(); }

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
    if (m_glInitialized) return true;
    if (m_glFailed) return false;

    initializeOpenGLFunctions();

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
    qDebug() << "DmaBufRenderer: GL initialized";
    return true;
}

bool DmaBufRenderer::uploadFrame()
{
    if (m_frameInfo.fd < 0 || m_frameInfo.width == 0 || m_frameInfo.height == 0)
        return false;

    int w = m_frameInfo.width;
    int h = m_frameInfo.height;
    int stride = m_frameInfo.stride;
    size_t ySize = stride * h;
    size_t uvStride = stride / 2;
    size_t uvHeight = h / 2;
    size_t totalSize = ySize + 2 * (uvStride * uvHeight);

    void *data = mmap(nullptr, totalSize, PROT_READ, MAP_SHARED,
                      m_frameInfo.fd, 0);
    if (data == MAP_FAILED)
        return false;

    const uint8_t *yPlane = (const uint8_t *)data;
    const uint8_t *uPlane = yPlane + ySize;
    const uint8_t *vPlane = uPlane + uvStride * uvHeight;

    glBindTexture(GL_TEXTURE_2D, m_texY);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, stride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE, yPlane);

    glBindTexture(GL_TEXTURE_2D, m_texU);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, uvStride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w / 2, h / 2, 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE, uPlane);

    glBindTexture(GL_TEXTURE_2D, m_texV);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, uvStride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w / 2, h / 2, 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE, vPlane);

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
        return;

    if (!uploadFrame())
        return;

    m_lastRenderedFrame = m_frameInfo.frame;

    int fboW = m_viewportSize.width();
    int fboH = m_viewportSize.height();
    float srcAspect = (float)m_frameInfo.width / m_frameInfo.height;
    float dstAspect = (float)fboW / fboH;

    int vpX = 0, vpY = 0, vpW = fboW, vpH = fboH;
    if (srcAspect > dstAspect) {
        vpW = (int)(fboH * srcAspect);
        vpX = (fboW - vpW) / 2;
    } else {
        vpH = (int)(fboW / srcAspect);
        vpY = (fboH - vpH) / 2;
    }

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport(vpX, vpY, vpW, vpH);

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
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(float),
                          (void *)(2 * sizeof(float)));

    glDrawArrays(GL_TRIANGLES, 0, 6);

    glDisableVertexAttribArray(0);
    glDisableVertexAttribArray(1);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    glViewport(0, 0, fboW, fboH);

    update();
}

// ─── DmaBufPreview (QML item) ────────────────────────────────────────────────

DmaBufPreview::DmaBufPreview(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
{
    setMirrorVertically(true);
    setTextureFollowsItemSize(true);
}

DmaBufPreview::~DmaBufPreview() = default;

QQuickFramebufferObject::Renderer *DmaBufPreview::createRenderer() const
{
    return new DmaBufRenderer(this);
}

DmaBufPreview::FrameInfo DmaBufPreview::currentFrame() const
{
    QMutexLocker lock(&m_mutex);
    return m_currentFrame;
}

void DmaBufPreview::onFrameReady(int fd, unsigned int width,
                                  unsigned int height, unsigned int stride,
                                  quint64 frame)
{
    {
        QMutexLocker lock(&m_mutex);
        m_currentFrame.fd = fd;
        m_currentFrame.width = width;
        m_currentFrame.height = height;
        m_currentFrame.stride = stride;
        m_currentFrame.frame = frame;
    }

    if (!m_available) {
        m_available = true;
        Q_EMIT availableChanged();
    }

    if ((int)width != m_sourceWidth || (int)height != m_sourceHeight) {
        m_sourceWidth = width;
        m_sourceHeight = height;
        Q_EMIT sourceSizeChanged();
    }

    update();
}
