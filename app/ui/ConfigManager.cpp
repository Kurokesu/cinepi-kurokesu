#include "ConfigManager.h"
#include "logging.h"
#include <QFile>
#include <QTextStream>
#include <QDir>

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.config");
    return l;
}

ConfigManager::ConfigManager(const QString &basePath, QObject *parent)
    : QObject(parent)
    , m_basePath(basePath)
{
    logger()->info("Loading config from {}", basePath.toStdString());
    reload();
}

void ConfigManager::reload()
{
    loadConfig();
    loadOverlay();
}

void ConfigManager::save()
{
    saveConfig();
    saveOverlay();
}

QVariantMap ConfigManager::readIniFile(const QString &path)
{
    QVariantMap map;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        logger()->warn("Cannot open config file: {}", path.toStdString());
        return map;
    }

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty() || line.startsWith('#')) continue;

        int spaceIdx = line.indexOf(' ');
        if (spaceIdx > 0) {
            QString key = line.left(spaceIdx).trimmed();
            QString value = line.mid(spaceIdx + 1).trimmed();
            map[key] = value;
        }
    }
    file.close();
    logger()->debug("Loaded {} keys from {}", map.size(), path.toStdString());
    return map;
}

void ConfigManager::writeIniFile(const QString &path, const QVariantMap &data)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        logger()->warn("Cannot write config file: {}", path.toStdString());
        return;
    }

    QTextStream out(&file);
    for (auto it = data.constBegin(); it != data.constEnd(); ++it) {
        out << it.key() << " " << it.value().toString() << "\n";
    }
    file.close();
    logger()->debug("Saved {} keys to {}", data.size(), path.toStdString());
}

void ConfigManager::loadConfig()
{
    QString path = m_basePath + "/config.ini";
    QVariantMap data = readIniFile(path);

    if (data.contains("ZebraEnabled"))
        m_zebraEnabled = data["ZebraEnabled"].toInt() != 0;
    if (data.contains("ZebraThreshold"))
        m_zebraThreshold = data["ZebraThreshold"].toDouble();
    if (data.contains("FalseColorEnabled"))
        m_falseColorEnabled = data["FalseColorEnabled"].toInt() != 0;
    if (data.contains("grayscaleEnabled"))
        m_grayscaleEnabled = data["grayscaleEnabled"].toInt() != 0;
    if (data.contains("focusPeakingEnabled"))
        m_focusPeakingEnabled = data["focusPeakingEnabled"].toInt() != 0;

    Q_EMIT zebraEnabledChanged();
    Q_EMIT zebraThresholdChanged();
    Q_EMIT falseColorEnabledChanged();
    Q_EMIT grayscaleEnabledChanged();
    Q_EMIT focusPeakingEnabledChanged();
}

void ConfigManager::loadOverlay()
{
    QString path = m_basePath + "/overlay.ini";
    QVariantMap data = readIniFile(path);

    if (data.contains("CrosshairEnabled"))
        m_crosshairEnabled = data["CrosshairEnabled"].toInt() != 0;
    if (data.contains("ThirdsGridEnabled"))
        m_thirdsGridEnabled = data["ThirdsGridEnabled"].toInt() != 0;
    if (data.contains("GoldenEnabled"))
        m_goldenEnabled = data["GoldenEnabled"].toInt() != 0;
    if (data.contains("CenterDotEnabled"))
        m_centerDotEnabled = data["CenterDotEnabled"].toInt() != 0;
    if (data.contains("CinematicGuideEnabled"))
        m_cinematicGuideEnabled = data["CinematicGuideEnabled"].toInt() != 0;
    if (data.contains("CinematicGuide185Enabled"))
        m_cinematicGuide185Enabled = data["CinematicGuide185Enabled"].toInt() != 0;
    if (data.contains("CinematicGuide43Enabled"))
        m_cinematicGuide43Enabled = data["CinematicGuide43Enabled"].toInt() != 0;

    Q_EMIT crosshairEnabledChanged();
    Q_EMIT thirdsGridEnabledChanged();
    Q_EMIT goldenEnabledChanged();
    Q_EMIT centerDotEnabledChanged();
    Q_EMIT cinematicGuideEnabledChanged();
    Q_EMIT cinematicGuide185EnabledChanged();
    Q_EMIT cinematicGuide43EnabledChanged();
}

