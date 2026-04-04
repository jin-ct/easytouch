#include "wechathelper.h"
#include <QGuiApplication>
#include <QScreen>
#include <QString>
#include <cmath>
#include <windowsx.h>

const wchar_t *WeChatHelper::s_overlayClassName = L"WeChatHelperOverlay";

static const int kScrollDragThreshold = 12;
static const int kLongPressMs = 500;
static const float kWheelDeltaScale = 3;         // 滚轮 delta = dy * scale，与滑动距离成正比
static const int kWheelDeltaMax = 360;           // 单次最大 delta，避免速度突变
static const float kVelocityThresholdMin = 2.0;  // 触发惯性的速度阈值
static const double kVelocityThresholdMax = 360; // 惯性计算的最大速度值，避免速度突变
static const float kMaxVelocityScale = 0.95;     // 惯性的最大速度占输入速度比例
static const float kVelocityScale = 0.90;        // 惯性单次变化比例
static const float kVelocityScaleDuration = 12;  // 惯性单次变化时间间隔 (ms)

WeChatHelper::WeChatHelper(QObject *parent)
    : QObject(parent)
{
    QObject::connect(&m_inertiaTimer, &QTimer::timeout, this, [this] {
        m_inertiaVelocity *= kVelocityScale;
        if (std::abs(m_inertiaVelocity) < 0.01) {
            m_inertiaTimer.stop();
            return;
        }
        // 惯性滑动
        sendWheelViaMouseInput(int(m_inertiaVelocity * 80.0));
    });

    m_longPressTimer.setSingleShot(true);
    QObject::connect(&m_longPressTimer, &QTimer::timeout, this, &WeChatHelper::onLongPressTimeout);

    createOverlay();

    m_foregroundCheckTimer.setInterval(150);
    QObject::connect(&m_foregroundCheckTimer, &QTimer::timeout, this, &WeChatHelper::updateOverlayVisibility);
    m_foregroundCheckTimer.start();
}

WeChatHelper::~WeChatHelper()
{
    m_foregroundCheckTimer.stop();
    destroyOverlay();
}

bool WeChatHelper::isWeixinForeground()
{
    HWND fg = GetForegroundWindow();
    if (!fg) return false;

    DWORD pid = 0;
    GetWindowThreadProcessId(fg, &pid);
    if (!pid) return false;

    HANDLE hProc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
    if (!hProc) return false;

    wchar_t path[MAX_PATH];
    DWORD size = MAX_PATH;
    bool ok = false;

    if (QueryFullProcessImageNameW(hProc, 0, path, &size)) {
        QString exe = QString::fromWCharArray(path).toLower();
        ok = exe.endsWith("\\weixin.exe") || exe.endsWith("\\wechat.exe");
    }

    CloseHandle(hProc);
    return ok;
}

HWND WeChatHelper::getWeChatHwnd()
{
    HWND fg = GetForegroundWindow();
    if (!fg) return nullptr;
    if (!isWeixinForeground()) return nullptr;
    return fg;
}

bool WeChatHelper::getWeChatClientRectInScreen(RECT *outRect)
{
    if (!outRect) return false;
    HWND h = getWeChatHwnd();
    if (!h || !IsWindow(h)) return false;
    RECT cr = {};
    if (!GetClientRect(h, &cr)) return false;
    POINT tl = { cr.left, cr.top };
    POINT br = { cr.right, cr.bottom };
    if (!ClientToScreen(h, &tl) || !ClientToScreen(h, &br)) return false;
    outRect->left = tl.x;
    outRect->top = tl.y;
    outRect->right = br.x;
    outRect->bottom = br.y;
    return true;
}

bool WeChatHelper::getWeChatWindowRectInScreen(RECT *outRect)
{
    if (!outRect) return false;
    HWND h = getWeChatHwnd();
    if (!h || !IsWindow(h)) return false;
    return GetWindowRect(h, outRect) != FALSE;
}

void WeChatHelper::createOverlay()
{
    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.lpfnWndProc = overlayWndProc;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = s_overlayClassName;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    RegisterClassExW(&wc);

    m_overlay = CreateWindowExW(
        WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_NOACTIVATE,
        s_overlayClassName,
        nullptr,
        WS_POPUP,
        0, 0, 1, 1,
        nullptr, nullptr, GetModuleHandle(nullptr), this);

    if (m_overlay) {
        SetLayeredWindowAttributes(m_overlay, 0, 1, LWA_ALPHA);
        ShowWindow(m_overlay, SW_HIDE);
    }
}

