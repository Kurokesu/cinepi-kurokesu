#include "redisbridge.h"
#include <QDebug>

RedisBridge::RedisBridge(QObject *parent)
    : QObject(parent)
{
    connectToRedis();

    // Poll Redis every 100ms for updated values
    connect(&m_pollTimer, &QTimer::timeout, this, &RedisBridge::pollRedis);
    m_pollTimer.start(100);
}

RedisBridge::~RedisBridge()
{
    m_pollTimer.stop();
    disconnectRedis();
}

void RedisBridge::connectToRedis()
{
    if (m_ctx) {
        disconnectRedis();
    }

    struct timeval timeout = { 1, 500000 }; // 1.5 seconds
    m_ctx = redisConnectWithTimeout("127.0.0.1", 6379, timeout);

    if (m_ctx == nullptr || m_ctx->err) {
        if (m_ctx) {
            qWarning() << "Redis connection error:" << m_ctx->errstr;
            redisFree(m_ctx);
            m_ctx = nullptr;
        } else {
            qWarning() << "Redis: can't allocate context";
        }
        if (m_connected) {
            m_connected = false;
            emit connectedChanged();
        }
        return;
    }

    if (!m_connected) {
        m_connected = true;
        emit connectedChanged();
    }

    qDebug() << "Connected to Redis";
    fetchAllValues();
}

void RedisBridge::disconnectRedis()
{
    if (m_ctx) {
        redisFree(m_ctx);
        m_ctx = nullptr;
    }
    if (m_connected) {
        m_connected = false;
        emit connectedChanged();
    }
}

QString RedisBridge::redisGet(const QString &key)
{
    if (!m_ctx) return QString();

    redisReply *reply = (redisReply *)redisCommand(m_ctx, "GET %s", key.toUtf8().constData());
    if (!reply) {
        qWarning() << "Redis GET failed for" << key;
        connectToRedis(); // Try reconnect
        return QString();
    }

    QString result;
    if (reply->type == REDIS_REPLY_STRING) {
        result = QString::fromUtf8(reply->str, reply->len);
    }
    freeReplyObject(reply);
    return result;
}

void RedisBridge::redisSet(const QString &key, const QString &value)
{
    if (!m_ctx) return;

    redisReply *reply = (redisReply *)redisCommand(m_ctx, "SET %s %s",
        key.toUtf8().constData(), value.toUtf8().constData());
    if (!reply) {
        qWarning() << "Redis SET failed for" << key;
        connectToRedis();
        return;
    }
    freeReplyObject(reply);
}

void RedisBridge::redisPublish(const QString &channel, const QString &message)
{
    if (!m_ctx) return;

    redisReply *reply = (redisReply *)redisCommand(m_ctx, "PUBLISH %s %s",
        channel.toUtf8().constData(), message.toUtf8().constData());
    if (reply) {
        freeReplyObject(reply);
    }
}

void RedisBridge::fetchAllValues()
{
    if (!m_ctx) return;

    auto getInt = [this](const QString &key, int defaultVal) -> int {
        QString val = redisGet(key);
        if (val.isEmpty()) return defaultVal;
        bool ok;
        int result = val.toInt(&ok);
        return ok ? result : defaultVal;
    };

    auto getDouble = [this](const QString &key, double defaultVal) -> double {
        QString val = redisGet(key);
        if (val.isEmpty()) return defaultVal;
        bool ok;
        double result = val.toDouble(&ok);
        return ok ? result : defaultVal;
    };

    m_iso = getInt("iso", 100);
    m_shutterAngle = getInt("shutter_a", 180);
    m_shutterSpeed = getDouble("shutter_s", 0.0);
    m_fps = getInt("fps", 24);
    m_whiteBalance = getInt("awb", 0);
    m_recording = getInt("is_recording", 0) != 0;
    m_width = getInt("width", 0);
    m_height = getInt("height", 0);
    m_compression = getInt("compress", 0);

    // Parse color gains "r,b" format
    QString cgRb = redisGet("cg_rb");
    if (!cgRb.isEmpty()) {
        QStringList parts = cgRb.split(",");
        if (parts.size() >= 2) {
            m_colorGainR = parts[0].toDouble();
            m_colorGainB = parts[1].toDouble();
        }
    }

    emit isoChanged();
    emit shutterAngleChanged();
    emit shutterSpeedChanged();
    emit fpsChanged();
    emit whiteBalanceChanged();
    emit recordingChanged();
    emit resolutionChanged();
    emit colorGainsChanged();
    emit compressionChanged();
}

