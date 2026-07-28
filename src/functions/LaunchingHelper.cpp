#include "LaunchingHelper.h"
#include <QDebug>
#include <QMutexLocker>
#include <QFileInfo>
#include <unordered_set>
#include <shellapi.h>
#include <shlobj.h>
#include <initguid.h>
#include <commoncontrols.h>
#include <winternl.h>
#include <QCursor>
#include "../components/QmlImageProvider.h"
#include "../components/MouseHook.h"
#include "../ConfigManager.h"

#ifndef STATUS_INFO_LENGTH_MISMATCH
#define STATUS_INFO_LENGTH_MISMATCH ((NTSTATUS)0xC0000004L)
#endif

using NtQuerySystemInformation_t =
    NTSTATUS (NTAPI*)(
        SYSTEM_INFORMATION_CLASS,
        PVOID,
        ULONG,
        PULONG);

static NtQuerySystemInformation_t pNtQuerySystemInformation =
    reinterpret_cast<NtQuerySystemInformation_t>(
        GetProcAddress(GetModuleHandleW(L"ntdll.dll"),
                       "NtQuerySystemInformation"));

static const std::unordered_set<std::wstring> g_shellParentExeNames = {
    L"explorer.exe",
    L"startmenuexperiencehost.exe",
    L"searchhost.exe",
    L"searchapp.exe",
    L"shellexperiencehost.exe",
};

LaunchingMonitor* LaunchingMonitor::instance = nullptr;

LaunchingMonitor::LaunchingMonitor() {
}

LaunchingMonitor::~LaunchingMonitor()
{
    if (g_winEventHook) {
        UnhookWinEvent(g_winEventHook);
        g_winEventHook = nullptr;
    }
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
    connect(MouseHook::instance(), &MouseHook::mousePressedUnfiltered, this, [this](){
        pollingTimer->start(pollingFastIntervalMs);
        QTimer::singleShot(500, this, [this](){
            pollingTimer->start(pollingIntervalMs);
        });
    }, Qt::QueuedConnection);
}

ProcState LaunchingMonitor::getProcState(DWORD pid)
{
    QMutex mutex;
    QMutexLocker locker(&mutex);
    return g_procs[pid];
}

