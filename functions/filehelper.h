#ifndef FILEHELPER_H
#define FILEHELPER_H

#include <QObject>

class FileHelper : public QObject
{
    Q_OBJECT
public:
    explicit FileHelper(QObject *parent = nullptr);

    Q_INVOKABLE QVariant openFolderDialog(const QVariant &title, const QVariant &initialDir);
    Q_INVOKABLE QVariant desktopFolder() const;
    Q_INVOKABLE QVariant getNowDateTimeNameFilePath(const QVariant &path, const QVariant &extName, const QVariant &isDebounce);

signals:
};

#endif // FILEHELPER_H
