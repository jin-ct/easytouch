#ifndef CONFIGMANAGER_H
#define CONFIGMANAGER_H

#include <QObject>
#include <QMutex>
#include "components/ConfigFileManager.h"

class ConfigManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ConfigFileManager* settings MEMBER settings NOTIFY managerChanged)
    Q_PROPERTY(ConfigFileManager* memory MEMBER memory NOTIFY managerChanged)
    Q_PROPERTY(ConfigFileManager* screenMovement MEMBER screenMovement NOTIFY managerChanged)
    Q_PROPERTY(ConfigFileManager* launchingHelperCfg MEMBER launchingHelperCfg NOTIFY managerChanged)

public:
    explicit ConfigManager(QObject *parent = nullptr);

    ConfigFileManager* settings{};
    ConfigFileManager* memory{};
    ConfigFileManager* screenMovement{};
    ConfigFileManager* launchingHelperCfg{};

    static ConfigManager* instance;  // 自身指针，注册全局单例对象时赋值

signals:
    void managerChanged();
    void allConfigLoaded();
    void loadConfig();

private:
    void registerConfig(const QString &path, const QVariant defaultVal, ConfigFileManager* mgr);
    bool isChangedInRegistering{false};
    void handleConfigLoad(ConfigFileManager* mgr);
    void compatibleOldConfigFile();
    int ConfigLoadedCount{0};
    QMutex mutex;
};

#endif // CONFIGMANAGER_H
