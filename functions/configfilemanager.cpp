#include "configfilemanager.h"
#include <QApplication>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QJSValue>

static const QString configDir = "config";
static const int kDebouncerInterval = 100;

ConfigFileManager::ConfigFileManager(QObject *parent)
    : QObject{parent}
{
    // 消抖触发文件保存
    connect(&writeFileDebouncer, &QTimer::timeout, this, [this](){
        writeFileDebouncer.stop();
        writeJsonFile(config.toJsonObject(), this->fileName);
    });
}

ConfigFileManager::ConfigFileManager(const QString &fileName, QObject *parent)
    : fileName(fileName), QObject{parent}
{
    // 消抖触发文件保存
    connect(&writeFileDebouncer, &QTimer::timeout, this, [this](){
        writeFileDebouncer.stop();
        writeJsonFile(config.toJsonObject(), this->fileName);
    });
}

QVariant ConfigFileManager::readConfigFile()
{
    config = readJsonFile(fileName).toVariantMap();
    readReady = true;
    QTimer::singleShot(0, this, [this](){
        emit fileRead();
        emit configChanged();
    });
    return config;
}

bool ConfigFileManager::writeConfigFile()
{
    return writeJsonFile(config.toJsonObject(), fileName);
}

void ConfigFileManager::writeConfigFileDebounced()
{
    writeFileDebouncer.start(kDebouncerInterval);
}

void ConfigFileManager::setFileName(const QString &fileName)
{
    this->fileName = fileName;
}

QVariant ConfigFileManager::getConfigObject()
{
    return config;
}

QVariant ConfigFileManager::get(const QString &path)
{
    QStringList keys = path.split('.');

    QVariant cur = config;

    for (const auto &k : keys)
    {
        if (k.contains('['))
        {
            QString name = k.left(k.indexOf('['));
            int index = k.mid(k.indexOf('[')+1)
                            .remove(']').toInt();

            cur = cur.toMap()[name].toList()[index];
        }
        else
        {
            cur = cur.toMap()[k];
        }
    }

    return cur;
}

bool ConfigFileManager::set(const QString &path, const QVariant &val, bool isSync)
{
    if (path.isEmpty())
        return false;

    // 解析路径
    struct Token
    {
        QString key;     // map key
        int index = -1;  // list index，-1表示不是数组项
    };

    QVector<Token> tokens;

    QString buf;
    for (int i = 0; i < path.size(); ++i)
    {
        QChar c = path[i];

        if (c == '.')
        {
            if (!buf.isEmpty()) {
                tokens.push_back({buf, -1});
                buf.clear();
            }
        }
        else if (c == '[')
        {
            Token t;
            t.key = buf;
            buf.clear();

            int end = path.indexOf(']', i);
            if (end < 0) return false;

            t.index = path.mid(i + 1, end - i - 1).toInt();
            tokens.push_back(t);

            i = end;
        }
        else
        {
            buf += c;
        }
    }

    if (!buf.isEmpty())
        tokens.push_back({buf, -1});

    if (tokens.isEmpty())
        return false;

    // 递归写入
    std::function<QVariant(QVariant&, int)> write =
        [&](QVariant& node, int level) -> QVariant
    {
        const Token& tk = tokens[level];
        bool last = (level == tokens.size() - 1);

        QVariantMap map = node.toMap();

        // 普通对象字段
        if (tk.index < 0)
        {
            if (last)
            {
                map[tk.key] = val;
            }
            else
            {
                QVariant child = map.value(tk.key);
                if (!child.isValid())
                {
                    if (tokens[level+1].index > -1) //下一层是数组
                        child = QVariantList();
                    else
                        child = QVariantMap();
                }
                map[tk.key] = write(child, level + 1);
            }

            return map;
        }

        // 数组
        QVariantList list = map.value(tk.key).toList();

        while (list.size() <= tk.index)
            list.append(QVariant());

        if (last)
        {
            list[tk.index] = val;
        }
        else
        {
            QVariant child = list[tk.index];
            list[tk.index] = write(child, level + 1);
        }

        map[tk.key] = list;
        return map;
    };

    config = write(config, 0).toMap();
    emit configChanged(path, val);
    if (isSync)
        writeConfigFile();
    return true;
}

