#include <QApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <Windows.h>
#include <QQmlContext>

#include "functions/functions.h"
#include "functions/fullscreenwatcher.h"
#include "functions/notificationhelper.h"
#include "functions/whiteboarditem.h"
#include "functions/updatehelper.h"
#include "functions/filehelper.h"
#include "functions/wechathelper.h"
#include "functions/windowfocushelper.h"
#include "functions/screenmovement.h"
#include "functions/mousehook.h"
#include "functions/configfilemanager.h"
#include "functions/launchinghelper.h"
#include "functions/qmlimageprovider.h"

#include "globalmanager.h"
#include "configmanager.h"
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

    // 在主线程初始化MouseHook并启动/停止线程
    MouseHook::instance()->start();
    QObject::connect(&app, &QApplication::aboutToQuit, MouseHook::instance(), &MouseHook::stop);

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
    qmlRegisterType<MouseHook>("Functions", 1, 0, "MouseHook");
    qmlRegisterType<QmlImageProvider>("Functions", 1, 0, "QmlImageProvider");
    qmlRegisterType<ConfigFileManager>("Functions", 1, 0, "ConfigFileManager");
    qmlRegisterType<LaunchingHelper>("Functions", 1, 0, "LaunchingHelper");

    qmlRegisterSingletonType<GlobalManager>(
        "Functions", 1, 0, "Global",
        [](QQmlEngine *engine, QJSEngine *) -> QObject* {
            auto mgr = new GlobalManager();
            mgr->setParent(engine);
            GlobalManager::instance = mgr;
            return mgr;
        }
    );
    qmlRegisterSingletonType<ConfigManager>(
        "Functions", 1, 0, "Config",
        [](QQmlEngine *engine, QJSEngine *) -> QObject* {
            auto mgr = new ConfigManager();
            mgr->setParent(engine);
            ConfigManager::instance = mgr;
            return mgr;
        }
    );

    engine.addImageProvider(QLatin1String("MImage"), QmlImageProvider::instance());

    engine.rootContext()->setContextProperty("appDir", qApp->applicationDirPath());

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // 配置文件加载完成后再加载Main.qml
    engine.loadFromModule("easytouch", "Splash");

    return app.exec();
}
