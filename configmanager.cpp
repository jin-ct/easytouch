#include "configmanager.h"
#include "functions/filehelper.h"

ConfigManager* ConfigManager::instance = nullptr;

static const int kConfigMgrCount = 3;

ConfigManager::ConfigManager(QObject *parent)
    : QObject{parent}
{
    // 常规设置
    settings = new ConfigFileManager("settings.json", this);
    handleConfigLoad(settings);
    registerConfig("AutoStart", true, settings);
    registerConfig("AutoUpdate", true, settings);
    registerConfig("ToolBar.Enable", true, settings);
    registerConfig("ToolBar.AutoHideBtns", true, settings);
    registerConfig("ToolBar.AutoShowBtns", true, settings);
    registerConfig("ToolBar.ShowWindowOpacityAnimation", false, settings);
    registerConfig("ToolBar.StayTopEnhanced", true, settings);
    registerConfig("USBDriveHelper.Enable", true, settings);
    registerConfig("WeChatTouchHelper.Enable", true, settings);
    registerConfig("WindowFocusHelper.Enable", true, settings);
    registerConfig("Drawpad.SavePath", FileHelper::desktopFolder().toString() + "/屏幕批注", settings);

    // 数据记忆
    memory = new ConfigFileManager("data/memory.json", this);
    handleConfigLoad(memory);
    registerConfig("RandomGenerator.minNum", 1, memory);
    registerConfig("RandomGenerator.maxNum", 100, memory);

    // 屏幕移位功能数据保存
    screenMovement = new ConfigFileManager("data/screenMovement.json", this);
    handleConfigLoad(screenMovement);
    registerConfig("List", QVariantList(), screenMovement);
}

void ConfigManager::registerConfig(const QString &path, const QVariant defaultVal, ConfigFileManager* mgr)
{
    connect(mgr, &ConfigFileManager::fileRead, this, [=](){
        if (!mgr->get(path).isValid()) {
            if (mgr->set(path, defaultVal, false))
                isChangedInRegistering = true;
            mgr->writeConfigFileDebounced();
        }
    });
}

void ConfigManager::handleConfigLoad(ConfigFileManager *mgr)
{
    connect(mgr, &ConfigFileManager::fileRead, this, [this](){
        ConfigLoadedCount++;
        if (ConfigLoadedCount == kConfigMgrCount)
            emit allConfigLoaded();
        qDebug() << "ConfigLoading(" << ConfigLoadedCount << ")";
    });
    connect(this, &ConfigManager::loadConfig, mgr, &ConfigFileManager::readConfigFile);
}
