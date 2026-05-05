#ifndef CONFIGFILEMANAGER_H
#define CONFIGFILEMANAGER_H

#include <QObject>
#include <QVariant>
#include <QJsonObject>
#include <QJsonDocument>
#include <QTimer>

class ConfigFileManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool readReady MEMBER readReady NOTIFY fileRead)
    Q_PROPERTY(QVariant data MEMBER config NOTIFY configChanged)
public:
    explicit ConfigFileManager(QObject *parent = nullptr);
    explicit ConfigFileManager(const QString &fileName, QObject *parent = nullptr);

    QVariant readConfigFile();
    bool writeConfigFile();
    Q_INVOKABLE void writeConfigFileDebounced();
    void setFileName(const QString &fileName);
    QVariant getConfigObject();

    /**
     * @brief get 获取配置的子字段
     * @param path 示例："a.b.c" 或 "a.b.c[i]"
     * @return 获取到的子字段
     */
    Q_INVOKABLE QVariant get(const QString &path);

    /**
     * @brief set 在配置中设置子字段，若子字段不存在则创建，若为数组则未定义部分补充空值
     * @param path 示例："a.b.c" 或 "a.b.c[i]"
     * @param val 将要设置的值
     * @param isSync 是否同步写入文件
     * @return 是否成功
     */
    Q_INVOKABLE bool set(const QString &path, const QVariant &val, bool isSync = true);

    /**
     * @brief add 在配置中增加指定字段，若指定字段已存在则修改对应值，若指定字段已存在并且为数组则在数组尾部插入
     * @param path 示例："a.b.c.d" 其中 'd' 为指定字段，可能为已存在的数组
     * @param val 为指定字段设置的值，或数组新增的值
     * @param isSync 是否同步写入文件
     * @return 是否成功
     */
    Q_INVOKABLE bool add(const QString &path, const QVariant &value, bool isSync = true);

    /**
     * @brief remove 在配置中移除指定字段或数组元素
     * @param path 示例："a.b.c.d" 或 "a.b.c.d[i]"，其中 'd' 为指定字段
     * @return 是否成功
     */
    Q_INVOKABLE bool remove(const QString &path, bool isSync = true);

    /**
     * @brief clearList 在配置中清空指定字段的数组，若指定字段的值不为数组则无效
     * @param path 示例："a.b.c.d" 其中 'd' 为指定字段
     * @return 是否成功
     */
    Q_INVOKABLE bool clearList(const QString &path, bool isSync = true);

    bool readReady = false;

signals:
    void configChanged(const QVariant path = "", const QVariant value = QVariant());
    void fileRead();

private:
    QJsonObject readJsonFile(const QString &fileName);
    bool writeJsonFile(const QJsonObject &json, const QString &fileName);
    QVariant normalize(const QVariant &v);
    QString fileName{""};
    QVariant config{};
    QTimer writeFileDebouncer;
};

#endif // CONFIGFILEMANAGER_H
