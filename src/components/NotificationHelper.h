#ifndef NOTIFICATIONHELPER_H
#define NOTIFICATIONHELPER_H

#include <QObject>
#include <QString>
#include <QMenu>
#include <QPoint>

class NotificationHelper : public QObject
{
    Q_OBJECT
public:
    explicit NotificationHelper(QObject *parent = nullptr);
    ~NotificationHelper();

    Q_INVOKABLE void showNotification(const QString &id, const QString &title, const QString &message, int millisecondsTimeoutHint = 5000);

signals:
    void notificationClicked(const QString &id);
    void showContentMenu(QPoint anchor);

private:
};

#endif // NOTIFICATIONHELPER_H
