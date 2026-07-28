#include "WindowMonitor.h"
#include <QDebug>
#include <QMutexLocker>
#include <QTimer>

Q_GLOBAL_STATIC(WindowMonitor, windowMonitorInstance)

static const int kPollingIntervalMs = 150;

WindowMonitorWorker* WindowMonitorWorker::instance = nullptr;

WindowMonitor::WindowMonitor()
{
    worker = new WindowMonitorWorker;
    worker->moveToThread(&workerThread);
    connect(worker, &WindowMonitorWorker::topWindowChanged, this, &WindowMonitor::topWindowChanged);
    connect(&workerThread, &QThread::started, worker, &WindowMonitorWorker::process, Qt::QueuedConnection);
    workerThread.start();
}

WindowMonitor::~WindowMonitor()
{
    workerThread.quit();
    workerThread.wait();
    if (worker) {
        worker->deleteLater();
        worker = nullptr;
    }
    qDebug() << "WindowMonitor线程退出";
}

WindowMonitor *WindowMonitor::instance()
{
    return windowMonitorInstance();
}

WindowInfo WindowMonitor::getTopWindow()
{
    return worker->getTopWindow();
}

WindowMonitorWorker::WindowMonitorWorker()
{
}

WindowMonitorWorker::~WindowMonitorWorker()
{
    UninstallHooks();
}

void WindowMonitorWorker::process()
{
    qDebug() << "WindowMonitor线程启动";
    instance = this;
    InstallHooks();
    pollingTimer = new QTimer(this);
    connect(pollingTimer, &QTimer::timeout, this, &WindowMonitorWorker::UpdateTopWindow, Qt::QueuedConnection);
    pollingTimer->start(kPollingIntervalMs);
}

WindowInfo WindowMonitorWorker::getTopWindow()
{
    QMutexLocker locker(&mutex);
    return topWindow;
}

void WindowMonitorWorker::UpdateTopWindow()
{
    const HWND top = FindTopActivatableWindow();

    if (!top) {
        return;
    }

    {
        QMutexLocker locker(&mutex);
        if (top == topWindow.hwnd) {
            return;
        }
    }

    wchar_t title[512] = {};
    wchar_t className[256] = {};
    GetWindowTextW(top, title, static_cast<int>(std::size(title)));
    GetClassNameW(top, className, static_cast<int>(std::size(className)));

    DWORD pid = 0;
    GetWindowThreadProcessId(top, &pid);
    const std::wstring exePath = GetExePath(pid);
    const std::wstring exeName = GetExeName(exePath);

    RECT rc = {};
    GetWindowRect(top, &rc);

    const LONG style = GetWindowLongW(top, GWL_STYLE);
    const LONG exStyle = GetWindowLongW(top, GWL_EXSTYLE);

    {
        QMutexLocker locker(&mutex);
        topWindow.hwnd = top;
        topWindow.title = QString::fromStdWString(title);
        topWindow.exeName = QString::fromStdWString(exeName);
        topWindow.exePath = QString::fromStdWString(exePath);
        topWindow.size = QRect(rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top);
        topWindow.className = className;
        topWindow.style = style;
        topWindow.exStyle = exStyle;
    }
    emit topWindowChanged(topWindow);
}

