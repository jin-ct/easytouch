#ifndef WECHATHELPER_H
#define WECHATHELPER_H

#include <QObject>
#include <QElapsedTimer>
#include <QTimer>
#include <QVector>
#include <climits>
#include <windows.h>

class WeChatHelper : public QObject
{
    Q_OBJECT
public:
    explicit WeChatHelper(QObject *parent = nullptr);
    ~WeChatHelper();

private:
    enum class InputState {
        Idle,
        TouchPending,
        TouchScroll,
        TouchDrag,
        MouseActive
    };

    // 覆盖层
    static const wchar_t *s_overlayClassName;
    HWND m_overlay = nullptr;
    QTimer m_foregroundCheckTimer;
    bool m_overlayVisible = false;
    RECT m_lastOverlayRect = {};
    bool m_mouseLeftDown = false;
    bool m_mouseRightDown = false;

    // 触摸状态
    InputState m_state = InputState::Idle;
    int m_pointerId = -1;
    int m_lastX = 0;
    int m_lastY = 0;
    int m_touchStartX = 0;
    int m_touchStartY = 0;
    QTimer m_longPressTimer;
    bool m_longPressFired = false;
    HWND m_dragTargetHwnd = nullptr;  // 拖拽全程固定发往主窗口，便于标题栏拖动
    int m_lastDragClientX = INT_MIN;   // 上次发送的拖拽客户区坐标，用于去抖
    int m_lastDragClientY = INT_MIN;
    POINT m_lastWheelScreenPt = { 0, 0 }; // 最近一次滚轮的落脚点（用于惯性）

    // 惯性
    QElapsedTimer m_timer;
    QVector<QPair<qint64, int>> m_samples;
    QTimer m_inertiaTimer;
    double m_velocity = 0.0;

    bool isWeixinForeground();
    HWND getWeChatHwnd();
    bool getWeChatClientRectInScreen(RECT *outRect);
    bool getWeChatWindowRectInScreen(RECT *outRect);
    void createOverlay();
    void destroyOverlay();
    void updateOverlayVisibility();
    void recordSample(int deltaY);
    double calcVelocity();
    void startInertia();
    void sendWheelToWeChat(int delta, const POINT &screenPt);
    void sendWheelViaMouseInput(int delta);                     // 通过 SendInput 注入鼠标滚轮
    void postMouseToWeChat(UINT msg, const POINT &screenPt, WPARAM wParam);
    void postMouseToHwnd(HWND h, UINT msg, const POINT &screenPt, WPARAM wParam);
    void onLongPressTimeout();

    static LRESULT CALLBACK overlayWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
};

#endif // WECHATHELPER_H