int LaunchingMonitor::getProcsCount()
{
    QMutex mutex;
    QMutexLocker locker(&mutex);
    return g_procs.size();
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

    int icon_imgIndex = 0;

    {
        QMutexLocker locker(&LaunchingMonitor::instance->m_mutex);
        auto it = LaunchingMonitor::instance->g_procs.find(pid);
        if (it == LaunchingMonitor::instance->g_procs.end()) return;
        if (it->second.windowShownSignaled) return;

        // 如果启动时没拿到路径，这里补一次
        if (it->second.imagePath.empty() || it->second.imagePath == L"[Unknown]") {
            std::wstring p = GetProcessImagePathRetryW(pid);
            if (!p.empty()) it->second.imagePath = p;
            it->second.icon_imgIndex = QmlImageProvider::instance()->addImg(LaunchingMonitor::instance->getExeIcon(p));
        }

        // 设置窗口标题
        wchar_t title[256] = {};
        GetWindowText(hwnd, title, 256);
        it->second.windowTitle = title;
        it->second.windowShownSignaled = true;

        icon_imgIndex = it->second.icon_imgIndex;
    }

    emit LaunchingMonitor::instance->windowShown(pid);
    QTimer::singleShot(1000, LaunchingMonitor::instance, [=](){  // 1秒后删除该项数据
        QMutexLocker locker(&LaunchingMonitor::instance->m_mutex);
        LaunchingMonitor::instance->g_procs.erase(pid);
        QmlImageProvider::instance()->removeImg(icon_imgIndex);
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

bool LaunchingMonitor::QueryProcesses(std::unordered_map<DWORD, DWORD> &result)
{
    if (!pNtQuerySystemInformation)
        return false;

    result.clear();

    ULONG size = 1 << 20;     // 1MB 起步

    std::vector<BYTE> buffer(size);

    NTSTATUS status;

    while (true)
    {
        status = pNtQuerySystemInformation(
            SystemProcessInformation,
            buffer.data(),
            static_cast<ULONG>(buffer.size()),
            &size);

        if (status == STATUS_INFO_LENGTH_MISMATCH)
        {
            buffer.resize(size + 64 * 1024);
            continue;
        }

        break;
    }

    if (!NT_SUCCESS(status))
        return false;

    auto* spi =
        reinterpret_cast<SYSTEM_PROCESS_INFORMATION*>(buffer.data());

    while (true)
    {
        DWORD pid =
            static_cast<DWORD>(
                reinterpret_cast<ULONG_PTR>(spi->UniqueProcessId));

        DWORD parent =
            static_cast<DWORD>(
                reinterpret_cast<ULONG_PTR>(spi->InheritedFromUniqueProcessId));

        result.emplace(pid, parent);

        if (spi->NextEntryOffset == 0)
            break;

        spi = reinterpret_cast<SYSTEM_PROCESS_INFORMATION*>(
            reinterpret_cast<BYTE*>(spi) + spi->NextEntryOffset);
    }

    return true;
}

void LaunchingMonitor::startMonitoring() {
    known.reserve(8192);

    // 启动时先做一次快照建表
    QueryProcesses(known);

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

        if (!QueryProcesses(current))
            return;

        for (const auto& [pid, parentPid] : current)
        {
            if (known.find(pid) == known.end())
            {
                std::wstring parentExe;
                if (parentCache.find(parentPid) == parentCache.end()) {
                    std::wstring parentPath = GetProcessImagePathRetryW(parentPid, 60);
                    parentExe = ToLowerW(BaseNameW(parentPath));
                    parentCache[parentPid] = parentExe;
                } else {
                    parentExe = parentCache[parentPid];
                }

                if (g_shellParentExeNames.find(parentExe)
                    == g_shellParentExeNames.end())
                {
                    continue;
                }

                SignalProcessStarted(pid, parentPid);
            }
        }

        known.swap(current);
    });
    pollingTimer->start(pollingIntervalMs);
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
            int icon_imgIndex = st.icon_imgIndex;
            locker.unlock();

            emit processStarted(pid);

            QTimer::singleShot(60000, this, [=](){  // 数据最多保留 60s
                QMutexLocker locker(&LaunchingMonitor::instance->m_mutex);
                LaunchingMonitor::instance->g_procs.erase(pid);
                QmlImageProvider::instance()->removeImg(icon_imgIndex);
            });
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
    st.icon_imgIndex = QmlImageProvider::instance()->addImg(LaunchingMonitor::instance->getExeIcon(path));

    int icon_imgIndex = st.icon_imgIndex;
    locker.unlock();

    emit processStarted(pid);

    QTimer::singleShot(60000, this, [=](){  // 数据最多保留 60s
        QMutexLocker locker(&LaunchingMonitor::instance->m_mutex);
        LaunchingMonitor::instance->g_procs.erase(pid);
        QmlImageProvider::instance()->removeImg(icon_imgIndex);
    });
}

QImage LaunchingMonitor::getExeIcon(std::wstring path)
{
    SHFILEINFOW sfi{};
    SHGetFileInfoW(
        path.c_str(),
        0,
        &sfi,
        sizeof(sfi),
        SHGFI_SYSICONINDEX
        );

    IImageList* imageList = nullptr;
    SHGetImageList(
        SHIL_JUMBO,
        IID_IImageList,
        (void**)&imageList
        );

    HICON hIcon = nullptr;
    imageList->GetIcon(
        sfi.iIcon,
        ILD_NORMAL,
        &hIcon
        );

    QImage ico = QImage::fromHICON(hIcon);
    DestroyIcon(hIcon);
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
        auto st = monitor->getProcState(pid);
        QString exeName = QString::fromStdWString(st.imagePath).split("\\").last();

        // 处理软件列表数据
        if (appList.find(exeName) == appList.end()) {
            // 自动添加数据项
            if (ConfigManager::instance->launchingHelperCfg->get("OnlyManualAddition").toBool())
                return;
            AppInfoItem info;
            info.exePath = QString::fromStdWString(st.imagePath);
            addAppItem(exeName, info);
        } else if (appList[exeName].exePath.isEmpty()) {
            appList[exeName].exePath = QString::fromStdWString(st.imagePath);
        }
        int perDuration = appList[exeName].duration;
        // 判断是否需要显示提示窗口
        if (!appList[exeName].enableHelper)
            return;
        // 当只有一个正在启动的软件时才重置定时器
        if (monitor->getProcsCount() == 0)
            launchingRecordTimer.start();
        // 记录开始时间，后续加上结束时间即为时间间隔
        appList[exeName].duration = - launchingRecordTimer.elapsed();

        QPoint cursor = QCursor::pos();
        qsizetype iconId = st.icon_imgIndex;
        qsizetype manualDuration = appList[exeName].manualDuration;
        emit processStartedWithInfo(exeName, QString::number(iconId), cursor, perDuration, manualDuration);
        qDebug() << "软件启动提示 (进程名称:" << exeName << "图标Id:" << iconId << "光标:" << cursor << ")";
    });
    connect(this, &LaunchingHelper::windowShown, this, [=](DWORD pid){
        auto st = monitor->getProcState(pid);
        QString exeName = QString::fromStdWString(st.imagePath).split("\\").last();

        if (appList.find(exeName) == appList.end())
            return;

        QPoint cursor = QCursor::pos();
        QString windowTitle = QString::fromStdWString(st.windowTitle);

        // 处理软件列表数据
        AppInfoItem info = appList[exeName];
        info.isShowWindow = true;
        info.duration += launchingRecordTimer.elapsed();
        // 如果窗口标题在 5 个字符以内就认为这是软件名称
        if (windowTitle.length() <= 5)
            info.appName = windowTitle;
        addAppItem(exeName, info);

        emit windowShownWithInfo(windowTitle, exeName, QString::number(st.icon_imgIndex), cursor);
        qDebug() << "软件启动窗口显示 (进程名称:" << exeName << "窗口标题:" << st.windowTitle << "光标:" << cursor << ")";
    });

    // 加载软件信息列表
    loadAppList();

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

