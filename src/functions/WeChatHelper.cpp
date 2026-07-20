#include "WechatHelper.h"
#include <QGuiApplication>
#include <QScreen>
#include <QString>
#include <cmath>
#include <windowsx.h>
#include "../components/WindowMonitor.h"

const wchar_t *WeChatHelper::s_overlayClassName = L"WeChatHelperOverlay";

static const int kScrollDragThreshold = 12;
static const int kLongPressMs = 500;
static const float kWheelDeltaScale = 3;         // 滚轮 delta = dy * scale，与滑动距离成正比
static const int kWheelDeltaMax = 360;           // 单次最大 delta，避免速度突变
static const float kVelocityThresholdMin = 1.2;  // 触发惯性的速度阈值
static const double kVelocityThresholdMax = 360; // 惯性计算的最大速度值，避免速度突变
static const float kMaxVelocityScale = 0.95;     // 惯性的最大速度占输入速度比例
static const float kVelocityScale = 0.90;        // 惯性单次变化比例
static const float kVelocityScaleInterval = 12;  // 惯性单次变化时间间隔 (ms)
static const int updateHoleInterval = 12;        // 覆盖层穿透区域位置更新时间间隔 (ms)
static const int holeSideLengthMax = 61;         // 覆盖层穿透区域最大边长
static const int holeSideChangeInterval = 200;   // 覆盖层穿透区域边长缩小停留时间 (ms)

