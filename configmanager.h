#ifndef CONFIGMANAGER_H
#define CONFIGMANAGER_H

#include <QObject>
#include "functions/configfilemanager.h"

class ConfigManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(ConfigFileManager* settings MEMBER settings NOTIFY managerChanged)
    Q_PROPERTY(ConfigFileManager* memory MEMBER memory NOTIFY managerChanged)
    Q_PROPERTY(ConfigFileManager* screenMovement MEMBER screenMovement NOTIFY managerChanged)

public:
    explicit ConfigManager(QObject *parent = nullptr);

    ConfigFileManager* settings;
    ConfigFileManager* memory;
    ConfigFileManager* screenMovement;

    static ConfigManager* instance;  // 自身指针，注册全局单例对象时赋值

signals:
    void managerChanged();
    void allConfigLoaded();
    void loadConfig();

private:
    void registerConfig(const QString &path, const QVariant defaultVal, ConfigFileManager* mgr);
    bool isChangedInRegistering{false};
    void handleConfigLoad(ConfigFileManager* mgr);
    int ConfigLoadedCount{0};
};

#endif // CONFIGMANAGER_H
