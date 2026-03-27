#pragma once

#include <QQmlPropertyMap>
#include <QString>

class ConfigManager : public QQmlPropertyMap
{
    Q_OBJECT

public:
    explicit ConfigManager(const QString &basePath, QObject *parent = nullptr);

    Q_INVOKABLE void reload();
    Q_INVOKABLE void save();

protected:
    QVariant updateValue(const QString &key, const QVariant &input) override;

private:
    QVariant coerce(const QString &key, const QVariant &input);
    QString configPath_;
};
