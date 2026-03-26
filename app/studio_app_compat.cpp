#include "quickstudioapplication.h"
#include <QtQml>

void registerStudioApplication()
{
    qmlRegisterType<QuickStudioApplication>(
        "QtQuick.Studio.Application", 1, 0, "StudioApplication");
}