bool WindowMonitorWorker::IsActivatableAppWindow(HWND hwnd)
{
    if (!IsWindow(hwnd) || !IsWindowVisible(hwnd)) {
        return false;
    }

    // 必须是顶层窗口
    if (GetAncestor(hwnd, GA_ROOT) != hwnd) {
        return false;
    }

    if (IsWindowCloaked(hwnd)) {
        return false;
    }

    if (!IsWindowEnabled(hwnd)) {
        return false;
    }

    const LONG style = GetWindowLongW(hwnd, GWL_STYLE);
    const LONG exStyle = GetWindowLongW(hwnd, GWL_EXSTYLE);

    // 不可激活
    if (exStyle & WS_EX_NOACTIVATE) {
        return false;
    }

    // 工具窗口（工具栏、浮动面板等）
    if (exStyle & WS_EX_TOOLWINDOW) {
        return false;
    }

    // 透明点击穿透层
    if (exStyle & WS_EX_TRANSPARENT) {
        return false;
    }

    // 无标题栏的弹出层通常不是主应用窗口
    if ((style & WS_POPUP) && !(style & WS_CAPTION) && !(exStyle & WS_EX_APPWINDOW)) {
        return false;
    }

    // 有所有者且未声明 APPWINDOW 的窗口（多为对话框/弹出层附属窗口）
    const HWND owner = GetWindow(hwnd, GW_OWNER);
    if (owner != nullptr && !(exStyle & WS_EX_APPWINDOW)) {
        return false;
    }

    // 标题为空且不是显式 APPWINDOW，通常是辅助层
    wchar_t title[512] = {};
    GetWindowTextW(hwnd, title, static_cast<int>(std::size(title)));
    if (title[0] == L'\0' && !(exStyle & WS_EX_APPWINDOW)) {
        return false;
    }

    return true;
}

HWND WindowMonitorWorker::FindTopActivatableWindow()
{
    HWND hwnd = GetTopWindow(nullptr);
    while (hwnd != nullptr) {
        if (IsActivatableAppWindow(hwnd)) {
            return hwnd;
        }
        hwnd = GetWindow(hwnd, GW_HWNDNEXT);
    }
    return nullptr;
}

bool WindowMonitorWorker::IsWindowCloaked(HWND hwnd)
{
    BOOL cloaked = FALSE;
    const HRESULT hr = DwmGetWindowAttribute(hwnd, DWMWA_CLOAKED, &cloaked, sizeof(cloaked));
    return SUCCEEDED(hr) && cloaked;
}

std::wstring WindowMonitorWorker::GetExePath(DWORD pid)
{
    HANDLE process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_VM_READ, FALSE, pid);
    if (!process) {
        process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    }
    if (!process) {
        return L"";
    }

    wchar_t path[MAX_PATH] = {};
    DWORD size = MAX_PATH;

    if (!QueryFullProcessImageNameW(process, 0, path, &size)) {
        GetModuleFileNameExW(process, nullptr, path, MAX_PATH);
    }

    CloseHandle(process);
    return std::wstring(path);
}

std::wstring WindowMonitorWorker::GetExeName(std::wstring exePath)
{
    const wchar_t* base = wcsrchr(exePath.c_str(), L'\\');
    return base ? (base + 1) : exePath.c_str();
}

bool WindowMonitorWorker::InstallHooks()
{
    constexpr DWORD events[] = {
        EVENT_SYSTEM_FOREGROUND,
        EVENT_SYSTEM_MOVESIZEEND,
        EVENT_OBJECT_SHOW,
        EVENT_OBJECT_HIDE,
        EVENT_OBJECT_REORDER,
    };

    for (size_t i = 0; i < std::size(events); ++i) {
        g_hooks[i] = SetWinEventHook(
            events[i], events[i],
            nullptr, WinEventProc,
            0, 0,
            WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS);
        if (!g_hooks[i]) {
            qDebug() << "WindowMonitor安装事件钩子失败:" << events[i]  << "(GetLastError=" << GetLastError() << ")";
            return false;
        }
    }
    return true;
}

void WindowMonitorWorker::UninstallHooks()
{
    for (HWINEVENTHOOK& hook : g_hooks) {
        if (hook) {
            UnhookWinEvent(hook);
            hook = nullptr;
        }
    }
}

void WindowMonitorWorker::WinEventProc(HWINEVENTHOOK, DWORD, HWND, LONG, LONG, DWORD, DWORD)
{
    if (WindowMonitorWorker::instance) {
        QMetaObject::invokeMethod(
            WindowMonitorWorker::instance,
            "UpdateTopWindow",
            Qt::QueuedConnection
            );
    }
}