void RedisBridge::pollRedis()
{
    if (!m_ctx) {
        connectToRedis();
        return;
    }

    // Poll key values from Redis
    auto checkInt = [this](const QString &key, int &member, auto signal) {
        QString val = redisGet(key);
        if (!val.isEmpty()) {
            bool ok;
            int newVal = val.toInt(&ok);
            if (ok && newVal != member) {
                member = newVal;
                emit (this->*signal)();
            }
        }
    };

    auto checkDouble = [this](const QString &key, double &member, auto signal) {
        QString val = redisGet(key);
        if (!val.isEmpty()) {
            bool ok;
            double newVal = val.toDouble(&ok);
            if (ok && qAbs(newVal - member) > 0.001) {
                member = newVal;
                emit (this->*signal)();
            }
        }
    };

    checkInt("iso", m_iso, &RedisBridge::isoChanged);
    checkInt("shutter_a", m_shutterAngle, &RedisBridge::shutterAngleChanged);
    checkDouble("shutter_s", m_shutterSpeed, &RedisBridge::shutterSpeedChanged);
    checkInt("fps", m_fps, &RedisBridge::fpsChanged);
    checkInt("awb", m_whiteBalance, &RedisBridge::whiteBalanceChanged);
    checkInt("width", m_width, &RedisBridge::resolutionChanged);
    checkInt("height", m_height, &RedisBridge::resolutionChanged);
    checkInt("compress", m_compression, &RedisBridge::compressionChanged);

    // Recording state
    QString recVal = redisGet("is_recording");
    if (!recVal.isEmpty()) {
        bool newRec = recVal.toInt() != 0;
        if (newRec != m_recording) {
            m_recording = newRec;
            emit recordingChanged();
        }
    }

    // Color gains
    QString cgRb = redisGet("cg_rb");
    if (!cgRb.isEmpty()) {
        QStringList parts = cgRb.split(",");
        if (parts.size() >= 2) {
            double r = parts[0].toDouble();
            double b = parts[1].toDouble();
            if (qAbs(r - m_colorGainR) > 0.001 || qAbs(b - m_colorGainB) > 0.001) {
                m_colorGainR = r;
                m_colorGainB = b;
                emit colorGainsChanged();
            }
        }
    }
}

void RedisBridge::setISO(int value)
{
    redisSet("iso", QString::number(value));
    redisPublish("cp_controls", "iso");
    if (value != m_iso) {
        m_iso = value;
        emit isoChanged();
    }
}

void RedisBridge::setShutterAngle(int value)
{
    redisSet("shutter_a", QString::number(value));
    redisPublish("cp_controls", "shutter_a");
    if (value != m_shutterAngle) {
        m_shutterAngle = value;
        emit shutterAngleChanged();
    }
}

void RedisBridge::setFPS(int value)
{
    redisSet("fps", QString::number(value));
    redisPublish("cp_controls", "fps");
    if (value != m_fps) {
        m_fps = value;
        emit fpsChanged();
    }
}

void RedisBridge::setWhiteBalance(int value)
{
    redisSet("awb", QString::number(value));
    redisPublish("cp_controls", "awb");
    if (value != m_whiteBalance) {
        m_whiteBalance = value;
        emit whiteBalanceChanged();
    }
}

void RedisBridge::setRecording(bool value)
{
    int intVal = value ? 1 : 0;
    redisSet("is_recording", QString::number(intVal));
    redisPublish("cp_controls", "is_recording");
    if (value != m_recording) {
        m_recording = value;
        emit recordingChanged();
    }
}

void RedisBridge::setCompression(int value)
{
    redisSet("compress", QString::number(value));
    if (value != m_compression) {
        m_compression = value;
        emit compressionChanged();
    }
}

void RedisBridge::setColorGains(double r, double b)
{
    QString val = QString("%1,%2").arg(r).arg(b);
    redisSet("cg_rb", val);
    redisPublish("cp_controls", "cg_rb");
    m_colorGainR = r;
    m_colorGainB = b;
    emit colorGainsChanged();
}

QString RedisBridge::getKey(const QString &key)
{
    return redisGet(key);
}

void RedisBridge::setKey(const QString &key, const QString &value)
{
    redisSet(key, value);
}
