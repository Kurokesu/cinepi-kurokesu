#include "ConfigManager.h"
#include "logging.h"
#include <QSettings>

static auto &logger()
{
    static auto l = cinepi::getLogger("ui.config");
    return l;
}

ConfigManager::ConfigManager(const QString &basePath, QObject *parent)
    : QQmlPropertyMap(this, parent)
    , m_configPath(basePath + "/settings.ini")
{
    // Camera exposure -- -1 = auto, positive = manual
    insert("manualIsoSensitivity",      800);
    insert("manualShutterAngle",        180);
    insert("colorTemperature",          0);
    insert("frameRate",                 24);

    // Monitor overlays
    insert("zebraEnabled",              true);
    insert("zebraThreshold",            85);
    insert("falseColorEnabled",         false);
    insert("grayscaleEnabled",          false);
    insert("focusPeakingEnabled",       false);

    insert("crosshairEnabled",          false);
    insert("thirdsGridEnabled",         false);
    insert("goldenEnabled",             false);
    insert("centerDotEnabled",          false);
    insert("cinematicGuideEnabled",     false);
    insert("cinematicGuide185Enabled",  false);
    insert("cinematicGuide43Enabled",   true);

    logger()->info("Config file: {}", m_configPath.toStdString());
    reload();
}

QVariant ConfigManager::coerce(const QString &key, const QVariant &input)
{
    QVariant cur = value(key);
    if (!cur.isValid())
        return cur;

    if (cur.metaType().id() == QMetaType::Int)
        return input.toInt();

    if (cur.metaType().id() == QMetaType::Bool)
        return input.toBool();

    return cur;
}

QVariant ConfigManager::updateValue(const QString &key, const QVariant &input)
{
    return coerce(key, input);
}

void ConfigManager::reload()
{
    QSettings settings(m_configPath, QSettings::IniFormat);
    const QStringList allKeys = keys();
    for (const QString &key : allKeys) {
        if (settings.contains(key))
            insert(key, coerce(key, settings.value(key)));
    }
    logger()->debug("Loaded {} keys from {}", allKeys.size(), m_configPath.toStdString());
}

void ConfigManager::save()
{
    QSettings settings(m_configPath, QSettings::IniFormat);
    const QStringList allKeys = keys();
    for (const QString &key : allKeys)
        settings.setValue(key, value(key));
    settings.sync();
    logger()->debug("Saved {} keys to {}", allKeys.size(), m_configPath.toStdString());
}
