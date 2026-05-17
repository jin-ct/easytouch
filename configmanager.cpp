#include "configmanager.h"
#include "functions/filehelper.h"
#include <QApplication>
#include <QSettings>
#include <QFileInfo>
#include <QTimer>
#include <QJSValue>

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
    registerConfig("UpdateChannel", "release", settings);
    registerConfig("ToolBar.Enable", true, settings);
    registerConfig("ToolBar.AutoHideBtns", true, settings);
    registerConfig("ToolBar.AutoShowBtns", true, settings);
    registerConfig("ToolBar.ShowWindowOpacityAnimation", false, settings);
    registerConfig("ToolBar.StayTopEnhanced", true, settings);
    registerConfig("USBDriveHelper.Enable", true, settings);
    registerConfig("WeChatTouchHelper.Enable", true, settings);
    registerConfig("WindowFocusHelper.Enable", true, settings);
    registerConfig("LaunchingHelper.Enable", true, settings);
    registerConfig("Drawpad.SavePath", FileHelper::desktopFolder().toString() + "/屏幕批注", settings);

    // 数据记忆
    memory = new ConfigFileManager("data/memory.json", this);
    handleConfigLoad(memory);
    registerConfig("RandomGenerator.minNum", 1, memory);
    registerConfig("RandomGenerator.maxNum", 100, memory);
    registerConfig("ConfigFileManager.isLoadOldFile", false, memory);

    // 屏幕移位功能数据保存
    screenMovement = new ConfigFileManager("data/screenMovement.json", this);
    handleConfigLoad(screenMovement);
    registerConfig("List", QVariantList(), screenMovement);

    // 兼容旧配置文件
    connect(this, &ConfigManager::allConfigLoaded, this, [=](){
        QTimer::singleShot(500, this, [=](){
            if (!memory->get("ConfigFileManager.isLoadOldFile").toBool())
                compatibleOldConfigFile();
        });
    });
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

void ConfigManager::compatibleOldConfigFile()
{
    QString oldConfigFilePath_settings = qApp->applicationDirPath() + "/config/settings.ini";
    QString oldConfigFilePath_screenMove = qApp->applicationDirPath() + "/config/screenMove.ini";

    if (!QFileInfo::exists(oldConfigFilePath_settings) && !QFileInfo::exists(oldConfigFilePath_screenMove)) {
        qDebug() << "Not Need To Be Compatible Old Config File";
        memory->set("ConfigFileManager.isLoadOldFile", true);
        return;
    }

    bool success = true;

    if (QFileInfo::exists(oldConfigFilePath_settings)) {

        QSettings m_settings(oldConfigFilePath_settings, QSettings::IniFormat);

        m_settings.beginGroup("Basic");

        bool isAutoUpdate = m_settings.value("isAutoUpdate", true).toBool();
        bool isAutoShowBtns = m_settings.value("isAutoShowBtns", true).toBool();
        bool isAutoStart = m_settings.value("isAutoStart", true).toBool();
        bool isSendOpenUsb = m_settings.value("isSendOpenUsb", true).toBool();
        bool isWeChatTouchHelperEnable = m_settings.value("isWeChatTouchHelperEnable", true).toBool();
        bool isWindowFocusHelperEnable = m_settings.value("isWindowFocusHelperEnable", true).toBool();
        QString penSavePath = m_settings.value("penSavePath", FileHelper::desktopFolder().toString() + "/屏幕批注").toString();
        bool isShowToolBar = m_settings.value("isShowToolBar", true).toBool();
        bool isShowWinodwOpacityAnimation = m_settings.value("isShowWinodwOpacityAnimation", false).toBool();
        bool isStayTopEnhanced = m_settings.value("isStayTopEnhanced", true).toBool();
        bool isAutoHideBtns = m_settings.value("isAutoHideBtns", true).toBool();

        if (m_settings.contains("isAutoUpdate"))
            success = success && settings->set("AutoUpdate", isAutoUpdate, false);
        if (m_settings.contains("isAutoShowBtns"))
            success = success && settings->set("AutoShowBtns", isAutoShowBtns, false);
        if (m_settings.contains("isAutoStart"))
            success = success && settings->set("AutoStart", isAutoStart, false);
        if (m_settings.contains("isSendOpenUsb"))
            success = success && settings->set("USBDriveHelper.Enable", isSendOpenUsb, false);
        if (m_settings.contains("isWeChatTouchHelperEnable"))
            success = success && settings->set("WeChatTouchHelper.Enable", isWeChatTouchHelperEnable, false);
        if (m_settings.contains("isWindowFocusHelperEnable"))
            success = success && settings->set("WindowFocusHelper.Enable", isWindowFocusHelperEnable, false);
        if (m_settings.contains("penSavePath"))
            success = success && settings->set("Drawpad.SavePath", penSavePath, false);
        if (m_settings.contains("isShowToolBar"))
            success = success && settings->set("ToolBar.Enable", isShowToolBar, false);
        if (m_settings.contains("isShowWinodwOpacityAnimation"))
            success = success && settings->set("ToolBar.ShowWindowOpacityAnimation", isShowWinodwOpacityAnimation, false);
        if (m_settings.contains("isStayTopEnhanced"))
            success = success && settings->set("ToolBar.StayTopEnhanced", isStayTopEnhanced, false);
        if (m_settings.contains("isAutoHideBtns"))
            success = success && settings->set("ToolBar.AutoHideBtns", isAutoHideBtns, false);
        if (m_settings.contains("isAutoHideBtns"))
            success = success && settings->set("ToolBar.AutoHideBtns", isAutoHideBtns, false);

        m_settings.endGroup();

        m_settings.beginGroup("Random");

        int minNum = m_settings.value("minNum", 1).toInt();
        int maxNum = m_settings.value("maxNum", 100).toInt();

        if (m_settings.contains("minNum"))
            success = success && memory->set("RandomGenerator.minNum", minNum, false);
        if (m_settings.contains("maxNum"))
            success = success && memory->set("RandomGenerator.maxNum", maxNum, false);

        m_settings.endGroup();
    }

    if (QFileInfo::exists(oldConfigFilePath_screenMove)) {
        QSettings screenMove(oldConfigFilePath_screenMove, QSettings::IniFormat);
        QVariant screenMoveSaveList = screenMove.value("ScreenMoveSaveDatas/screenMoveSaveList");
        if (screenMoveSaveList.userType() != QMetaType::QVariantList) {
            if (screenMoveSaveList.canConvert<QVariantList>()) {
                screenMoveSaveList = screenMoveSaveList.toList();
            } else {
                screenMoveSaveList = QVariantList();
                qWarning() << "To Be Compatible Old Config File Error: screenMoveSaveList Read Error; userType: " << screenMoveSaveList.userType();
            }
        }

        if (screenMove.contains("ScreenMoveSaveDatas/screenMoveSaveList"))
            success = success && screenMovement->set("List", screenMoveSaveList, false);

    }

    settings->writeConfigFile();
    memory->writeConfigFile();
    screenMovement->writeConfigFile();

    if (success)
        qDebug() << "To Be Compatible Old Config File Success";
    else
        qWarning() << "To Be Compatible Old Config File Error";

    memory->set("ConfigFileManager.isLoadOldFile", true);
}
