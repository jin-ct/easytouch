#include <QApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <Windows.h>

#include "functions/functions.h"
#include "functions/fullscreenwatcher.h"
#include "functions/notificationhelper.h"
#include "functions/whiteboarditem.h"
#include "functions/updatehelper.h"
#include "functions/filehelper.h"
#include "functions/wechathelper.h"
#include "functions/windowfocushelper.h"
#include "functions/screenmovement.h"

#include "globalmanager.h"
#include "QtLogger.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    LOG_INIT(LogConfig());

    // 防止重复启动
    HANDLE hMutex = CreateMutex(nullptr, TRUE, (LPCWSTR)qApp->applicationName().toStdWString().c_str());
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        qWarning() << "An instance of the application is already running.";
        CloseHandle(hMutex);
        hMutex = NULL;
        return 1;
    }

    QQmlApplicationEngine engine;

    qmlRegisterType<Functions>("Functions", 1, 0, "Functions");
    qmlRegisterType<FullscreenWatcher>("Functions", 1, 0, "FullscreenWatcher");
    qmlRegisterType<NotificationHelper>("Functions", 1, 0, "NotificationHelper");
    qmlRegisterType<WhiteboardItem>("Functions", 1, 0, "WhiteboardItem");
    qmlRegisterType<UpdateHelper>("Functions", 1, 0, "UpdateHelper");
    qmlRegisterType<FileHelper>("Functions", 1, 0, "FileHelper");
    qmlRegisterType<WeChatHelper>("Functions", 1, 0, "WeChatHelper");
    qmlRegisterType<WindowFocusHelper>("Functions", 1, 0, "WindowFocusHelper");
    qmlRegisterType<ScreenMovement>("Functions", 1, 0, "ScreenMovement");

    qmlRegisterSingletonType<GlobalManager>(
        "Functions", 1, 0, "Global",
        [](QQmlEngine *engine, QJSEngine *) -> QObject* {
            auto mgr = new GlobalManager();
            mgr->setParent(engine);
            return mgr;
        }
    );

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("easytouch", "Main");

    return app.exec();
}
