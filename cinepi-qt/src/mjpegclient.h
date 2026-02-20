#pragma once

#include <QObject>
#include <QImage>
#include <QTcpSocket>
#include <QTimer>
#include <QByteArray>
#include <QUrl>

/**
 * MjpegClient - Connects to the cinepi-raw MJPEG stream and extracts frames.
 *
 * The MJPEG stream is available at http://127.0.0.1:8000/stream as a
 * multipart/x-mixed-replace stream. Each part is a JPEG image.
 *
 * Emits frameReady(QImage) for each decoded frame.
 */
class MjpegClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(int frameCount READ frameCount NOTIFY frameCountChanged)

public:
    explicit MjpegClient(QObject *parent = nullptr);
    ~MjpegClient();

    Q_INVOKABLE void start(const QString &url = "http://127.0.0.1:8000/stream");
    Q_INVOKABLE void stop();

    bool isConnected() const { return m_connected; }
    int frameCount() const { return m_frameCount; }

signals:
    void frameReady(const QImage &frame);
    void connectedChanged();
    void frameCountChanged();
    void errorOccurred(const QString &error);

private slots:
    void onSocketConnected();
    void onSocketReadyRead();
    void onSocketDisconnected();
    void onSocketError();

private:
    void sendHttpRequest();
    void processBuffer();
    bool extractJpegFrame(const QByteArray &data, QImage &outImage);

    QTcpSocket *m_socket = nullptr;
    QByteArray m_buffer;
    QByteArray m_boundary;
    QString m_host;
    int m_port = 8000;
    QString m_path;
    bool m_connected = false;
    bool m_headerParsed = false;
    int m_frameCount = 0;
    bool m_running = false;
};
