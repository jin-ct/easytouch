#ifndef WINDOWFOCUSHELPER_H
#define WINDOWFOCUSHELPER_H

#include <QObject>
#include <windows.h>

class WindowFocusHelper : public QObject
{
    Q_OBJECT
public:
    explicit WindowFocusHelper(QObject *parent = nullptr);
    ~WindowFocusHelper();

    bool start();
    void stop();
    bool isActive() const { return m_active; }

private:
    static LRESULT CALLBACK shellWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
    static bool isFocusableWindow(HWND hwnd);
    static bool isForegroundInWhitelist();
    void scheduleFocusToWindow(HWND hwnd, bool isDelay = false);
    void applyFocusToWindow(HWND hwnd);

    HWND m_shellHost{ nullptr };
    bool m_active{ false };
    UINT m_msgShellHook{ 0 };
};

#endif // WINDOWFOCUSHELPER_H