void ConfigManager::saveConfig()
{
    QVariantMap data;
    data["ZebraEnabled"] = m_zebraEnabled ? 1 : 0;
    data["ZebraThreshold"] = m_zebraThreshold;
    data["FalseColorEnabled"] = m_falseColorEnabled ? 1 : 0;
    data["grayscaleEnabled"] = m_grayscaleEnabled ? 1 : 0;
    data["focusPeakingEnabled"] = m_focusPeakingEnabled ? 1 : 0;

    writeIniFile(m_basePath + "/config.ini", data);
}

void ConfigManager::saveOverlay()
{
    QVariantMap data;
    data["CrosshairEnabled"] = m_crosshairEnabled ? 1 : 0;
    data["ThirdsGridEnabled"] = m_thirdsGridEnabled ? 1 : 0;
    data["GoldenEnabled"] = m_goldenEnabled ? 1 : 0;
    data["CenterDotEnabled"] = m_centerDotEnabled ? 1 : 0;
    data["CinematicGuideEnabled"] = m_cinematicGuideEnabled ? 1 : 0;
    data["CinematicGuide185Enabled"] = m_cinematicGuide185Enabled ? 1 : 0;
    data["CinematicGuide43Enabled"] = m_cinematicGuide43Enabled ? 1 : 0;

    writeIniFile(m_basePath + "/overlay.ini", data);
}

void ConfigManager::setZebraEnabled(bool v) {
    if (m_zebraEnabled != v) { m_zebraEnabled = v; Q_EMIT zebraEnabledChanged(); saveConfig(); }
}
void ConfigManager::setZebraThreshold(double v) {
    if (qAbs(m_zebraThreshold - v) > 0.001) { m_zebraThreshold = v; Q_EMIT zebraThresholdChanged(); saveConfig(); }
}
void ConfigManager::setFalseColorEnabled(bool v) {
    if (m_falseColorEnabled != v) { m_falseColorEnabled = v; Q_EMIT falseColorEnabledChanged(); saveConfig(); }
}
void ConfigManager::setGrayscaleEnabled(bool v) {
    if (m_grayscaleEnabled != v) { m_grayscaleEnabled = v; Q_EMIT grayscaleEnabledChanged(); saveConfig(); }
}
void ConfigManager::setFocusPeakingEnabled(bool v) {
    if (m_focusPeakingEnabled != v) { m_focusPeakingEnabled = v; Q_EMIT focusPeakingEnabledChanged(); saveConfig(); }
}
void ConfigManager::setCrosshairEnabled(bool v) {
    if (m_crosshairEnabled != v) { m_crosshairEnabled = v; Q_EMIT crosshairEnabledChanged(); saveOverlay(); }
}
void ConfigManager::setThirdsGridEnabled(bool v) {
    if (m_thirdsGridEnabled != v) { m_thirdsGridEnabled = v; Q_EMIT thirdsGridEnabledChanged(); saveOverlay(); }
}
void ConfigManager::setGoldenEnabled(bool v) {
    if (m_goldenEnabled != v) { m_goldenEnabled = v; Q_EMIT goldenEnabledChanged(); saveOverlay(); }
}
void ConfigManager::setCenterDotEnabled(bool v) {
    if (m_centerDotEnabled != v) { m_centerDotEnabled = v; Q_EMIT centerDotEnabledChanged(); saveOverlay(); }
}
void ConfigManager::setCinematicGuideEnabled(bool v) {
    if (m_cinematicGuideEnabled != v) { m_cinematicGuideEnabled = v; Q_EMIT cinematicGuideEnabledChanged(); saveOverlay(); }
}
void ConfigManager::setCinematicGuide185Enabled(bool v) {
    if (m_cinematicGuide185Enabled != v) { m_cinematicGuide185Enabled = v; Q_EMIT cinematicGuide185EnabledChanged(); saveOverlay(); }
}
void ConfigManager::setCinematicGuide43Enabled(bool v) {
    if (m_cinematicGuide43Enabled != v) { m_cinematicGuide43Enabled = v; Q_EMIT cinematicGuide43EnabledChanged(); saveOverlay(); }
}
