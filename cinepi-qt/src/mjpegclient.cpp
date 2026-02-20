#include "mjpegclient.h"
#include <QDebug>
#include <QUrl>
#include <QTimer>

MjpegClient::MjpegClient(QObject *parent)
    : QObject(parent)
{
}

MjpegClient::~MjpegClient()
{
    stop();
}

void MjpegClient::start(const QString &urlStr)
{
    stop();

    QUrl url(urlStr);
    m_host = url.host();
    m_port = url.port(8000);
    m_path = url.path();
    if (m_path.isEmpty()) m_path = "/stream";

    m_running = true;
    m_headerParsed = false;
    m_buffer.clear();
    m_boundary.clear();
    m_frameCount = 0;

    m_socket = new QTcpSocket(this);
    connect(m_socket, &QTcpSocket::connected, this, &MjpegClient::onSocketConnected);
    connect(m_socket, &QTcpSocket::readyRead, this, &MjpegClient::onSocketReadyRead);
    connect(m_socket, &QTcpSocket::disconnected, this, &MjpegClient::onSocketDisconnected);
    connect(m_socket, &QTcpSocket::errorOccurred,
            this, &MjpegClient::onSocketError);

    qDebug() << "MJPEG: Connecting to" << m_host << ":" << m_port;
    m_socket->connectToHost(m_host, m_port);
}

void MjpegClient::stop()
{
    m_running = false;
    if (m_socket) {
        m_socket->disconnect();
        m_socket->abort();
        m_socket->deleteLater();
        m_socket = nullptr;
    }
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
}

void MjpegClient::onSocketConnected()
{
    qDebug() << "MJPEG: TCP connected, sending HTTP request";
    sendHttpRequest();
    m_connected = true;
    emit connectedChanged();
}

void MjpegClient::sendHttpRequest()
{
    QString request = QString("GET %1 HTTP/1.1\r\n"
                              "Host: %2:%3\r\n"
                              "Connection: keep-alive\r\n"
                              "\r\n")
                          .arg(m_path, m_host)
                          .arg(m_port);
    m_socket->write(request.toUtf8());
}

void MjpegClient::onSocketReadyRead()
{
    m_buffer.append(m_socket->readAll());
    processBuffer();
}

void MjpegClient::processBuffer()
{
    // First, parse HTTP headers to find the boundary string
    if (!m_headerParsed) {
        int headerEnd = m_buffer.indexOf("\r\n\r\n");
        if (headerEnd == -1) return; // Need more data

        QByteArray headers = m_buffer.left(headerEnd);
        m_buffer = m_buffer.mid(headerEnd + 4);

        // Find boundary from Content-Type header
        // Content-Type: multipart/x-mixed-replace;boundary=<boundary>
        int ctIdx = headers.indexOf("boundary=");
        if (ctIdx != -1) {
            int lineEnd = headers.indexOf("\r\n", ctIdx);
            if (lineEnd == -1) lineEnd = headers.size();
            m_boundary = headers.mid(ctIdx + 9, lineEnd - ctIdx - 9).trimmed();
        }

        if (m_boundary.isEmpty()) {
            // Default boundary used by nadjieb mjpeg streamer
            m_boundary = "myboundary";
        }

        m_headerParsed = true;
        qDebug() << "MJPEG: Headers parsed, boundary:" << m_boundary;
    }

    // Parse multipart frames
    // Format: --boundary\r\nContent-Type: image/jpeg\r\nContent-Length: NNN\r\n\r\n<jpeg data>
    QByteArray separator = "--" + m_boundary;

    while (true) {
        int sepIdx = m_buffer.indexOf(separator);
        if (sepIdx == -1) break;

        // Find the headers after the separator
        int headStart = sepIdx + separator.size();
        int headEnd = m_buffer.indexOf("\r\n\r\n", headStart);
        if (headEnd == -1) break; // Need more data

        // Parse Content-Length from part headers
        QByteArray partHeaders = m_buffer.mid(headStart, headEnd - headStart);
        int contentLength = -1;
        int clIdx = partHeaders.indexOf("Content-Length:");
        if (clIdx != -1) {
            int lineEnd = partHeaders.indexOf("\r\n", clIdx);
            if (lineEnd == -1) lineEnd = partHeaders.size();
            contentLength = partHeaders.mid(clIdx + 15, lineEnd - clIdx - 15).trimmed().toInt();
        }

        int dataStart = headEnd + 4;

        if (contentLength > 0) {
            // We know the exact length
            if (m_buffer.size() < dataStart + contentLength) break; // Need more data

            QByteArray jpegData = m_buffer.mid(dataStart, contentLength);
            m_buffer = m_buffer.mid(dataStart + contentLength);

            QImage frame;
            if (extractJpegFrame(jpegData, frame)) {
                m_frameCount++;
                emit frameReady(frame);
                if (m_frameCount % 100 == 0) {
                    emit frameCountChanged();
                }
            }
        } else {
            // No content-length; find the next boundary
            int nextSep = m_buffer.indexOf(separator, dataStart);
            if (nextSep == -1) break; // Need more data

            // Strip trailing \r\n before next boundary
            int dataEnd = nextSep;
            while (dataEnd > dataStart && (m_buffer[dataEnd - 1] == '\r' || m_buffer[dataEnd - 1] == '\n')) {
                dataEnd--;
            }

            QByteArray jpegData = m_buffer.mid(dataStart, dataEnd - dataStart);
            m_buffer = m_buffer.mid(nextSep);

            QImage frame;
            if (extractJpegFrame(jpegData, frame)) {
                m_frameCount++;
                emit frameReady(frame);
                if (m_frameCount % 100 == 0) {
                    emit frameCountChanged();
                }
            }
        }
    }

    // Prevent buffer from growing unbounded
    if (m_buffer.size() > 10 * 1024 * 1024) {
        qWarning() << "MJPEG: Buffer too large, trimming";
        int lastSep = m_buffer.lastIndexOf("--" + m_boundary);
        if (lastSep > 0) {
            m_buffer = m_buffer.mid(lastSep);
        } else {
            m_buffer.clear();
        }
    }
}

bool MjpegClient::extractJpegFrame(const QByteArray &data, QImage &outImage)
{
    if (data.isEmpty()) return false;

    // Verify JPEG magic bytes (FFD8)
    if (data.size() < 2 || (unsigned char)data[0] != 0xFF || (unsigned char)data[1] != 0xD8) {
        return false;
    }

    outImage = QImage::fromData(data, "JPEG");
    return !outImage.isNull();
}

void MjpegClient::onSocketDisconnected()
{
    qDebug() << "MJPEG: Disconnected";
    m_connected = false;
    emit connectedChanged();

    // Auto-reconnect after 2 seconds
    if (m_running) {
        QTimer::singleShot(2000, this, [this]() {
            if (m_running) {
                qDebug() << "MJPEG: Attempting reconnect...";
                start(QString("http://%1:%2%3").arg(m_host).arg(m_port).arg(m_path));
            }
        });
    }
}

void MjpegClient::onSocketError()
{
    if (m_socket) {
        QString err = m_socket->errorString();
        qWarning() << "MJPEG socket error:" << err;
        emit errorOccurred(err);
    }

    // Auto-reconnect on error
    if (m_running) {
        QTimer::singleShot(2000, this, [this]() {
            if (m_running) {
                start(QString("http://%1:%2%3").arg(m_host).arg(m_port).arg(m_path));
            }
        });
    }
}
