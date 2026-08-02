#ifndef GLOBALMANAGER_H
#define GLOBALMANAGER_H

#include <QObject>

#include "components/Functions.h"
#include "components/Filehelper.h"
#include "components/NotificationHelper.h"
#include "components/UpdateHelper.h"
#include "components/MouseHook.h"
#include "components/QmlImageProvider.h"
#include "functions/WeChatHelper.h"
#include "functions/WindowFocusHelper.h"
#include "functions/LaunchingHelper.h"

class GlobalManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(MouseHook* mouseHook READ mouseHook NOTIFY objChanged)
    Q_PROPERTY(QmlImageProvider* imgProvider READ imgProvider NOTIFY objChanged)
    Q_PROPERTY(Functions* funs MEMBER funs NOTIFY objChanged)
    Q_PROPERTY(FileHelper* fileHelper MEMBER fileHelper NOTIFY objChanged)
    Q_PROPERTY(NotificationHelper* notification MEMBER notification NOTIFY objChanged)
    Q_PROPERTY(UpdateHelper* updateHelper MEMBER updateHelper NOTIFY objChanged)

    Q_PROPERTY(WeChatHelper* weChatHelper MEMBER weChatHelper NOTIFY funSwitched)
    Q_PROPERTY(WindowFocusHelper* windowFocusHelper MEMBER windowFocusHelper NOTIFY funSwitched)
    Q_PROPERTY(LaunchingHelper* launchingHelper MEMBER launchingHelper NOTIFY funSwitched)
public:
    explicit GlobalManager(QObject *parent = nullptr);

    MouseHook* mouseHook() const { return MouseHook::instance(); }
    QmlImageProvider* imgProvider() const { return QmlImageProvider::instance(); }

    static GlobalManager* instance;  // 自身指针，注册全局单例对象时赋值

public slots:
    void handleConfigChanged();

signals:
    void objChanged();
    void funSwitched();

private:
    template <typename T>
    void switchFun(T* &ptr, bool enable);

    Functions* funs{};
    FileHelper* fileHelper{};
    NotificationHelper* notification{};
    UpdateHelper* updateHelper{};

    WeChatHelper* weChatHelper{};
    WindowFocusHelper* windowFocusHelper{};
    LaunchingHelper* launchingHelper{};

};

#endif // GLOBALMANAGER_H
