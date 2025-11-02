#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "functions/functions.h"
#include <QSettings>
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QDebug>

bool setAutoStart(bool enable)
{
    QString appName = QCoreApplication::applicationName();
    QString appPath = QCoreApplication::applicationFilePath();
    appPath = QDir::toNativeSeparators(appPath);

    QSettings reg("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                  QSettings::NativeFormat);

    if (enable) {
        reg.setValue(appName, "\"" + appPath + "\"");
        qDebug() << "自启动已启用:" << appPath;
    } else {
        reg.remove(appName);
        qDebug() << "自启动已禁用";
    }

    return true;
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    setAutoStart(true);

    QQmlApplicationEngine engine;

    qmlRegisterType<Functions>("Functions", 1, 0, "Functions");

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("easytouch", "Main");

    return app.exec();
}
