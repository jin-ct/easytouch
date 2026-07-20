#include "NotificationHelper.h"
#include <QSystemTrayIcon>
#include <QAction>
#include <QApplication>
#include <QCursor>
#include <QGuiApplication>
#include <QScreen>
#include <QTimer>
#include <dwmapi.h>

namespace {

constexpr int kTouchOrLostCursorDistPx = 10; // 光标离图标超过此距离时视为触控/漂移，先把光标移到图标再弹出

int distSquaredPointToRect(const QPoint &p, const QRect &r)
{
    if (!r.isValid())
        return (1 << 30);
    int dx = 0;
    if (p.x() < r.left())
        dx = r.left() - p.x();
    else if (p.x() > r.right())
        dx = p.x() - r.right();
    int dy = 0;
    if (p.y() < r.top())
        dy = r.top() - p.y();
    else if (p.y() > r.bottom())
        dy = p.y() - r.bottom();
    return dx * dx + dy * dy;
}

} // namespace

class NotificationHelperPrivate {
public:
    QSystemTrayIcon *tray = nullptr;
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

    d->tray->setContextMenu(nullptr);
    connect(d->tray, &QSystemTrayIcon::activated, this, [=](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Context || reason == QSystemTrayIcon::Trigger) {
            const QRect iconRect = d->tray->geometry();
            const QPoint cur = QCursor::pos();

            const int touchThreshSq = kTouchOrLostCursorDistPx * kTouchOrLostCursorDistPx;
            const bool cursorNearIcon = iconRect.isValid() && distSquaredPointToRect(cur, iconRect) <= touchThreshSq;

            // 触控时光标常未落在图标上，将光标移到图标中心作为近似触点
            QPoint anchor = cur;
            if (!cursorNearIcon && iconRect.isValid()) {
                QCursor::setPos(iconRect.center());
                anchor = QCursor::pos();
            }

            emit showContentMenu(anchor);
        }
    });

    d->tray->show();
    d->tray->setToolTip("易触控");

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

void NotificationHelper::showNotification(const QString &id, const QString &title, const QString &message, int millisecondsTimeoutHint)
{
    auto d = reinterpret_cast<NotificationHelperPrivate*>(this->property("_d").value<void*>());
    d->lastId = id;

    // 弹出通知（系统托盘通知）
    d->tray->showMessage(title, message, QSystemTrayIcon::Information, millisecondsTimeoutHint);
}