void LaunchingHelper::disableHelperForItem(const QVariant &exeName)
{
    switchHelperForItem(exeName, false);
}

void LaunchingHelper::switchHelperForItem(const QVariant &exeName, bool enable)
{
    appList[exeName.toString()].enableHelper = enable;
    saveAppList();
}

void LaunchingHelper::deleteItem(const QString &exeName)
{
    appList.remove(exeName);
    saveAppList();
}

void LaunchingHelper::setItem(const QString &exeName, const QString &appName, bool enableHelper, int manualDuration, const QString &exePath)
{
    AppInfoItem info;
    info.appName = appName;
    info.enableHelper = enableHelper;
    info.manualDuration = manualDuration;
    info.exePath = exePath;
    addAppItem(exeName, info);
}

void LaunchingHelper::loadAppList()
{
    ConfigFileManager* cfg = ConfigManager::instance->launchingHelperCfg;
    if (!cfg->readReady())
        return;

    QVariantList list = cfg->get("Apps").toList();
    if (list.empty())
        return;

    for (auto it = list.begin(); it != list.end() ; it++) {
        QVariantMap data = it->toMap();
        AppInfoItem item;
        item.enableHelper = data["enableHelper"].toBool();
        item.appName = data["appName"].toString();
        item.duration = data["duration"].toInt();
        item.manualDuration = data["manualDuration"].toInt();
        item.isShowWindow = data["isShowWindow"].toBool();
        item.exePath = data["exePath"].toString();
        appList[data["exeName"].toString()] = item;
    }
}

void LaunchingHelper::saveAppList()
{
    if (appList.empty())
        return;

    ConfigFileManager* cfg = ConfigManager::instance->launchingHelperCfg;
    cfg->clearList("Apps");
    for (auto it = appList.begin(); it != appList.end() ; it++) {
        QVariantMap item;
        item["exeName"] = it.key();
        item["enableHelper"] = it.value().enableHelper;
        item["appName"] = it.value().appName;
        item["duration"] = it.value().duration;
        item["manualDuration"] = it.value().manualDuration;
        item["isShowWindow"] = it.value().isShowWindow;
        item["exePath"] = it.value().exePath;
        cfg->add("Apps", item, false);
    }
    ConfigManager::instance->launchingHelperCfg->writeConfigFile();
}

void LaunchingHelper::addAppItem(const QString &exeName, const AppInfoItem &item)
{
    appList[exeName] = item;
    saveAppList();
}