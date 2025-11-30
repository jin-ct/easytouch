#ifndef NOTIFICATIONHELPER_H
#define NOTIFICATIONHELPER_H

#include <QObject>
#include <QString>

class NotificationHelper : public QObject
{
    Q_OBJECT
public:
    explicit NotificationHelper(QObject *parent = nullptr);
    ~NotificationHelper();

    Q_INVOKABLE void showNotification(const QString &id, const QString &title, const QString &message);

signals:
    void notificationClicked(const QString &id);
};

#endif // NOTIFICATIONHELPER_H
