#include "windowfocushelper.h"
#include <QTimer>
#include <QDebug>

#ifndef HSHELL_WINDOWCREATED
#define HSHELL_WINDOWCREATED 1
#endif

// 延迟设焦的毫秒数，晚于资源管理器“抢焦点”的时机
static const int kFocusDelayMs = 800;

static const wchar_t kShellHostClassName[] = L"WindowFocusHelperShellHost";

static const wchar_t* const kForegroundWhitelist[] = {
    L"explorer.exe",
    L"weixin.exe",
};
static const size_t kForegroundWhitelistCount = sizeof(kForegroundWhitelist) / sizeof(kForegroundWhitelist[0]);

WindowFocusHelper::WindowFocusHelper(QObject *parent) : QObject(parent) {
    start();
}

WindowFocusHelper::~WindowFocusHelper()
{
    stop();
}

bool WindowFocusHelper::isForegroundInWhitelist()
{
    HWND fg = GetForegroundWindow();
    if (!fg) return false;

    DWORD pid = 0;
    GetWindowThreadProcessId(fg, &pid);
    if (!pid) return false;

    HANDLE hProc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!hProc) return false;

    wchar_t path[MAX_PATH] = {};
    DWORD size = MAX_PATH;
    bool ok = false;
    if (QueryFullProcessImageNameW(hProc, 0, path, &size)) {
        const wchar_t* name = path + wcslen(path);
        while (name > path && name[-1] != L'\\' && name[-1] != L'/') --name;
        qDebug() << "HSHELL_WINDOWCREATED_Name：" << QString::fromWCharArray(path).toLower();
        for (size_t i = 0; i < kForegroundWhitelistCount; ++i) {
            if (_wcsicmp(name, kForegroundWhitelist[i]) == 0) {
                ok = true;
                break;
            }
        }
    }
    CloseHandle(hProc);
    return ok;
}

void WindowFocusHelper::scheduleFocusToWindow(HWND hwnd, bool isDelay)
{
    if (!hwnd) return;
    if (isDelay)
        QTimer::singleShot(kFocusDelayMs, this, [this, hwnd]() { applyFocusToWindow(hwnd); });
    else
        applyFocusToWindow(hwnd);
}

void WindowFocusHelper::applyFocusToWindow(HWND hwnd)
{
    if (!hwnd || !IsWindow(hwnd) || !isFocusableWindow(hwnd))
        return;

    HWND fg = GetForegroundWindow();
    DWORD fgTid = fg ? GetWindowThreadProcessId(fg, nullptr) : 0;
    DWORD ourTid = GetCurrentThreadId();

    // 方案1：附加到当前前景线程后设焦
    if (fgTid && fgTid != ourTid && AttachThreadInput(ourTid, fgTid, TRUE)) {
        SetForegroundWindow(hwnd);
        AttachThreadInput(ourTid, fgTid, FALSE);
    }

    // 若仍未成为前景，使用“模拟 Alt 键”解除系统前景锁后再设焦（跨进程可靠）
    if (GetForegroundWindow() != hwnd) {
        keybd_event(VK_MENU, 0, 0, 0);
        keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, 0);
        SetForegroundWindow(hwnd);
    }
}

bool WindowFocusHelper::isFocusableWindow(HWND hwnd)
{
    if (!hwnd || !IsWindow(hwnd))
        return false;

    // 无焦点窗口：显式带有 WS_EX_NOACTIVATE 的窗口不激活
    LONG exStyle = GetWindowLongW(hwnd, GWL_EXSTYLE);
    if (exStyle & WS_EX_NOACTIVATE)
        return false;

    // 子窗口不单独抢焦点（由父窗口管理）
    if (GetParent(hwnd) != nullptr)
        return false;

    // 不可见窗口不处理（如尚未 ShowWindow 的）
    if (!IsWindowVisible(hwnd))
        return false;

    // 工具窗口且无 Owner 的通常不参与任务栏、可不激活（可选；这里为兼容性保留，仅排除明确无焦点的）
    // 排除工具提示、菜单等系统无焦点窗口
    wchar_t className[64] = {};
    if (GetClassNameW(hwnd, className, (int)(sizeof(className) / sizeof(className[0])))) {
        if (wcscmp(className, L"tooltips_class32") == 0)
            return false;
        if (wcscmp(className, L"#32768") == 0)  // 菜单
            return false;
    }

    return true;
}

LRESULT CALLBACK WindowFocusHelper::shellWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    WindowFocusHelper* self = nullptr;
    if (msg == WM_NCCREATE) {
        qDebug() << "WM_NCCREATE";
        CREATESTRUCTW* cs = reinterpret_cast<CREATESTRUCTW*>(lParam);
        self = reinterpret_cast<WindowFocusHelper*>(cs->lpCreateParams);
        if (self)
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    } else {
        self = reinterpret_cast<WindowFocusHelper*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    }

    if (self && msg == self->m_msgShellHook && self->m_msgShellHook != 0) {
        if (wParam == HSHELL_WINDOWCREATED) {
            qDebug() << "HSHELL_WINDOWCREATED";
            HWND newHwnd = reinterpret_cast<HWND>(lParam);
            if (isFocusableWindow(newHwnd)) {
                // 若当前前景是白名单内软件则时延迟设焦
                if (isForegroundInWhitelist())
                    self->scheduleFocusToWindow(newHwnd, true);
            }
        }
        return 0;
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

bool WindowFocusHelper::start()
{
    if (m_active)
        return true;

    m_msgShellHook = RegisterWindowMessageW(L"SHELLHOOK");
    if (m_msgShellHook == 0)
        return false;

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = &WindowFocusHelper::shellWndProc;
    wc.hInstance = GetModuleHandleW(nullptr);
    wc.lpszClassName = kShellHostClassName;
    if (!RegisterClassExW(&wc))
        return false;

    m_shellHost = CreateWindowExW(
        0,
        kShellHostClassName,
        L"",
        WS_OVERLAPPED,
        0, 0, 0, 0,
        nullptr,
        nullptr,
        wc.hInstance,
        this
    );
    if (!m_shellHost) {
        UnregisterClassW(kShellHostClassName, wc.hInstance);
        return false;
    }

    if (!RegisterShellHookWindow(m_shellHost)) {
        DestroyWindow(m_shellHost);
        m_shellHost = nullptr;
        UnregisterClassW(kShellHostClassName, wc.hInstance);
        return false;
    }

    m_active = true;
    return true;
}

void WindowFocusHelper::stop()
{
    if (!m_active)
        return;

    if (m_shellHost) {
        DeregisterShellHookWindow(m_shellHost);
        DestroyWindow(m_shellHost);
        m_shellHost = nullptr;
        UnregisterClassW(kShellHostClassName, GetModuleHandleW(nullptr));
    }
    m_msgShellHook = 0;
    m_active = false;
}
