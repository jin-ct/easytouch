/**
 * @file functions.h
 * @note 用于设置窗口属性和监听信号，以及实现基本功能（如关闭窗口、系统音量等）
 */

#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <QObject>
#include <QWindow>
#include <windows.h>
#include <winioctl.h>
#include <QSettings>
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QHash>

class Functions : public QObject
{
    Q_OBJECT
public:
    explicit Functions(QObject *parent = nullptr);
    ~Functions();
    Q_INVOKABLE void setWindowNoActivate(QWindow* window);
    Q_INVOKABLE void setOwner(QWindow *child, QWindow *owner);
    Q_INVOKABLE void disableTouchFeedback(QWindow* window);
    Q_INVOKABLE void resetWindowStayOnTop(QWindow* window);
    Q_INVOKABLE void ensureWinodowTopMost(QWindow* window);

    Q_INVOKABLE void closeTopWindow();
    Q_INVOKABLE void openDrive();
    Q_INVOKABLE bool ejectDrive();
    Q_INVOKABLE void setVolume(float level);
    Q_INVOKABLE float getVolume();
    Q_INVOKABLE bool getIsMute();
    Q_INVOKABLE void setMute(bool mute);
    Q_INVOKABLE bool setAutoStart(bool enable);

    // 弹出层
    Q_INVOKABLE bool isRectContains(const QVariant &rect, const QVariant &point);
    Q_INVOKABLE QVariant windowMapFromGlobal(QWindow *window, const QVariant &pos);

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result);

    // 系统鼠标钩子
    // 系统钩子
    Q_INVOKABLE void installHook();
    Q_INVOKABLE void uninstallHook();
    static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam);

    static Functions *instance;
    static HHOOK g_mouseHook;

public slots:
    void onMouse(int eventType); // 0 - 鼠标按下

signals:
    void usbInserted();
    void usbRemoved();

    // 钩子回调中调用
    void mousePressed(QVariant pos);

private:
    void checkUsbDrives(bool inserted);
    QStringList usbDrivePaths;
    bool isUsbInserted = false;
    bool isSignalsEmit = false;

    // 仅用于恢复系统触摸反馈设置（HKCU）
    bool touchFeedbackSaved = false;
    QString prevContactVisualization;
    QString prevGestureVisualization;

};

#endif // FUNCTIONS_H
