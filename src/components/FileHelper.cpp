#include "FileHelper.h"
#include <QFileDialog>
#include <QStandardPaths>
#include <QDateTime>
#include <QFile>

FileHelper::FileHelper(QObject *parent)
    : QObject{parent}
{}

QVariant FileHelper::openFolderDialog(const QVariant &title, const QVariant &initialDir)
{
    QString dir = initialDir.toString().trimmed().isEmpty()
        ? desktopFolder().toString()
        : initialDir.toString();
    QString caption = title.toString().trimmed().isEmpty()
        ? QObject::tr("选择文件夹")
        : title.toString();
    QString selected = QFileDialog::getExistingDirectory(
        nullptr,
        caption,
        dir,
        QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks
    );
    return QVariant(selected);
}

QVariant FileHelper::desktopFolder()
{
    return QVariant(QStandardPaths::writableLocation(QStandardPaths::DesktopLocation));
}

QVariant FileHelper::getNowDateTimeNameFilePath(const QVariant &path, const QVariant &extName, const QVariant &isDebounce)
{
    QString dateString = QDate::currentDate().toString("yyyy-MM-dd");
    QDir dir(path.toString() + "/" + dateString);
    if (!dir.exists()) {
        QDir().mkpath(path.toString() + "/" + dateString);
    }
    QString timeString = QTime::currentTime().toString("hh时mm分ss秒");
    QString fileName = timeString + "." + extName.toString();
    if (!isDebounce.toBool()) {
        int index = 1;
        while (dir.exists(fileName)) {
            fileName = QString("%1-%2.%3").arg(timeString).arg(index++).arg(extName.toString());
        }
    }
    return QVariant(dir.filePath(fileName));
}
