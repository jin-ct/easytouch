#include "launchinghelper.h"
#include <QDebug>
#include <QMutexLocker>
#include <QFileInfo>
#include <unordered_set>
#include <shellapi.h>
#include <QCursor>

static const int kPollingIntervalMs = 20;

static const std::unordered_set<std::wstring> g_shellParentExeNames = {
    L"explorer.exe",
    L"startmenuexperiencehost.exe",
    L"searchhost.exe",
    L"searchapp.exe",
    L"shellexperiencehost.exe",
};

LaunchingMonitor* LaunchingMonitor::instance = nullptr;

LaunchingMonitor::LaunchingMonitor(QObject *parent) {
}

void LaunchingMonitor::process()
{
    qDebug() << "LaunchingMonitor线程已启动";
    // instance用于回调函数
    instance = this;
    // 监听窗口显示
    g_winEventHook = SetWinEventHook(
        EVENT_OBJECT_SHOW,
        EVENT_OBJECT_SHOW,
        nullptr,
        LaunchingMonitor::WinEventCallback,
        0,
        0,
        WINEVENT_OUTOFCONTEXT | WINEVENT_SKIPOWNPROCESS
        );
    if (!g_winEventHook) {
        qWarning() << "SetWinEventHook failed: " << GetLastError();
    }
    // 轮询监听进程启动
    startMonitoring();
}

ProcState LaunchingMonitor::getProcState(DWORD pid)
{
    QMutex mutex;
    QMutexLocker locker(&mutex);
    return g_procs[pid];
}

void WINAPI LaunchingMonitor::WinEventCallback(
    HWINEVENTHOOK /*hWinEventHook*/,
    DWORD event,
    HWND hwnd,
    LONG idObject,
    LONG idChild,
    DWORD /*dwEventThread*/,
    DWORD /*dwmsEventTime*/
    ) {
    if (!LaunchingMonitor::instance) return;
    if (event != EVENT_OBJECT_SHOW) return;
    if (idObject != OBJID_WINDOW) return;
    if (idChild != CHILDID_SELF) return;
    if (!hwnd) return;
    if (!IsTopLevelMainWindowCandidate(hwnd)) return;

    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (!pid) return;

    QMutexLocker locker(&LaunchingMonitor::instance->m_mutex);
    auto it = LaunchingMonitor::instance->g_procs.find(pid);
    if (it == LaunchingMonitor::instance->g_procs.end()) return;
    if (it->second.windowShownSignaled) return;

    // 如果启动时没拿到路径，这里补一次
    if (it->second.imagePath.empty() || it->second.imagePath == L"[Unknown]") {
        std::wstring p = GetProcessImagePathRetryW(pid);
        if (!p.empty()) it->second.imagePath = p;
        it->second.icon = LaunchingMonitor::instance->getExeIcon(p);
    }

    // 设置窗口标题
    wchar_t title[256] = {};
    GetWindowText(hwnd, title, 256);
    it->second.windowTitle = title;

    it->second.windowShownSignaled = true;
    emit LaunchingMonitor::instance->windowShown(pid);
    QTimer::singleShot(1000, LaunchingMonitor::instance, [=](){  // 1秒后删除该项数据
        LaunchingMonitor::instance->g_procs.erase(pid);
    });
}

std::wstring LaunchingMonitor::ToLowerW(std::wstring s) {
    for (auto& ch : s) {
        if (ch >= L'A' && ch <= L'Z') ch = (wchar_t)(ch - L'A' + L'a');
    }
    return s;
}

std::wstring LaunchingMonitor::BaseNameW(const std::wstring& path) {
    size_t pos = path.find_last_of(L"\\/");
    if (pos == std::wstring::npos) return path;
    return path.substr(pos + 1);
}

bool LaunchingMonitor::IsUserSessionProcess(DWORD pid) {
    DWORD curSid = 0, pidSid = 0;
    if (!ProcessIdToSessionId(GetCurrentProcessId(), &curSid)) return true;
    if (!ProcessIdToSessionId(pid, &pidSid)) return true;
    return curSid == pidSid;
}

std::wstring LaunchingMonitor::GetProcessImagePathW(DWORD pid) {
    HANDLE h = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!h) return L"";

    wchar_t buf[MAX_PATH];
    DWORD size = static_cast<DWORD>(std::size(buf));
    std::wstring path;
    if (QueryFullProcessImageNameW(h, 0, buf, &size)) {
        path.assign(buf, buf + size);
    }
    CloseHandle(h);
    return path;
}

std::wstring LaunchingMonitor::GetProcessImagePathRetryW(DWORD pid, DWORD maxWaitMs) {
    // 进程刚创建时，QueryFullProcessImageName 可能短时间失败，这里做轻量重试避免丢事件
    const DWORD step = 10;
    DWORD waited = 0;
    while (waited <= maxWaitMs) {
        std::wstring p = GetProcessImagePathW(pid);
        if (!p.empty()) return p;
        Sleep(step);
        waited += step;
    }
    return L"";
}

