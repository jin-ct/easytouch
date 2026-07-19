#include "NotificationHelper.h"
#include <QSystemTrayIcon>
#include <QMenu>
#include <QAction>
#include <QApplication>
#include <QCursor>
#include <QGuiApplication>
#include <QScreen>
#include <QTimer>

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

// 以光标为左上角锚点，必要时向左/上翻转，使菜单落在此屏工作区内
QPoint menuPosFromCursor(const QPoint &cur, const QSize &menuSize, const QRect &avail)
{
    if (menuSize.isEmpty() || !avail.isValid())
        return cur;

    int x = cur.x();
    int y = cur.y();

    if (x + menuSize.width() > avail.left() + avail.width())
        x = cur.x() - menuSize.width();
    if (y + menuSize.height() > avail.top() + avail.height())
        y = cur.y() - menuSize.height();

    const int maxX = avail.left() + avail.width() - menuSize.width();
    const int maxY = avail.top() + avail.height() - menuSize.height();
    x = qBound(avail.left(), x, qMax(avail.left(), maxX));
    y = qBound(avail.top(), y, qMax(avail.top(), maxY));
    return QPoint(x, y);
}

} // namespace

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
    d->menu->setStyleSheet(
        "QMenu {"
        "  background-color: #f6f7f9;"
        "  border: 1px solid #cfd3dc;"
        "  border-radius: 8px;"
        "  padding: 3px 3px;"
        "}"
        "QMenu::item {"
        "  padding: 4px 18px 4px 18px;"
        "  min-height: 24px;"
        "  margin: 1px 1px;"
        "  border-radius: 6px;"
        "  font-size: 13px;"
        "  color: #1c1c1e;"
        "}"
        "QMenu::item:selected {"
        "  background-color: #e3ecf8;"
        "  color: #0b57d0;"
        "}"
        "QMenu::item:pressed {"
        "  background-color: #d0dff0;"
        "}");
    d->menu->setWindowFlag(Qt::FramelessWindowHint, true);
    d->menu->setWindowFlag(Qt::NoDropShadowWindowHint, true);
    d->menu->setAttribute(Qt::WA_TranslucentBackground, true);

    QAction *settingsAction = new QAction("设置", d->menu);
    QAction *quitAction = new QAction("退出程序", d->menu);
    settingsAction->setIconVisibleInMenu(false);
    quitAction->setIconVisibleInMenu(false);
    d->menu->addAction(settingsAction);
    d->menu->addAction(quitAction);

    d->tray->setContextMenu(nullptr);
    connect(d->tray, &QSystemTrayIcon::activated, this, [=](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Context) {
            d->menu->adjustSize();
            const QSize menuSize = d->menu->sizeHint();
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

            QScreen *screen = QGuiApplication::screenAt(anchor);
            if (!screen)
                screen = QGuiApplication::screenAt(iconRect.center());
            if (!screen)
                screen = QGuiApplication::primaryScreen();
            const QRect avail = screen ? screen->availableGeometry() : QRect();

            if (screen && avail.isValid())
                d->menu->popup(menuPosFromCursor(anchor, menuSize, avail));
            else
                d->menu->popup(cur);
        } else if (reason == QSystemTrayIcon::Trigger) {
            emit startSettings();
        }
    });

    d->tray->show();
    d->tray->setToolTip("易触控");

    // 点击“退出”
    connect(quitAction, &QAction::triggered, this, [=] {
        if (d->menu->isVisible())
            d->menu->close();

        d->tray->hide();

        emit appQuit();
    });

    // 点击“设置”
    connect(settingsAction, &QAction::triggered, this, [=] {emit startSettings();});

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
