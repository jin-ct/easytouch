#ifndef WINDOWMONITOR_H
#define WINDOWMONITOR_H

#include <QThread>
#include <QRect>
#include <QMutex>
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

class WindowMonitor : public QThread
{
    Q_OBJECT
public:
    WindowMonitor();
    static WindowMonitor* instance();
    void stop();

    const WindowInfo& getTopWindow();

signals:
    void topWindowChanged(const WindowInfo &window);

protected:
    void run() override;

private:
    void UpdateTopWindow();
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
};

#endif // WINDOWMONITOR_H
