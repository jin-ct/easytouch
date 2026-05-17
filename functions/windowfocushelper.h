#ifndef WINDOWFOCUSHELPER_H
#define WINDOWFOCUSHELPER_H

#include <QObject>
#include <windows.h>
#include <QTimer>

class WindowFocusHelper : public QObject
{
    Q_OBJECT
public:
    explicit WindowFocusHelper(QObject *parent = nullptr);
    ~WindowFocusHelper();

    bool start();
    void stop();
    bool isActive() const { return m_active; }

signals:
    void started();
    void newWindowCreated();

private:
    static LRESULT CALLBACK shellWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
    static bool isFocusableWindow(HWND hwnd);
    static bool isForegroundInWhitelist();
    static bool isWindowInWhitelist(HWND hwnd);
    void scheduleFocusToWindow(HWND hwnd, bool isDelay = false);
    void applyFocusToWindow(HWND hwnd);

    QTimer focusSettingTimer;
    HWND focusSettingWindow;

    HWND m_shellHost{ nullptr };
    bool m_active{ false };
    UINT m_msgShellHook{ 0 };
};

#endif // WINDOWFOCUSHELPER_H
