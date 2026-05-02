#ifndef GLOBALMANAGER_H
#define GLOBALMANAGER_H

#include <QObject>
#include "functions/functions.h"
#include "functions/filehelper.h"
#include "functions/notificationhelper.h"
#include "functions/updatehelper.h"
#include "functions/mousehook.h"

class GlobalManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(Functions* funs READ functions NOTIFY funsChanged)
    Q_PROPERTY(FileHelper* fileHelper READ fileHelper NOTIFY fileHelperChanged)
    Q_PROPERTY(NotificationHelper* notification READ notification NOTIFY notificationChanged)
    Q_PROPERTY(UpdateHelper* updateHelper READ updateHelper NOTIFY updateHelperChanged)
    Q_PROPERTY(MouseHook* mouseHook READ mouseHook NOTIFY mouseHookChanged)
public:
    explicit GlobalManager(QObject *parent = nullptr);

    Functions* functions() const { return m_funs; }
    FileHelper* fileHelper() const { return m_fileHelper; }
    NotificationHelper* notification() const { return m_notification; }
    UpdateHelper* updateHelper() const { return m_updateHelper; }
    MouseHook* mouseHook() const { return MouseHook::instance(); }

signals:
    void funsChanged();
    void fileHelperChanged();
    void notificationChanged();
    void updateHelperChanged();
    void mouseHookChanged();

private:
    Functions *m_funs;
    FileHelper *m_fileHelper;
    NotificationHelper *m_notification;
    UpdateHelper *m_updateHelper;

};

#endif // GLOBALMANAGER_H