bool LaunchingMonitor::IsTopLevelMainWindowCandidate(HWND hwnd) {
    if (!IsWindow(hwnd)) return false;
    if (!IsWindowVisible(hwnd)) return false;
    if (GetAncestor(hwnd, GA_ROOT) != hwnd) return false;

    LONG_PTR style = GetWindowLongPtrW(hwnd, GWL_STYLE);
    if (style & WS_CHILD) return false;
    if (style & WS_DISABLED) return false;

    HWND owner = GetWindow(hwnd, GW_OWNER);
    if (owner) return false;

    return true;
}

void LaunchingMonitor::startMonitoring() {
    known.reserve(8192);

    // 启动时先做一次快照建表
    {
        HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if (snap != INVALID_HANDLE_VALUE) {
            PROCESSENTRY32W pe{};
            pe.dwSize = sizeof(pe);
            if (Process32FirstW(snap, &pe)) {
                do {
                    known.emplace(pe.th32ProcessID, pe.th32ParentProcessID);
                } while (Process32NextW(snap, &pe));
            }
            CloseHandle(snap);
        }
    }

    pollingTimer = new QTimer(this);
    connect(pollingTimer, &QTimer::timeout, this, [=]{
        HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        if (snap == INVALID_HANDLE_VALUE) {
            return;
        }

        PROCESSENTRY32W pe{};
        pe.dwSize = sizeof(pe);

        std::unordered_map<DWORD, DWORD> current; // pid -> parentPid
        current.reserve(8192);

        if (Process32FirstW(snap, &pe)) {
            do {
                current.emplace(pe.th32ProcessID, pe.th32ParentProcessID);
                if (known.find(pe.th32ProcessID) == known.end()) {
                    auto it = known.find(pe.th32ParentProcessID);
                    (void)it;
                    std::wstring parentPath = GetProcessImagePathRetryW(pe.th32ParentProcessID, 60);
                    std::wstring parentExe = ToLowerW(BaseNameW(parentPath));
                    if (g_shellParentExeNames.find(parentExe) == g_shellParentExeNames.end()) {
                        continue;
                    }

                    SignalProcessStarted(pe.th32ProcessID, pe.th32ParentProcessID);
                }
            } while (Process32NextW(snap, &pe));
        }

        CloseHandle(snap);
        known.swap(current);
    });
    pollingTimer->start(kPollingIntervalMs);
}

void LaunchingMonitor::SignalProcessStarted(DWORD pid, DWORD parentPid) {
    // 过滤系统 idle / system 等
    if (pid <= 4) return;
    if (!IsUserSessionProcess(pid)) return;

    std::wstring path = GetProcessImagePathRetryW(pid);
    if (path.empty()) {
        // 路径仍不可得：仍记录，后续由窗口事件/其它机会补全路径
        QMutexLocker locker(&m_mutex);
        auto& st = g_procs[pid];
        if (!st.startedSignaled) {
            st.imagePath = L"[Unknown]";
            st.parentPid = parentPid;
            st.startedSignaled = true;
            st.windowShownSignaled = false;
            st.windowTitle = L"";
            emit processStarted(pid);
        }
        return;
    }

    QMutexLocker locker(&m_mutex);
    auto& st = g_procs[pid];
    if (st.startedSignaled) return;

    st.imagePath = path;
    st.parentPid = parentPid;
    st.startedSignaled = true;
    st.windowShownSignaled = false;
    st.windowTitle = L"";
    st.icon = getExeIcon(path);

    emit processStarted(pid);
}

QImage LaunchingMonitor::getExeIcon(std::wstring path)
{
    HICON largeIcon = nullptr;

    // 提取第一个大图标
    ExtractIconExW(
        path.c_str(),
        0,
        &largeIcon,
        nullptr,
        1
        );

    QImage ico = QImage::fromHICON(largeIcon);
    DestroyIcon(largeIcon);
    return ico;
}

LaunchingHelper::LaunchingHelper(QObject *parent)
    : QObject{parent}
{
    monitor = new LaunchingMonitor;
    monitor->moveToThread(&monitorThread);

    connect(monitor, &LaunchingMonitor::processStarted, this, &LaunchingHelper::processStarted);
    connect(monitor, &LaunchingMonitor::windowShown, this, &LaunchingHelper::windowShown);

    connect(&monitorThread, &QThread::started, monitor, &LaunchingMonitor::process, Qt::QueuedConnection);

    connect(this, &LaunchingHelper::processStarted, this, [=](DWORD pid){
        QString exeName = QString::fromStdWString(monitor->getProcState(pid).imagePath).split("\\").last();
        emit processStartedWithInfo(exeName, monitor->getProcState(pid).icon, QCursor::pos());
    });
    connect(this, &LaunchingHelper::windowShown, this, [=](DWORD pid){
        QString exeName = QString::fromStdWString(monitor->getProcState(pid).imagePath).split("\\").last();
        auto st = monitor->getProcState(pid);
        emit windowShownWithInfo(QString::fromStdWString(st.windowTitle), exeName, st.icon, QCursor::pos());
    });

    monitorThread.start();
    emit loaded();
}

LaunchingHelper::~LaunchingHelper()
{
    monitorThread.quit();
    monitorThread.wait();
    if (monitor) {
        monitor->deleteLater();
        monitor = nullptr;
    }
    qDebug() << "LaunchingMonitor线程已退出";
}