void WeChatHelper::destroyOverlay()
{
    if (m_overlay) {
        DestroyWindow(m_overlay);
        m_overlay = nullptr;
    }
    UnregisterClassW(s_overlayClassName, GetModuleHandle(nullptr));
}

void WeChatHelper::updateOverlayVisibility()
{
    if (!m_overlay) return;

    RECT rect = {};
    if (!isWeixinForeground()) {
        if (m_overlayVisible) {
            ShowWindow(m_overlay, SW_HIDE);
            m_overlayVisible = false;
        }
        return;
    }
    if (getWeChatClientRectInScreen(&rect)) {
        int w = rect.right - rect.left;
        int h = rect.bottom - rect.top;
        if (w <= 0 || h <= 0) {
            if (!getWeChatWindowRectInScreen(&rect)) {
                if (m_overlayVisible) {
                    ShowWindow(m_overlay, SW_HIDE);
                    m_overlayVisible = false;
                }
                return;
            }
            w = rect.right - rect.left;
            h = rect.bottom - rect.top;
        }
        if (w > 0 && h > 0) {
            bool rectChanged = (rect.left != m_lastOverlayRect.left || rect.top != m_lastOverlayRect.top ||
                                rect.right != m_lastOverlayRect.right || rect.bottom != m_lastOverlayRect.bottom);
            if (rectChanged) {
                SetWindowPos(m_overlay, HWND_TOPMOST,
                             rect.left, rect.top, w, h,
                             SWP_NOACTIVATE | SWP_NOZORDER);
                m_lastOverlayRect = rect;
            }
            if (!m_overlayVisible) {
                ShowWindow(m_overlay, SW_SHOWNOACTIVATE);
                m_overlayVisible = true;
            }
        } else if (m_overlayVisible) {
            ShowWindow(m_overlay, SW_HIDE);
            m_overlayVisible = false;
        }
    } else if (getWeChatWindowRectInScreen(&rect)) {
        int w = rect.right - rect.left;
        int h = rect.bottom - rect.top;
        if (w > 0 && h > 0) {
            bool rectChanged = (rect.left != m_lastOverlayRect.left || rect.top != m_lastOverlayRect.top ||
                                rect.right != m_lastOverlayRect.right || rect.bottom != m_lastOverlayRect.bottom);
            if (rectChanged) {
                SetWindowPos(m_overlay, HWND_TOPMOST,
                             rect.left, rect.top, w, h,
                             SWP_NOACTIVATE | SWP_NOZORDER);
                m_lastOverlayRect = rect;
            }
            if (!m_overlayVisible) {
                ShowWindow(m_overlay, SW_SHOWNOACTIVATE);
                m_overlayVisible = true;
            }
        } else if (m_overlayVisible) {
            ShowWindow(m_overlay, SW_HIDE);
            m_overlayVisible = false;
        }
    } else if (m_overlayVisible) {
        ShowWindow(m_overlay, SW_HIDE);
        m_overlayVisible = false;
    }
}

void WeChatHelper::sendWheelToWeChat(int delta, const POINT &screenPt)
{
    HWND h = getWeChatHwnd();
    if (!h || !IsWindow(h)) return;
    POINT client = screenPt;
    if (!ScreenToClient(h, &client)) return;
    WPARAM wParam = MAKEWPARAM(0, (WORD)(short)delta);
    LPARAM lParam = MAKELPARAM(client.x, client.y);
    PostMessage(h, WM_MOUSEWHEEL, wParam, lParam);
}

