#include "MouseHook.h"
#include <QDebug>
#include <QCursor>
#include <QMutexLocker>

static const int kHasMouseEventKeepDuration = 800;

Q_GLOBAL_STATIC(MouseHook, mouseHookInstance)

MouseHookWorker* MouseHookWorker::instance = nullptr;
HHOOK MouseHookWorker::g_mouseHook = nullptr;

MouseHook::MouseHook()
{
    worker = new MouseHookWorker;
    worker->moveToThread(&workerThread);
    connect(worker, &MouseHookWorker::mousePressedUnfiltered, this, &MouseHook::mousePressedUnfiltered);
    connect(worker, &MouseHookWorker::mousePressed, this, &MouseHook::mousePressed);
    connect(worker, &MouseHookWorker::mouseMoved, this, &MouseHook::mouseMoved);
    connect(worker, &MouseHookWorker::installed, this, &MouseHook::installed);
    connect(worker, &MouseHookWorker::uninstalled, this, &MouseHook::uninstalled);
    connect(&workerThread, &QThread::started, worker, &MouseHookWorker::process, Qt::QueuedConnection);
    workerThread.start();
}

MouseHook::~MouseHook()
{
    workerThread.quit();
    workerThread.wait();
    if (worker) {
        worker->deleteLater();
        worker = nullptr;
    }
    qDebug() << "MouseHook线程退出";
}

void MouseHookWorker::process()
{
    qDebug() << "MouseHook线程启动";
    instance = this;
    // 恢复 hasMouseEvent 变量
    recordTimer = new QTimer(this);
    connect(recordTimer, &QTimer::timeout, this, [this](){
        QMutexLocker locker(&mutex);
        hasMouseEvent = false;
        recordTimer->stop();
    });
    installHook();
}

MouseHook *MouseHook::instance()
{
    return mouseHookInstance();
}

void MouseHook::addIgnoreAreas(const QVariant &rect, QVariant idStr)
{
    worker->addIgnoreAreas(rect.toRect(), idStr.toString());
}

void MouseHook::removeIgnoreAreas(QVariant idStr)
{
    worker->removeIgnoreAreas(idStr.toString());
}

bool MouseHook::getHasMouseEvent()
{
    return worker->getHasMouseEvent();
}

MouseHookWorker::MouseHookWorker()
{}

MouseHookWorker::~MouseHookWorker()
{
    uninstallHook();
}

void MouseHookWorker::addIgnoreAreas(const QRect &rect, QString idStr)
{
    QMutexLocker locker(&mutex);
    ignoreAreas.insert(idStr, rect);
}

void MouseHookWorker::removeIgnoreAreas(QString idStr)
{
    QMutexLocker locker(&mutex);
    ignoreAreas.remove(idStr);
}

bool MouseHookWorker::getHasMouseEvent()
{
    QMutexLocker locker(&mutex);
    return hasMouseEvent;
}

void MouseHookWorker::onMouse(QEvent::Type eventType)
{
    setHasMouseEvent();
    QPoint pos = QCursor::pos();
    switch (eventType) {
    case QEvent::MouseButtonPress:
        emit mousePressedUnfiltered(QVariant(pos));
        // 若在忽略区域直接退出
        for (auto i = ignoreAreas.cbegin(), end = ignoreAreas.cend(); i != end; ++i) {
            if (isRectContains(i.value(), pos))
                return;
        }
        emit mousePressed(QVariant(pos));
        break;
    case QEvent::MouseMove:
        emit mouseMoved(QVariant(pos));
        break;
    }
}

void MouseHookWorker::installHook()
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

void MouseHookWorker::uninstallHook()
{
    UnhookWindowsHookEx(g_mouseHook);
    g_mouseHook = nullptr;
    ignoreAreas.clear();
    emit uninstalled();
    qDebug() << "WindowsMouseHookUninstalled";
}

bool MouseHookWorker::isRectContains(const QRect &rect, const QPoint &point)
{
    return rect.contains(point);
}

void MouseHookWorker::setHasMouseEvent()
{
    QMutexLocker locker(&mutex);
    hasMouseEvent = true;
    recordTimer->start(kHasMouseEventKeepDuration);
}

LRESULT MouseHookWorker::LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode == HC_ACTION) {
        const MSLLHOOKSTRUCT* info = reinterpret_cast<MSLLHOOKSTRUCT*>(lParam);
        switch (wParam) {
        case WM_LBUTTONDOWN:
            if (MouseHookWorker::instance)
                QMetaObject::invokeMethod(
                    MouseHookWorker::instance,
                    "onMouse",
                    Qt::QueuedConnection,
                    QEvent::MouseButtonPress
                    );
            break;
        case WM_MOUSEMOVE:
            if (MouseHookWorker::instance)
                QMetaObject::invokeMethod(
                    MouseHookWorker::instance,
                    "onMouse",
                    Qt::QueuedConnection,
                    QEvent::MouseMove
                    );
            break;
        }
    }

    return CallNextHookEx(MouseHookWorker::g_mouseHook, nCode, wParam, lParam);
}
