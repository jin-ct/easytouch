#include <QApplication>
#include <QQmlApplicationEngine>
#include <QDebug>

#include "functions/functions.h"
#include "functions/fullscreenwatcher.h"
#include "functions/notificationhelper.h"
#include "functions/whiteboarditem.h"

#include "QtLogger.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    app.setOrganizationName("jin-ct");

    LOG_INIT(LogConfig());

    QQmlApplicationEngine engine;

    qmlRegisterType<Functions>("Functions", 1, 0, "Functions");
    qmlRegisterType<FullscreenWatcher>("Functions", 1, 0, "FullscreenWatcher");
    qmlRegisterType<NotificationHelper>("Functions", 1, 0, "NotificationHelper");
    qmlRegisterType<WhiteboardItem>("Functions", 1, 0, "WhiteboardItem");

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("easytouch", "Main");

    return app.exec();
}