void WeChatHelper::postMouseToWeChat(UINT msg, const POINT &screenPt, WPARAM wParam)
{
    HWND wechatHwnd = getWeChatHwnd();
    if (!wechatHwnd || !IsWindow(wechatHwnd))
        return;

    DWORD wechatPid = 0;
    GetWindowThreadProcessId(wechatHwnd, &wechatPid);
    if (!wechatPid)
        return;

    HWND topWeChatHwnd = nullptr;
    {
        POINT pt = screenPt;
        for (HWND h = GetTopWindow(nullptr); h != nullptr; h = GetWindow(h, GW_HWNDNEXT)) {
            DWORD pid = 0;
            GetWindowThreadProcessId(h, &pid);
            if (pid != wechatPid)
                continue;
            if (!IsWindowVisible(h) || IsIconic(h))
                continue;

            RECT r = {};
            if (!GetWindowRect(h, &r))
                continue;
            if (!PtInRect(&r, pt))
                continue;

            topWeChatHwnd = h;
            break;  // Z 序从前到后，第一个命中的就是最上层
        }
    }

    if (!topWeChatHwnd)
        topWeChatHwnd = wechatHwnd;

    // 先把屏幕坐标转换成顶层微信窗口的客户区坐标
    POINT ptClient = screenPt;
    if (!ScreenToClient(topWeChatHwnd, &ptClient))
        return;

    HWND target = topWeChatHwnd;
    POINT ptInTarget = ptClient;

    // 在父窗口客户区坐标下调用 RealChildWindowFromPoint，
    // 命中子窗口后再把点转换到子窗口客户区，如此循环，直到没有更深的子窗口
    for (;;) {
        HWND child = RealChildWindowFromPoint(target, ptInTarget);
        if (!child || child == target)
            break;

        POINT ptInChild = ptInTarget;
        MapWindowPoints(target, child, &ptInChild, 1);

        target = child;
        ptInTarget = ptInChild;
    }

    auto sendTo = [](HWND hwnd, UINT m, WPARAM wp, LPARAM lp) {
        PostMessage(hwnd, m, wp, lp);
    };

    // 先发给命中的最深子窗口（坐标为该子窗口客户区）
    LPARAM lParamTarget = MAKELPARAM(ptInTarget.x, ptInTarget.y);
    sendTo(target, msg, wParam, lParamTarget);

    // 再兜底发给顶层微信窗口（坐标为其客户区），兼容“子控件不处理但父窗口处理”的情况
    if (target != topWeChatHwnd) {
        LPARAM lParamRoot = MAKELPARAM(ptClient.x, ptClient.y);
        sendTo(topWeChatHwnd, msg, wParam, lParamRoot);
    }
}

void WeChatHelper::onLongPressTimeout()
{
    if (m_state != InputState::TouchPending) return;
    m_longPressFired = true;
    POINT pt = { m_touchStartX, m_touchStartY };
    postMouseToWeChat(WM_RBUTTONDOWN, pt, MK_RBUTTON);
    postMouseToWeChat(WM_RBUTTONUP, pt, 0);
}

void WeChatHelper::recordSample(int deltaY, qint64 elapsed)
{
    m_samples.append({elapsed, deltaY});

    while (!m_samples.isEmpty() && elapsed - m_samples.first().first > 100)
        m_samples.removeFirst();
}

double WeChatHelper::calcVelocity()
{
    if (m_samples.size() < 2)
        return 0.0;

    int sum = 0;
    qint64 dt = m_timer.elapsed();
    for (auto &s : m_samples) {
        if (std::abs(sum + s.second) > std::abs(sum))
            sum += s.second;
    }

    if (dt <= 0) return 0.0;
    return double(sum) / double(dt);
}

void WeChatHelper::startInertia()
{
    m_velocity = calcVelocity();
    m_samples.clear();
    m_inertiaVelocity = std::min(m_velocity * kMaxVelocityScale, kVelocityThresholdMax);

    if (std::abs(m_velocity) < kVelocityThresholdMin)
        return;

    m_inertiaTimer.start(kVelocityScaleDuration);
}

void WeChatHelper::sendWheelViaMouseInput(int delta)
{
    POINT targetPt = m_lastWheelScreenPt;

    // 如果还没有记录过滚轮位置，则优先使用微信客户端区域中心，其次使用当前鼠标位置
    if (targetPt.x == 0 && targetPt.y == 0) {
        RECT rect = {};
        if (getWeChatClientRectInScreen(&rect)) {
            targetPt.x = (rect.left + rect.right) / 2;
            targetPt.y = (rect.top + rect.bottom) / 2;
        } else {
            GetCursorPos(&targetPt);
        }
        m_lastWheelScreenPt = targetPt;
    }

    POINT oldPos = {};
    GetCursorPos(&oldPos);

    // 暂时移动系统光标到目标位置，让 SendInput 生成的 WM_MOUSEWHEEL 以该点为落脚
    SetCursorPos(targetPt.x, targetPt.y);

    INPUT input = {};
    input.type = INPUT_MOUSE;
    input.mi.dwFlags = MOUSEEVENTF_WHEEL;
    input.mi.mouseData = delta;
    input.mi.dwExtraInfo = GetMessageExtraInfo();

    SendInput(1, &input, sizeof(INPUT));
}

