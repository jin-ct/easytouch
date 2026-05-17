#ifndef LAUNCHINGHELPER_H
#define LAUNCHINGHELPER_H

#include <QObject>
#include <QThread>
#include <windows.h>
#include <tlhelp32.h>
#include <string>
#include <unordered_map>
#include <QMutex>
#include <QTimer>
#include <QImage>

struct ProcState {
    std::wstring imagePath{};
    DWORD parentPid{0};
    bool startedSignaled{false};
    bool windowShownSignaled{false};
    QImage icon{};
    std::wstring windowTitle{};
};

class LaunchingMonitor : public QObject
{
    Q_OBJECT
public:
    explicit LaunchingMonitor(QObject *parent = nullptr);
    void process();

    ProcState getProcState(DWORD pid = 0);

    static void WINAPI WinEventCallback(
        HWINEVENTHOOK /*hWinEventHook*/,
        DWORD event,
        HWND hwnd,
        LONG idObject,
        LONG idChild,
        DWORD /*dwEventThread*/,
        DWORD /*dwmsEventTime*/
        );

    static std::wstring ToLowerW(std::wstring s);
    static std::wstring BaseNameW(const std::wstring& path);
    static bool IsUserSessionProcess(DWORD pid);
    static std::wstring GetProcessImagePathW(DWORD pid);
    static std::wstring GetProcessImagePathRetryW(DWORD pid, DWORD maxWaitMs = 200);
    static bool IsTopLevelMainWindowCandidate(HWND hwnd);

    static LaunchingMonitor* instance;

signals:
    void windowShown(DWORD pid);
    void processStarted(DWORD pid);

private:
    void startMonitoring();
    void SignalProcessStarted(DWORD pid, DWORD parentPid);
    QImage getExeIcon(std::wstring path);

    QMutex m_mutex;
    std::unordered_map<DWORD, ProcState> g_procs;
    HWINEVENTHOOK g_winEventHook{nullptr};
    std::unordered_map<DWORD, DWORD> known; // pid -> parentPid
    QTimer* pollingTimer;
};

class LaunchingHelper : public QObject
{
    Q_OBJECT
public:
    explicit LaunchingHelper(QObject *parent = nullptr);
    ~LaunchingHelper();

signals:
    void loaded();
    void windowShown(DWORD pid);
    void processStarted(DWORD pid);
    void windowShownWithInfo(QVariant windowTile, QVariant exeName, QVariant exeIcon, QVariant cursorPos);
    void processStartedWithInfo(QVariant exeName, QVariant exeIcon, QVariant cursorPos);

private:
    QThread monitorThread;
    LaunchingMonitor* monitor{nullptr};
};

#endif // LAUNCHINGHELPER_H
