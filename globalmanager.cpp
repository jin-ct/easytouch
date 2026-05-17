#include "globalmanager.h"
#include "configmanager.h"

GlobalManager* GlobalManager::instance = nullptr;

GlobalManager::GlobalManager(QObject *parent)
    : QObject{parent}
{
    funs = new Functions(this);
    fileHelper = new FileHelper(this);
    notification = new NotificationHelper(this);
    updateHelper = new UpdateHelper(this);

    // 配置更改时开关功能
    connect(ConfigManager::instance->settings, &ConfigFileManager::configChanged, this, &GlobalManager::handleConfigChanged);
    handleConfigChanged();
}

void GlobalManager::handleConfigChanged()
{
    if (!ConfigManager::instance->settings->readReady)
        return;
    switchFun(weChatHelper, ConfigManager::instance->settings->get("WeChatTouchHelper.Enable").toBool());
    switchFun(windowFocusHelper, ConfigManager::instance->settings->get("WindowFocusHelper.Enable").toBool());
    switchFun(launchingHelper, ConfigManager::instance->settings->get("LaunchingHelper.Enable").toBool());
}

template<typename T>
void GlobalManager::switchFun(T* &ptr, bool enable)
{
    if (enable && !ptr) {
        ptr = new T(this);
        emit funSwitched();
    } else if (!enable && ptr) {
        ptr->deleteLater();
        ptr = nullptr;
        emit funSwitched();
    }
}
