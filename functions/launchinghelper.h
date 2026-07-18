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
#include <QMap>
#include <QElapsedTimer>

struct ProcState {
    std::wstring imagePath{};
    DWORD parentPid{0};
    bool startedSignaled{false};
    bool windowShownSignaled{false};
    qsizetype icon_imgIndex{};
    std::wstring windowTitle{};
};

struct AppInfoItem
{
    bool enableHelper{true};
    QString appName{""};
    int duration{0};  // 从监测到进程到显示窗口所用时间
    bool isShowWindow{false};
    QString exePath;
};

class LaunchingMonitor : public QObject
{
    Q_OBJECT
public:
    explicit LaunchingMonitor(QObject *parent = nullptr);
    void process();

    ProcState getProcState(DWORD pid = 0);
    int getProcsCount();

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
    std::unordered_map<DWORD, ProcState> g_procs{};
    HWINEVENTHOOK g_winEventHook{nullptr};
    std::unordered_map<DWORD, DWORD> known{}; // pid -> parentPid
    QTimer* pollingTimer{};
};

class LaunchingHelper : public QObject
{
    Q_OBJECT
public:
    explicit LaunchingHelper(QObject *parent = nullptr);
    ~LaunchingHelper();

    Q_INVOKABLE void disableHelperForItem(const QVariant &exeName);
    Q_INVOKABLE void switchHelperForItem(const QVariant &exeName, bool enable);

signals:
    void loaded();
    void windowShown(DWORD pid);
    void processStarted(DWORD pid);
    void windowShownWithInfo(QVariant windowTile, QVariant exeName, QVariant exeIconId, QVariant cursorPos);
    void processStartedWithInfo(QVariant exeName, QVariant exeIconId, QVariant cursorPos, int duration = 0);

private:
    void loadAppList();
    void saveAppList();
    void addAppItem(const QString &exeName, const AppInfoItem &item);

    QThread monitorThread;
    LaunchingMonitor* monitor{nullptr};
    QMap<QString, AppInfoItem> appList;
    QElapsedTimer launchingRecordTimer;
};

#endif // LAUNCHINGHELPER_H
