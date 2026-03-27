#include "dmabuf_viewfinder.hpp"
#include "logging.hpp"

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
    DmaBufRenderer(const DmaBufViewfinder *item);
    ~DmaBufRenderer();

    void render() override;
    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override;
    void synchronize(QQuickFramebufferObject *item) override;

private:
    bool initGL();
    bool uploadFrame();
    void cleanup();
    GLuint compileShader(GLenum type, const char *source);

    const DmaBufViewfinder *item_;

    bool glInitialized_ = false;
    bool glFailed_ = false;
    GLuint program_ = 0;
    GLuint vbo_ = 0;
    GLuint texY_ = 0, texU_ = 0, texV_ = 0;

    DmaBufViewfinder::FrameInfo frameInfo_;
    uint64_t lastRenderedFrame_ = 0;
    QSize viewportSize_;
};

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.viewfinder");
    return l;
}

DmaBufRenderer::DmaBufRenderer(const DmaBufViewfinder *item)
    : item_(item) {}

DmaBufRenderer::~DmaBufRenderer() { cleanup(); }

void DmaBufRenderer::cleanup()
{
    if (texY_) { glDeleteTextures(1, &texY_); texY_ = 0; }
    if (texU_) { glDeleteTextures(1, &texU_); texU_ = 0; }
    if (texV_) { glDeleteTextures(1, &texV_); texV_ = 0; }
    if (vbo_) { glDeleteBuffers(1, &vbo_); vbo_ = 0; }
    if (program_) { glDeleteProgram(program_); program_ = 0; }
}

GLuint DmaBufRenderer::compileShader(GLenum type, const char *source)
{
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 1, &source, nullptr);
    glCompileShader(shader);
    GLint ok;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (!ok) {
        char buf[512];
        glGetShaderInfoLog(shader, sizeof(buf), nullptr, buf);
        cinepi::getLogger("ui.viewfinder")->error("Shader compile error: {}", buf);
        glDeleteShader(shader);
        return 0;
    }
    return shader;
}

bool DmaBufRenderer::initGL()
{
    if (glInitialized_) return true;
    if (glFailed_) return false;

    initializeOpenGLFunctions();

    GLuint vs = compileShader(GL_VERTEX_SHADER, vertexShaderSrc);
    GLuint fs = compileShader(GL_FRAGMENT_SHADER, fragmentShaderSrc);
    if (!vs || !fs) {
        if (vs) glDeleteShader(vs);
        if (fs) glDeleteShader(fs);
        glFailed_ = true;
        return false;
    }

    program_ = glCreateProgram();
    glAttachShader(program_, vs);
    glAttachShader(program_, fs);
    glBindAttribLocation(program_, 0, "aPos");
    glBindAttribLocation(program_, 1, "aTexCoord");
    glLinkProgram(program_);
    glDeleteShader(vs);
    glDeleteShader(fs);

    GLint ok;
    glGetProgramiv(program_, GL_LINK_STATUS, &ok);
    if (!ok) {
        char buf[512];
        glGetProgramInfoLog(program_, sizeof(buf), nullptr, buf);
        cinepi::getLogger("ui.viewfinder")->error("Program link error: {}", buf);
        glDeleteProgram(program_);
        program_ = 0;
        glFailed_ = true;
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

    glGenBuffers(1, &vbo_);
    glBindBuffer(GL_ARRAY_BUFFER, vbo_);
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
    texY_ = createTex();
    texU_ = createTex();
    texV_ = createTex();

    glInitialized_ = true;
    logger()->debug("GL initialized");
    return true;
}

bool DmaBufRenderer::uploadFrame()
{
    if (frameInfo_.fd < 0 || frameInfo_.width == 0 || frameInfo_.height == 0)
        return false;

    int w = frameInfo_.width;
    int h = frameInfo_.height;
    int stride = frameInfo_.stride;
    size_t ySize = stride * h;
    size_t uvStride = stride / 2;
    size_t uvHeight = h / 2;
    size_t totalSize = ySize + 2 * (uvStride * uvHeight);

    void *data = mmap(nullptr, totalSize, PROT_READ, MAP_SHARED,
                      frameInfo_.fd, 0);
    if (data == MAP_FAILED) {
        logger()->warn("mmap failed for viewfinder frame (fd={}, size={})", frameInfo_.fd, totalSize);
        return false;
    }

    const uint8_t *yPlane = (const uint8_t *)data;
    const uint8_t *uPlane = yPlane + ySize;
    const uint8_t *vPlane = uPlane + uvStride * uvHeight;

    glBindTexture(GL_TEXTURE_2D, texY_);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, stride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w, h, 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE, yPlane);

    glBindTexture(GL_TEXTURE_2D, texU_);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, uvStride);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, w / 2, h / 2, 0,
                 GL_LUMINANCE, GL_UNSIGNED_BYTE, uPlane);

    glBindTexture(GL_TEXTURE_2D, texV_);
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
    auto *viewfinder = static_cast<DmaBufViewfinder *>(item);
    frameInfo_ = viewfinder->currentFrame();
    viewportSize_ = QSize(item->width(), item->height());
}

QOpenGLFramebufferObject *DmaBufRenderer::createFramebufferObject(const QSize &size)
{
    return new QOpenGLFramebufferObject(size);
}

void DmaBufRenderer::render()
{
    if (!initGL())
        return;

    if (frameInfo_.frame == lastRenderedFrame_)
        return;

    if (!uploadFrame())
        return;

    lastRenderedFrame_ = frameInfo_.frame;

    int fboW = viewportSize_.width();
    int fboH = viewportSize_.height();
    float srcAspect = (float)frameInfo_.width / frameInfo_.height;
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

    glUseProgram(program_);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texY_);
    glUniform1i(glGetUniformLocation(program_, "texY"), 0);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texU_);
    glUniform1i(glGetUniformLocation(program_, "texU"), 1);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, texV_);
    glUniform1i(glGetUniformLocation(program_, "texV"), 2);

    glBindBuffer(GL_ARRAY_BUFFER, vbo_);
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

DmaBufViewfinder::DmaBufViewfinder(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
{
    setMirrorVertically(true);
    setTextureFollowsItemSize(true);
}

DmaBufViewfinder::~DmaBufViewfinder() = default;

QQuickFramebufferObject::Renderer *DmaBufViewfinder::createRenderer() const
{
    return new DmaBufRenderer(this);
}

DmaBufViewfinder::FrameInfo DmaBufViewfinder::currentFrame() const
{
    QMutexLocker lock(&mutex_);
    return currentFrame_;
}

void DmaBufViewfinder::onFrameReady(int fd, unsigned int width,
                                  unsigned int height, unsigned int stride,
                                  quint64 frame)
{
    {
        QMutexLocker lock(&mutex_);
        currentFrame_.fd = fd;
        currentFrame_.width = width;
        currentFrame_.height = height;
        currentFrame_.stride = stride;
        currentFrame_.frame = frame;
    }

    if (!available_) {
        available_ = true;
        Q_EMIT availableChanged();
    }

    if ((int)width != sourceWidth_ || (int)height != sourceHeight_) {
        sourceWidth_ = width;
        sourceHeight_ = height;
        Q_EMIT sourceSizeChanged();
    }

    update();
}
