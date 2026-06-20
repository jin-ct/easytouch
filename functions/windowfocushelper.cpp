#include "windowfocushelper.h"
#include <QDebug>

#ifndef HSHELL_WINDOWCREATED
#define HSHELL_WINDOWCREATED 1
#endif

// 设焦间隔的毫秒数
static const int kFocusDelayMs = 100;

static const wchar_t kShellHostClassName[] = L"WindowFocusHelperShellHost";

struct WindowInf
{
    const wchar_t* exeName;
    const wchar_t* title;
    const LONG uniqueStyle;
    const bool isExceptUStyle;
};

static const WindowInf kForegroundWhitelist[] = {
    {.exeName = L"explorer.exe", .title = L"文件资源管理器", .uniqueStyle = 0, .isExceptUStyle = true},
    {.exeName = L"weixin.exe", .title = L"微信", .uniqueStyle = WS_MAXIMIZEBOX | WS_MINIMIZEBOX, .isExceptUStyle = true}
};
static const size_t kForegroundWhitelistCount = sizeof(kForegroundWhitelist) / sizeof(kForegroundWhitelist[0]);

WindowFocusHelper::WindowFocusHelper(QObject *parent) : QObject(parent) {
    focusSettingTimer.setInterval(kFocusDelayMs);
    connect(&this->focusSettingTimer, &QTimer::timeout, this, [=](){
        if (GetForegroundWindow() != focusSettingWindow) {
            applyFocusToWindow(focusSettingWindow);
        } else {
            focusSettingTimer.stop();
            // 双重保险
            QTimer::singleShot(1000, this, [=](){
                if (GetForegroundWindow() != focusSettingWindow)
                    applyFocusToWindow(focusSettingWindow);
            });
        }
    });
    start();
}

WindowFocusHelper::~WindowFocusHelper()
{
    stop();
}

bool WindowFocusHelper::isWindowInWhitelist(HWND hwnd)
{
    if (!hwnd) return false;

    wchar_t title[256] = {};
    GetWindowText(hwnd, title, 256);

    LONG style = GetWindowLong(hwnd, GWL_STYLE);
    LONG exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);

    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    if (!pid) return false;

    HANDLE hProc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!hProc) return false;

    wchar_t path[MAX_PATH] = {};
    DWORD size = MAX_PATH;
    bool ok = false;
    if (QueryFullProcessImageNameW(hProc, 0, path, &size)) {
        QString m_path = QString::fromWCharArray(path).toLower();
        QString m_title = QString::fromWCharArray(title);
        for (size_t i = 0; i < kForegroundWhitelistCount; ++i) {
            bool isHaveUniqueStyle = (style | exStyle) & kForegroundWhitelist[i].uniqueStyle;
            if (m_path.contains(QString::fromWCharArray(kForegroundWhitelist[i].exeName).toLower()) &&
                m_title.contains(QString::fromWCharArray(kForegroundWhitelist[i].title)) &&
                (kForegroundWhitelist[i].isExceptUStyle ? !isHaveUniqueStyle : isHaveUniqueStyle)) {
                ok = true;
                break;
            }
        }
        qDebug() << "窗口焦点助手触发 (进程路径: " << m_path << ", 窗口标题: " << m_title << ",在窗口列表内: " << ok << ")";
    }
    CloseHandle(hProc);
    return ok;
}

void WindowFocusHelper::scheduleFocusToWindow(HWND hwnd, bool isDelay)
{
    if (!hwnd) return;
    if (isDelay) {
        focusSettingWindow = hwnd;
        focusSettingTimer.start();
    } else {
        applyFocusToWindow(hwnd);
    }
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
        INPUT input[2] = {};

        input[0].type = INPUT_KEYBOARD;
        input[0].ki.wVk = VK_MENU;

        input[1].type = INPUT_KEYBOARD;
        input[1].ki.wVk = VK_MENU;
        input[1].ki.dwFlags = KEYEVENTF_KEYUP;

        SendInput(2, input, sizeof(INPUT));
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
            emit self->newWindowCreated();
            HWND newHwnd = reinterpret_cast<HWND>(lParam);
            if (isFocusableWindow(newHwnd) && !isWindowInWhitelist(newHwnd)) {
                HWND fg = GetForegroundWindow();
                // 若当前前景是白名单内软件则时延迟设焦
                if (isWindowInWhitelist(fg) || newHwnd == fg)
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
    emit started();
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
