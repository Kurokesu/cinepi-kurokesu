/* SPDX-License-Identifier: GPL-3.0-or-later */
/*
 * Copyright (C) 2026, UAB Kurokesu
 *
 * studio_app_compat.cpp - QML compatibility shim.
 */

#include "quickstudioapplication.h"
#include <QtQml>

void registerStudioApplication()
{
    qmlRegisterType<QuickStudioApplication>(
        "QtQuick.Studio.Application", 1, 0, "StudioApplication");
}
