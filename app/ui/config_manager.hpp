/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * config_manager.hpp - application configuration store.
 */

#pragma once

#include <QQmlPropertyMap>
#include <QString>

class ConfigManager : public QQmlPropertyMap
{
    Q_OBJECT

public:
    explicit ConfigManager(QObject *parent = nullptr);

    Q_INVOKABLE void reload();
    Q_INVOKABLE void save();

protected:
    QVariant updateValue(const QString &key, const QVariant &input) override;

private:
    QVariant coerce(const QString &key, const QVariant &input);
    QString configPath_;
};