WeChatHelper::WeChatHelper(QObject *parent)
    : QObject(parent)
{
    QObject::connect(&m_inertiaTimer, &QTimer::timeout, this, [this] {
        m_inertiaVelocity *= kVelocityScale;
        if (std::abs(m_inertiaVelocity) < 0.01) {
            m_inertiaTimer.stop();
            SetCursorPos(0, 0);
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

    QObject::connect(&m_updateHoleTimer, &QTimer::timeout, this, [this](){overlayUpdateHole();});
    QObject::connect(&m_holeSideTimer, &QTimer::timeout, this, &WeChatHelper::overlayUpdateHoleSide);
    emit loaded();
}

WeChatHelper::~WeChatHelper()
{
    m_foregroundCheckTimer.stop();
    destroyOverlay();
}

bool WeChatHelper::isWeixinForeground()
{
    WindowInfo win = WindowMonitor::instance()->getTopWindow();
    bool isExeNameMatch = win.exeName.toLower() == "weixin.exe";
    bool isStyleMatch = win.style & WS_MAXIMIZEBOX;
    return isExeNameMatch && isStyleMatch;
}

HWND WeChatHelper::getWeChatHwnd()
{
    return WindowMonitor::instance()->getTopWindow().hwnd;
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
            m_updateHoleTimer.stop();
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
                overlayUpdateHole(true);
                SetWindowPos(m_overlay, HWND_NOTOPMOST, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE);  // 重新置顶
                SetWindowPos(m_overlay, HWND_TOPMOST, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE);
                if (!m_updateHoleTimer.isActive())
                    m_updateHoleTimer.start(updateHoleInterval);
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
                overlayUpdateHole(true);
                SetWindowPos(m_overlay, HWND_NOTOPMOST, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE);  // 重新置顶
                SetWindowPos(m_overlay, HWND_TOPMOST, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE);
                if (!m_updateHoleTimer.isActive())
                    m_updateHoleTimer.start(updateHoleInterval);
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

void WeChatHelper::overlayUpdateHole(bool fouce)
{
    POINT pt;
    GetCursorPos(&pt);
    if (((pt.x == g_holeCenter.x && pt.y == g_holeCenter.y)  ||
        m_state == InputState::TouchScroll ||
        m_state == InputState::TouchPending) && !fouce)
        return;
    m_holeSideTimer.start(holeSideChangeInterval);
    if (m_holeSideLength == 1)
        m_holeSideLength = holeSideLengthMax;
    updateHole(m_overlay, pt);
    g_holeCenter = pt;
}

void WeChatHelper::overlayUpdateHoleSide()
{
    m_holeSideTimer.stop();
    POINT pt;
    GetCursorPos(&pt);
    if (m_holeSideLength > 1 && pt.x == g_holeCenter.x && pt.y == g_holeCenter.y) {
        m_holeSideLength = 1;
        updateHole(m_overlay, pt);
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

void WeChatHelper::onLongPressTimeout()
{
    if (m_state != InputState::TouchPending) return;
    m_longPressFired = true;
    POINT pt = { m_touchStartX, m_touchStartY };
    updateHole(m_overlay, pt);
    SetCursorPos(pt.x, pt.y);
    INPUT inputs[2] = {};
    inputs[0].type = INPUT_MOUSE;
    inputs[0].mi.dwFlags = MOUSEEVENTF_RIGHTDOWN;
    inputs[1].type = INPUT_MOUSE;
    inputs[1].mi.dwFlags = MOUSEEVENTF_RIGHTUP;
    SendInput(2, inputs, sizeof(INPUT));
}

void WeChatHelper::updateHole(HWND hwnd, POINT center)
{
    RECT rc;
    GetWindowRect(hwnd, &rc);
    HRGN full = CreateRectRgn(0, 0, rc.right - rc.left, rc.bottom - rc.top);
    POINT clientPt = center;
    ScreenToClient(hwnd, &clientPt);
    int radius = (m_holeSideLength - 1) / 2;
    HRGN hole = CreateRectRgn(
        clientPt.x - radius, clientPt.y - radius,
        clientPt.x + radius + 1, clientPt.y + radius + 1);
    // 挖洞
    CombineRgn(full, full, hole, RGN_DIFF);
    SetWindowRgn(hwnd, full, TRUE);
    DeleteObject(hole);
    DeleteObject(full);
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

    m_inertiaTimer.start(kVelocityScaleInterval);
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

    // 移动系统光标到目标位置，让 SendInput 生成的 WM_MOUSEWHEEL 以该点为落脚
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
            // int dx = x - self->m_lastX;
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
                        self->updateHole(self->m_overlay, pi.ptPixelLocationRaw);
                        self->m_holeSideLength = holeSideLengthMax;
                        SetCursorPos(x, y);
                        INPUT inputs[1] = {};
                        inputs[0].type = INPUT_MOUSE;
                        inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
                        SendInput(1, inputs, sizeof(INPUT));
                    }
                }
            }

            if (self->m_state == InputState::TouchScroll && std::abs(dy) > 2) {
                self->recordSample(dy, self->m_timer.elapsed());
                int absDelta = std::min((int)(std::abs(dy) * kWheelDeltaScale), kWheelDeltaMax);
                int delta = (dy > 0 ? 1 : -1) * absDelta;
                self->sendWheelViaMouseInput(delta);
            }
            if (self->m_state == InputState::TouchDrag) {
                self->updateHole(self->m_overlay, pi.ptPixelLocationRaw);
                self->m_holeSideLength = holeSideLengthMax;
                SetCursorPos(x, y);
                INPUT inputs[1] = {};
                inputs[0].type = INPUT_MOUSE;
                inputs[0].mi.dwFlags = MOUSEEVENTF_MOVE;
                SendInput(1, inputs, sizeof(INPUT));
            }

            self->m_lastX = x;
            self->m_lastY = y;
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
            if (self->m_state == InputState::TouchScroll) {
                self->startInertia();
                SetCursorPos(0, 0);
            }
            else if (self->m_state == InputState::TouchDrag) {
                INPUT inputs[1] = {};
                inputs[0].type = INPUT_MOUSE;
                inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTUP;
                SendInput(1, inputs, sizeof(INPUT));
            }
            else if (self->m_state == InputState::TouchPending && !self->m_longPressFired) {
                POINT pt = { self->m_touchStartX, self->m_touchStartY };
                self->updateHole(self->m_overlay, pt);
                SetCursorPos(pt.x, pt.y);
                INPUT inputs[2] = {};
                inputs[0].type = INPUT_MOUSE;
                inputs[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
                inputs[1].type = INPUT_MOUSE;
                inputs[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;
                SendInput(2, inputs, sizeof(INPUT));
            }
            self->m_longPressFired = false;
        }
        self->m_state = InputState::Idle;
        self->m_pointerId = -1;
        return 0;
    }

    case WM_MOUSEMOVE:
    {
        if (!self->isWeixinForeground()) break;
        if (self->m_state != InputState::Idle) break;
        if (!self->m_updateHoleTimer.isActive())
            self->m_updateHoleTimer.start(updateHoleInterval);
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
