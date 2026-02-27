#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

/**
 * ConfigManager - Reads/writes config.ini and overlay.ini files.
 *
 * These files use a simple "key value" format (space-separated).
 *
 * config.ini:   ZebraEnabled, ZebraThreshold, FalseColorEnabled,
 *               grayscaleEnabled, focusPeakingEnabled
 *
 * overlay.ini:  CrosshairEnabled, ThirdsGridEnabled, CinematicGuideEnabled,
 *               CinematicGuide185Enabled, CinematicGuide43Enabled
 */
class ConfigManager : public QObject
{
    Q_OBJECT

    // Shader overlay toggles (config.ini)
    Q_PROPERTY(bool zebraEnabled READ zebraEnabled WRITE setZebraEnabled NOTIFY zebraEnabledChanged)
    Q_PROPERTY(double zebraThreshold READ zebraThreshold WRITE setZebraThreshold NOTIFY zebraThresholdChanged)
    Q_PROPERTY(bool falseColorEnabled READ falseColorEnabled WRITE setFalseColorEnabled NOTIFY falseColorEnabledChanged)
    Q_PROPERTY(bool grayscaleEnabled READ grayscaleEnabled WRITE setGrayscaleEnabled NOTIFY grayscaleEnabledChanged)
    Q_PROPERTY(bool focusPeakingEnabled READ focusPeakingEnabled WRITE setFocusPeakingEnabled NOTIFY focusPeakingEnabledChanged)

    // Grid/guide overlay toggles (overlay.ini)
    Q_PROPERTY(bool crosshairEnabled READ crosshairEnabled WRITE setCrosshairEnabled NOTIFY crosshairEnabledChanged)
    Q_PROPERTY(bool thirdsGridEnabled READ thirdsGridEnabled WRITE setThirdsGridEnabled NOTIFY thirdsGridEnabledChanged)
    Q_PROPERTY(bool cinematicGuideEnabled READ cinematicGuideEnabled WRITE setCinematicGuideEnabled NOTIFY cinematicGuideEnabledChanged)
    Q_PROPERTY(bool cinematicGuide185Enabled READ cinematicGuide185Enabled WRITE setCinematicGuide185Enabled NOTIFY cinematicGuide185EnabledChanged)
    Q_PROPERTY(bool cinematicGuide43Enabled READ cinematicGuide43Enabled WRITE setCinematicGuide43Enabled NOTIFY cinematicGuide43EnabledChanged)

public:
    explicit ConfigManager(const QString &basePath, QObject *parent = nullptr);

    // Shader overlays
    bool zebraEnabled() const { return m_zebraEnabled; }
    double zebraThreshold() const { return m_zebraThreshold; }
    bool falseColorEnabled() const { return m_falseColorEnabled; }
    bool grayscaleEnabled() const { return m_grayscaleEnabled; }
    bool focusPeakingEnabled() const { return m_focusPeakingEnabled; }

    void setZebraEnabled(bool v);
    void setZebraThreshold(double v);
    void setFalseColorEnabled(bool v);
    void setGrayscaleEnabled(bool v);
    void setFocusPeakingEnabled(bool v);

    // Grid overlays
    bool crosshairEnabled() const { return m_crosshairEnabled; }
    bool thirdsGridEnabled() const { return m_thirdsGridEnabled; }
    bool cinematicGuideEnabled() const { return m_cinematicGuideEnabled; }
    bool cinematicGuide185Enabled() const { return m_cinematicGuide185Enabled; }
    bool cinematicGuide43Enabled() const { return m_cinematicGuide43Enabled; }

    void setCrosshairEnabled(bool v);
    void setThirdsGridEnabled(bool v);
    void setCinematicGuideEnabled(bool v);
    void setCinematicGuide185Enabled(bool v);
    void setCinematicGuide43Enabled(bool v);

    Q_INVOKABLE void reload();
    Q_INVOKABLE void save();

signals:
    void zebraEnabledChanged();
    void zebraThresholdChanged();
    void falseColorEnabledChanged();
    void grayscaleEnabledChanged();
    void focusPeakingEnabledChanged();
    void crosshairEnabledChanged();
    void thirdsGridEnabledChanged();
    void cinematicGuideEnabledChanged();
    void cinematicGuide185EnabledChanged();
    void cinematicGuide43EnabledChanged();

private:
    void loadConfig();
    void loadOverlay();
    void saveConfig();
    void saveOverlay();

    QVariantMap readIniFile(const QString &path);
    void writeIniFile(const QString &path, const QVariantMap &data);

    QString m_basePath;

    // config.ini values
    bool m_zebraEnabled = true;
    double m_zebraThreshold = 0.85;
    bool m_falseColorEnabled = false;
    bool m_grayscaleEnabled = false;
    bool m_focusPeakingEnabled = false;

    // overlay.ini values
    bool m_crosshairEnabled = false;
    bool m_thirdsGridEnabled = false;
    bool m_cinematicGuideEnabled = false;
    bool m_cinematicGuide185Enabled = false;
    bool m_cinematicGuide43Enabled = true;
};
