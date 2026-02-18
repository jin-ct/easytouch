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

class Functions : public QObject
{
    Q_OBJECT
public:
    explicit Functions(QObject *parent = nullptr);
    ~Functions();
    Q_INVOKABLE void setWindowNoActivate(QWindow* window);
    Q_INVOKABLE void setOwner(QWindow *child, QWindow *owner);
    Q_INVOKABLE void disableTouchFeedback(QWindow* window);

    Q_INVOKABLE void closeTopWindow();
    Q_INVOKABLE void openDrive();
    Q_INVOKABLE bool ejectDrive();
    Q_INVOKABLE void setVolume(float level);
    Q_INVOKABLE float getVolume();
    Q_INVOKABLE bool getIsMute();
    Q_INVOKABLE void setMute(bool mute);
    Q_INVOKABLE bool setAutoStart(bool enable);

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result);

signals:
    void usbInserted();
    void usbRemoved();

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