LRESULT CALLBACK WeChatHelper::overlayWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    WeChatHelper *self = nullptr;
    if (msg == WM_NCCREATE) {
        CREATESTRUCTW *cs = reinterpret_cast<CREATESTRUCTW *>(lParam);
        self = static_cast<WeChatHelper *>(cs->lpCreateParams);
        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
    } else {
        self = reinterpret_cast<WeChatHelper *>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
    }

    if (!self) return DefWindowProcW(hwnd, msg, wParam, lParam);

    switch (msg) {
    case WM_POINTERDOWN:
    {
        UINT32 id = GET_POINTERID_WPARAM(wParam);
        POINTER_INFO pi = {};
        if (!GetPointerInfo(id, &pi)) break;

        if (pi.pointerType == PT_TOUCH && self->isWeixinForeground()) {
            if (self->m_state == InputState::Idle) {
                self->m_state = InputState::TouchPending;
                self->m_pointerId = id;
                self->m_lastX = pi.ptPixelLocationRaw.x;
                self->m_lastY = pi.ptPixelLocationRaw.y;
                self->m_touchStartX = pi.ptPixelLocationRaw.x;
                self->m_touchStartY = pi.ptPixelLocationRaw.y;
                self->m_longPressFired = false;
                self->m_longPressTimer.start(kLongPressMs);
                self->m_timer.restart();
                self->m_samples.clear();
            }
            return 0;
        }
        if (pi.pointerType == PT_MOUSE && self->isWeixinForeground()) {
            SetCapture(hwnd);
            self->postMouseToWeChat(WM_LBUTTONDOWN, pi.ptPixelLocation, MK_LBUTTON);
            self->m_mouseLeftDown = true;
            return 0;
        }
        break;
    }

    case WM_POINTERUPDATE:
    {
        UINT32 id = GET_POINTERID_WPARAM(wParam);
        POINTER_INFO pi = {};
        if (!GetPointerInfo(id, &pi)) break;

        if (pi.pointerType == PT_TOUCH &&
            (self->m_state == InputState::TouchPending || self->m_state == InputState::TouchScroll || self->m_state == InputState::TouchDrag) &&
            id == static_cast<UINT32>(self->m_pointerId)) {

            int x = pi.ptPixelLocationRaw.x;
            int y = pi.ptPixelLocationRaw.y;
            int dx = x - self->m_lastX;
            int dy = y - self->m_lastY;
            int totalDx = x - self->m_touchStartX;
            int totalDy = y - self->m_touchStartY;

            if (self->m_state == InputState::TouchPending) {
                if (std::abs(totalDx) > kScrollDragThreshold || std::abs(totalDy) > kScrollDragThreshold) {
                    self->m_longPressTimer.stop();
                    if (std::abs(totalDy) >= std::abs(totalDx)) {
                        self->m_state = InputState::TouchScroll;
                        // 以滑动起点作为滚轮落脚点（并贯穿惯性），避免落脚点跟随手指漂移
                        self->m_lastWheelScreenPt = { self->m_touchStartX, self->m_touchStartY };
                    } else {
                        self->m_state = InputState::TouchDrag;
                        self->m_dragTargetHwnd = self->getWeChatHwnd();
                        self->m_lastDragClientX = INT_MIN;
                        self->m_lastDragClientY = INT_MIN;
                        SetCapture(hwnd);
                        POINT pt = { self->m_touchStartX, self->m_touchStartY };
                        self->postMouseToWeChat(WM_LBUTTONDOWN, pt, MK_LBUTTON);
                    }
                }
            }

            if (self->m_state == InputState::TouchScroll && std::abs(dy) > 2) {
                self->recordSample(dy, self->m_timer.elapsed());
                int absDelta = std::min((int)(std::abs(dy) * kWheelDeltaScale), kWheelDeltaMax);
                int delta = (dy > 0 ? 1 : -1) * absDelta;
                self->sendWheelViaMouseInput(delta);
            }
            if (self->m_state == InputState::TouchDrag && self->m_dragTargetHwnd) {
                POINT rawPt = { x, y };
                POINT client = rawPt;
                if (ScreenToClient(self->m_dragTargetHwnd, &client)) {
                    if (client.x != self->m_lastDragClientX || client.y != self->m_lastDragClientY) {
                        self->m_lastDragClientX = client.x;
                        self->m_lastDragClientY = client.y;
                        SetCursorPos(rawPt.x, rawPt.y);
                        self->postMouseToWeChat(WM_MOUSEMOVE, rawPt, MK_LBUTTON);
                    }
                }
            }

            self->m_lastX = x;
            self->m_lastY = y;
            return 0;
        }
        if (pi.pointerType == PT_MOUSE && self->isWeixinForeground()) {
            WPARAM keys = (self->m_mouseLeftDown ? MK_LBUTTON : 0) | (self->m_mouseRightDown ? MK_RBUTTON : 0);
            self->postMouseToWeChat(WM_MOUSEMOVE, pi.ptPixelLocation, keys);
            return 0;
        }
        break;
    }

    case WM_POINTERUP:
    case WM_POINTERCAPTURECHANGED:
    {
        UINT32 id = GET_POINTERID_WPARAM(wParam);
        POINTER_INFO pi = {};
        if (GetPointerInfo(id, &pi) && pi.pointerType == PT_TOUCH &&
            id == static_cast<UINT32>(self->m_pointerId)) {
            self->m_longPressTimer.stop();
            if (self->m_state == InputState::TouchScroll)
                self->startInertia();
            else if (self->m_state == InputState::TouchDrag) {
                ReleaseCapture();
                POINT upPt = { self->m_lastX, self->m_lastY };
                self->postMouseToWeChat(WM_LBUTTONUP, upPt, 0);
            }
            else if (self->m_state == InputState::TouchPending && !self->m_longPressFired) {
                POINT pt = pi.ptPixelLocationRaw;
                self->postMouseToWeChat(WM_LBUTTONDOWN, pt, MK_LBUTTON);
                self->postMouseToWeChat(WM_LBUTTONUP, pt, 0);
            }
            self->m_longPressFired = false;
        }
        if (GetPointerInfo(id, &pi) && pi.pointerType == PT_MOUSE && self->isWeixinForeground()) {
            ReleaseCapture();
            self->postMouseToWeChat(WM_LBUTTONUP, pi.ptPixelLocation, 0);
            self->m_mouseLeftDown = false;
        }
        self->m_state = InputState::Idle;
        self->m_pointerId = -1;
        self->m_lastDragClientX = INT_MIN;
        self->m_lastDragClientY = INT_MIN;
        return 0;
    }

    case WM_LBUTTONDOWN:
    {
        if (!self->isWeixinForeground()) break;
        if (self->m_state != InputState::Idle) break;
        SetCapture(hwnd);
        POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        ClientToScreen(hwnd, &pt);
        self->postMouseToWeChat(WM_LBUTTONDOWN, pt, MK_LBUTTON);
        self->m_mouseLeftDown = true;
        return 0;
    }
    case WM_LBUTTONUP:
    {
        if (!self->isWeixinForeground()) break;
        if (self->m_state != InputState::Idle) break;
        ReleaseCapture();
        POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        ClientToScreen(hwnd, &pt);
        self->postMouseToWeChat(WM_LBUTTONUP, pt, 0);
        self->m_mouseLeftDown = false;
        return 0;
    }
    case WM_RBUTTONDOWN:
    {
        if (!self->isWeixinForeground()) break;
        SetCapture(hwnd);
        POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        ClientToScreen(hwnd, &pt);
        self->postMouseToWeChat(WM_RBUTTONDOWN, pt, MK_RBUTTON);
        self->m_mouseRightDown = true;
        return 0;
    }
    case WM_RBUTTONUP:
    {
        if (!self->isWeixinForeground()) break;
        ReleaseCapture();
        POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        ClientToScreen(hwnd, &pt);
        self->postMouseToWeChat(WM_RBUTTONUP, pt, 0);
        self->m_mouseRightDown = false;
        return 0;
    }
    case WM_CAPTURECHANGED:
    {
        self->m_mouseLeftDown = false;
        self->m_mouseRightDown = false;
        break;
    }
    case WM_MOUSEMOVE:
    {
        if (!self->isWeixinForeground()) break;
        if (self->m_state != InputState::Idle) break;
        UINT32 id = GET_POINTERID_WPARAM(wParam);
        POINTER_INFO pi = {};
        if (!GetPointerInfo(id, &pi)) break;
        POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        ClientToScreen(hwnd, &pt);
        WPARAM keys = (self->m_mouseLeftDown ? MK_LBUTTON : 0) | (self->m_mouseRightDown ? MK_RBUTTON : 0);
        if (keys != 0)
            self->postMouseToWeChat(WM_MOUSEMOVE, pt, keys);
        return 0;
    }
    case WM_MOUSEWHEEL:
    {
        if (!self->isWeixinForeground()) break;
        short zDelta = GET_WHEEL_DELTA_WPARAM(wParam);
        POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        ClientToScreen(hwnd, &pt);
        self->sendWheelToWeChat(zDelta, pt);
        return 0;
    }

    default:
        break;
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}