bool ConfigFileManager::add(const QString &path, const QVariant &value, bool isSync)
{
    if (path.isEmpty())
        return false;
    if (!value.isValid())
        return false;
    QVariant val = normalize(value);

    QVariant cur = get(path);
    if (cur.userType() == QMetaType::QVariantList) {
        QVariantList list = cur.toList();
        list.append(val);
        set(path, list, isSync);
    } else {
        set(path, val, isSync);
    }
    return true;
}

bool ConfigFileManager::remove(const QString &path, bool isSync)
{
    if (path.isEmpty())
        return false;

    QStringList keys = path.split('.');

    QVariant cur = config;
    int l_index = -1;
    QString l_name = "";

    for (int i = 0; i < keys.count(); ++i)
    {
        if (keys[i].contains('['))
        {
            QString name = keys[i].left(keys[i].indexOf('['));
            int index = keys[i].mid(keys[i].indexOf('[')+1)
                            .remove(']').toInt();

            // 最后一个数组不用展开
            if (i == keys.count() - 1) {
                cur = cur.toMap()[name];
                l_index = index;
                l_name = name;
                break;
            }

            cur = cur.toMap()[name].toList()[index];
        }
        else
        {
            // 忽略最后一个字段
            if (i == keys.count() - 1) {
                l_name = keys[i];
                break;
            }
            cur = cur.toMap()[keys[i]];
        }
    }

    bool success = false;

    if (cur.userType() == QMetaType::QVariantList) {
        keys.pop_back();
        QString listPath = keys.join('.') + "." + l_name;
        QVariantList list = cur.toList();
        list.remove(l_index);
        success = set(listPath, list, isSync);
    } else {
        keys.pop_back();
        QString objPath = keys.join('.');
        QVariantMap obj = cur.toMap();
        obj.remove(keys.last());
        success = set(objPath, obj, isSync);
    }

    return success;
}

bool ConfigFileManager::clearList(const QString &path, bool isSync)
{
    if (path.isEmpty())
        return false;

    QVariant cur = get(path);
    if (cur.userType() != QMetaType::QVariantList)
        return false;

    return set (path, QVariantList(), isSync);
}

QJsonObject ConfigFileManager::readJsonFile(const QString &fileName)
{
    if (fileName.isEmpty())
        return QJsonObject();

    QString filePath = qApp->applicationDirPath() + "/" + configDir + "/" + fileName;

    if (!QFileInfo::exists(filePath)) {
        qDebug() << "ConfigFileManager::readJsonFile File Not Exists";
        return QJsonObject();
    }

    QFile file(filePath);
    file.open(QIODevice::ReadOnly);

    QByteArray data = file.readAll();
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(data);

    return doc.object();
}

bool ConfigFileManager::writeJsonFile(const QJsonObject &json, const QString &fileName)
{
    if (fileName.isEmpty())
        return false;

    QString filePath = qApp->applicationDirPath() + "/" + configDir + "/" + fileName;

    QDir fileDir = QFileInfo(filePath).dir();
    if (!fileDir.exists()) {
        if (!fileDir.mkpath(fileDir.absolutePath())) {
            qWarning() << "ConfigFileManager::writeJsonFile Make Path Error:" << fileDir.absolutePath();
            return false;
        }
    }

    QJsonDocument doc(json);

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "ConfigFileManager::writeJsonFile Open File Error";
        return false;
    }

    file.write(doc.toJson(QJsonDocument::Indented));
    file.close();
    return true;
}

QVariant ConfigFileManager::normalize(const QVariant &v)
{
    QVariant obj = v;
    if (obj.canConvert<QJSValue>()) {
        QJSValue js = obj.value<QJSValue>();
        obj = js.toVariant();
    }
    return obj;
}