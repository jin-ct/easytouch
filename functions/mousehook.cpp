#include "mousehook.h"
#include <QDebug>
#include <QCursor>
#include <QMutexLocker>

static const int kHasMouseEventKeepDuration = 150;

Q_GLOBAL_STATIC(MouseHook, mouseHookInstance)

HHOOK MouseHook::g_mouseHook = nullptr;

MouseHook::MouseHook()
{
    qDebug() << "MouseHook线程启动";
}

MouseHook *MouseHook::instance()
{
    return mouseHookInstance();
}

void MouseHook::stop()
{
    quit();
    wait();
    qDebug() << "MouseHook线程退出";
}

void MouseHook::addIgnoreAreas(const QVariant &rect, QVariant idStr)
{
    QMutexLocker locker(&mutex);
    ignoreAreas.insert(idStr.toString(), rect.toRect());
}

void MouseHook::removeIgnoreAreas(QVariant idStr)
{
    QMutexLocker locker(&mutex);
    ignoreAreas.remove(idStr.toString());
}

LRESULT MouseHook::LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode == HC_ACTION) {
        const MSLLHOOKSTRUCT* info = reinterpret_cast<MSLLHOOKSTRUCT*>(lParam);
        switch (wParam) {
        case WM_LBUTTONDOWN:
            if (MouseHook::instance())
                QMetaObject::invokeMethod(
                    MouseHook::instance(),
                    "onMouse",
                    Qt::QueuedConnection,
                    0  // eventType: 鼠标按下
                    );
            break;
        case WM_MOUSEMOVE:
            if (MouseHook::instance())
                QMetaObject::invokeMethod(
                    MouseHook::instance(),
                    "onMouse",
                    Qt::QueuedConnection,
                    1  // eventType: 鼠标移动
                    );
            break;
        }
    }

    return CallNextHookEx(MouseHook::g_mouseHook, nCode, wParam, lParam);
}

void MouseHook::onMouse(int eventType)
{
    setHasMouseEvent();
    QPoint pos = QCursor::pos();
    switch (eventType) {
    case 0:   // 鼠标按下
        emit mousePressedUnfiltered(QVariant(pos));
        // 若在忽略区域直接退出
        for (auto i = ignoreAreas.cbegin(), end = ignoreAreas.cend(); i != end; ++i) {
            if (isRectContains(i.value(), pos))
                return;
        }
        emit mousePressed(QVariant(pos));
        break;
    case 1:   // 鼠标移动
        emit mouseMoved(QVariant(pos));
        break;
    }
}

void MouseHook::run()
{
    installHook();
    exec();
    uninstallHook();
}

void MouseHook::installHook()
{
    if (g_mouseHook) {
        return;
    }
    g_mouseHook = SetWindowsHookEx(
        WH_MOUSE_LL,
        LowLevelMouseProc,
        GetModuleHandle(nullptr),
        0
        );
    emit installed();
    qDebug() << "WindowsMouseHookInstalled";
}

void MouseHook::uninstallHook()
{
    UnhookWindowsHookEx(g_mouseHook);
    g_mouseHook = nullptr;
    ignoreAreas.clear();
    emit uninstalled();
    qDebug() << "WindowsMouseHookUninstalled";
}

bool MouseHook::isRectContains(const QRect &rect, const QPoint &point)
{
    return rect.contains(point);
}

void MouseHook::setHasMouseEvent()
{
    hasMouseEvent = true;
    QTimer::singleShot(kHasMouseEventKeepDuration, this, [this](){
        hasMouseEvent = false;
    });
}
