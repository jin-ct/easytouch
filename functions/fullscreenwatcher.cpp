#include "fullscreenwatcher.h"
#include <QDebug>

bool isFullscreenWindow(HWND hwnd) {
    if (!IsWindowVisible(hwnd)) return false;
    if (IsIconic(hwnd)) return false;

    // 过滤桌面 / 任务栏 / WorkerW
    wchar_t className[256];
    GetClassNameW(hwnd, className, 256);
    if (wcscmp(className, L"Shell_TrayWnd") == 0) return false;  // 任务栏
    if (wcscmp(className, L"Progman") == 0) return false;        // 桌面
    if (wcscmp(className, L"WorkerW") == 0) return false;        // 桌面第二层

    WINDOWPLACEMENT wp;
    wp.length = sizeof(WINDOWPLACEMENT);
    if (GetWindowPlacement(hwnd, &wp)) {
        if (wp.showCmd == SW_SHOWMAXIMIZED)
            return false;
    }

    RECT rect;
    GetWindowRect(hwnd, &rect);

    QScreen *screen = QGuiApplication::screenAt(QPoint(rect.left, rect.top));
    if (!screen) screen = QGuiApplication::primaryScreen();

    QRect s = screen->geometry();

    return rect.left <= s.left() &&
           rect.top <= s.top() &&
           rect.right >= s.right() &&
           rect.bottom >= s.bottom();
}

// ---------------- Worker ----------------

FullscreenWorker::FullscreenWorker(QObject *parent)
    : QObject(parent)
{
}

void FullscreenWorker::process() {
    running = true;
    while (running) {
        HWND hwnd = GetForegroundWindow();

        if (!hwnd) {
            QThread::msleep(150);
            continue;
        }

        // 过滤桌面/任务栏（双保险）
        wchar_t className[256];
        GetClassNameW(hwnd, className, 256);
        if (wcscmp(className, L"Shell_TrayWnd") == 0 ||
            wcscmp(className, L"Progman") == 0 ||
            wcscmp(className, L"WorkerW") == 0)
        {
            QThread::msleep(150);
            continue;
        }

        bool fullscreen = isFullscreenWindow(hwnd);
        // qDebug() << fullscreen;

        if (fullscreen != lastState) {
            lastState = fullscreen;

            WCHAR title[256] = {0};
            GetWindowTextW(hwnd, title, 255);
            QString winTitle = QString::fromWCharArray(title);

            if (fullscreen)
                emit fullscreenEntered(winTitle);
            else
                emit fullscreenExited(winTitle);
        }

        QThread::msleep(150);
    }
    running = false;
}

// ---------------- Watcher ----------------

FullscreenWatcher::FullscreenWatcher(QObject *parent)
    : QObject(parent)
{
    start();
}

FullscreenWatcher::~FullscreenWatcher() {
    stop();
}

void FullscreenWatcher::start()
{
    // 如果已经在运行，先停止
    if (workerThread.isRunning()) {
        stop();
    }

    worker = new FullscreenWorker(nullptr);
    worker->moveToThread(&workerThread);

    connect(&workerThread, &QThread::started, worker, &FullscreenWorker::process);

    connect(worker, &FullscreenWorker::fullscreenEntered, this, &FullscreenWatcher::fullscreenEntered);
    connect(worker, &FullscreenWorker::fullscreenExited, this, &FullscreenWatcher::fullscreenExited);

    workerThread.start();
}

void FullscreenWatcher::stop()
{
    if (!workerThread.isRunning()) {
        return;
    }

    if (worker) {
        worker->running = false;
    }
    workerThread.quit();
    workerThread.wait();
    if (worker) {
        worker->deleteLater();
        worker = nullptr;
    }
}
