#include "NotificationHelper.h"
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QApplication>
#include <QTimer>

class NotificationHelperPrivate {
public:
    QSystemTrayIcon *tray = nullptr;
    QMenu *menu = nullptr;
    QString lastId;
};

NotificationHelper::NotificationHelper(QObject *parent)
    : QObject(parent)
{
    auto d = new NotificationHelperPrivate();
    this->setProperty("_d", QVariant::fromValue<void*>(d));

    // 创建托盘图标
    d->tray = new QSystemTrayIcon(nullptr);
    d->tray->setIcon(QIcon(":/icon/icon.ico"));

    // 创建右键菜单
    d->menu = new QMenu();
    QAction *quitAction = new QAction("退出程序", d->menu);
    d->menu->addAction(quitAction);

    d->tray->setContextMenu(d->menu);
    d->tray->show();
    d->tray->setToolTip("易触控");

    // 点击“退出”
    connect(quitAction, &QAction::triggered, this, [=] {
        if (d->menu->isVisible())
            d->menu->close();

        d->tray->hide();

        emit appQuit();
    });

    // 点击托盘通知
    connect(d->tray, &QSystemTrayIcon::messageClicked, this, [this, d] {
        if (!d->lastId.isEmpty()) {
            emit notificationClicked(d->lastId);
        }
    });
}

NotificationHelper::~NotificationHelper()
{
    delete reinterpret_cast<NotificationHelperPrivate*>(this->property("_d").value<void*>());
}

void NotificationHelper::showNotification(const QString &id, const QString &title, const QString &message)
{
    auto d = reinterpret_cast<NotificationHelperPrivate*>(this->property("_d").value<void*>());
    d->lastId = id;

    // 弹出通知（系统托盘通知）
    d->tray->showMessage(title, message, QSystemTrayIcon::Information, 5000);
}
