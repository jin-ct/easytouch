#include <QApplication>
#include <QQmlApplicationEngine>
#include <QDebug>
#include <Windows.h>
#include <QQmlContext>

#include "src/components/Functions.h"
#include "src/components/FullScreenWatcher.h"
#include "src/components/NotificationHelper.h"
#include "src/components/UpdateHelper.h"
#include "src/components/FileHelper.h"
#include "src/components/ConfigFileManager.h"
#include "src/components/QmlImageProvider.h"
#include "src/components/CircularReveal.h"
#include "src/components/FileWatcher.h"
#include "src/components/MouseHook.h"
#include "src/components/WindowMonitor.h"

#include "src/functions/WhiteBoardItem.h"
#include "src/functions/WeChatHelper.h"
#include "src/functions/WindowFocusHelper.h"
#include "src/functions/ScreenMovement.h"
#include "src/functions/LaunchingHelper.h"

#include "src/GlobalManager.h"
#include "src/ConfigManager.h"
#include "src/QtLogger.h"

#ifdef WIN32
#  include "src/app_dmp.h"
#endif

int main(int argc, char *argv[])
{
#ifdef WIN32
    ::SetUnhandledExceptionFilter(MyUnhandledExceptionFilter);
    qputenv("QT_QPA_PLATFORM", "windows:darkmode=2");
#endif

    QApplication app(argc, argv);

    // 日志初始化
    LOG_INIT(LogConfig());

    // 防止重复启动
    HANDLE hMutex = NULL;
    int tryCount = 0;
    while(true) {
        hMutex = CreateMutex(nullptr, TRUE, (LPCWSTR)qApp->applicationName().toStdWString().c_str());
        if (GetLastError() == ERROR_ALREADY_EXISTS) {
            qWarning() << "An instance of the application is already running.";
            CloseHandle(hMutex);
            hMutex = NULL;
            QThread::sleep(1000);
        } else {
            break;
        }
        tryCount++;
        if (tryCount > 2)
            return 1;
    }

    QQmlApplicationEngine engine;

    // Qml类型注册
    qmlRegisterType<Functions>("Functions", 1, 0, "Functions");
    qmlRegisterType<FullscreenWatcher>("Functions", 1, 0, "FullscreenWatcher");
    qmlRegisterType<NotificationHelper>("Functions", 1, 0, "NotificationHelper");
    qmlRegisterType<UpdateHelper>("Functions", 1, 0, "UpdateHelper");
    qmlRegisterType<FileHelper>("Functions", 1, 0, "FileHelper");
    qmlRegisterType<MouseHook>("Functions", 1, 0, "MouseHook");
    qmlRegisterType<QmlImageProvider>("Functions", 1, 0, "QmlImageProvider");
    qmlRegisterType<ConfigFileManager>("Functions", 1, 0, "ConfigFileManager");
    qmlRegisterType<CircularReveal>("Functions", 1, 0, "CircularReveal");
    qmlRegisterType<FileWatcher>("Functions", 1, 0, "FileWatcher");

    qmlRegisterType<WhiteboardItem>("Functions", 1, 0, "WhiteboardItem");
    qmlRegisterType<WeChatHelper>("Functions", 1, 0, "WeChatHelper");
    qmlRegisterType<WindowFocusHelper>("Functions", 1, 0, "WindowFocusHelper");
    qmlRegisterType<ScreenMovement>("Functions", 1, 0, "ScreenMovement");
    qmlRegisterType<LaunchingHelper>("Functions", 1, 0, "LaunchingHelper");

    // Qml单例注册及初始化
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

    // 监测线程（单例）初始化
    // 鼠标钩子
    MouseHook::instance()->start();
    QObject::connect(&app, &QApplication::aboutToQuit, MouseHook::instance(), &MouseHook::stop);
    // 顶层窗口监测器
    WindowMonitor::instance()->start();
    QObject::connect(&app, &QApplication::aboutToQuit, WindowMonitor::instance(), &WindowMonitor::stop);

    // Qml图像 Provider
    engine.addImageProvider(QLatin1String("MImage"), QmlImageProvider::instance());

    // 暴露程序目录至Qml
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
