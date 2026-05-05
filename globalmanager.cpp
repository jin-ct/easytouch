#include "globalmanager.h"

GlobalManager* GlobalManager::instance = nullptr;

GlobalManager::GlobalManager(QObject *parent)
    : QObject{parent}
{
    m_funs = new Functions(this);
    m_fileHelper = new FileHelper(this);
    m_notification = new NotificationHelper(this);
    m_updateHelper = new UpdateHelper(this);
}
