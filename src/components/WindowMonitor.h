#ifndef WINDOWMONITOR_H
#define WINDOWMONITOR_H

#include <QObject>
#include <QThread>
#include <QRect>
#include <QMutex>
#include <QTimer>
#include <dwmapi.h>
#include <psapi.h>
#include <cstdio>
#include <cwchar>

struct WindowInfo {
    HWND hwnd{};
    QString title{""};
    QString exeName{""};
    QString exePath{""};
    QRect size{};
    std::wstring className{};
    LONG style{};
    LONG exStyle{};
};

class WindowMonitorWorker : public QObject
{
    Q_OBJECT
public:
    WindowMonitorWorker();
    ~WindowMonitorWorker();
    void process();

    WindowInfo getTopWindow();

    static WindowMonitorWorker* instance;

public slots:
    void UpdateTopWindow();

signals:
    void topWindowChanged(WindowInfo window);

private:
    bool IsActivatableAppWindow(HWND hwnd);
    HWND FindTopActivatableWindow();
    bool IsWindowCloaked(HWND hwnd);
    std::wstring GetExePath(DWORD pid);
    std::wstring GetExeName(std::wstring exePath);

    bool InstallHooks();
    void UninstallHooks();
    static void CALLBACK WinEventProc(HWINEVENTHOOK, DWORD, HWND, LONG, LONG, DWORD, DWORD);

    HWND g_lastTopHwnd{nullptr};
    HWINEVENTHOOK g_hooks[5]{};
    DWORD g_mainThreadId{0};

    QMutex mutex;
    WindowInfo topWindow{};
    QTimer* pollingTimer{};
};

class WindowMonitor : public QObject
{
    Q_OBJECT
public:
    WindowMonitor();
    ~WindowMonitor();
    static WindowMonitor* instance();

    WindowInfo getTopWindow();

signals:
    void topWindowChanged(WindowInfo window);

private:
    QThread workerThread{};
    WindowMonitorWorker* worker{};
    QMutex mutex;
};

#endif // WINDOWMONITOR_H
