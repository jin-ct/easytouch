#ifndef FUNCTIONS_H
#define FUNCTIONS_H

#include <QObject>
#include <QWindow>
#include <windows.h>
#include <winioctl.h>

class Functions : public QObject
{
    Q_OBJECT
public:
    explicit Functions(QObject *parent = nullptr);
    Q_INVOKABLE void setWindowNoActivate(QWindow* window);

    Q_INVOKABLE void closeTopWindow();
    Q_INVOKABLE void openDrive();
    Q_INVOKABLE bool ejectDrive();
    Q_INVOKABLE void setVolume(float level);
    Q_INVOKABLE float getVolume();

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result);

signals:
    void usbInserted();
    void usbRemoved();

private:
    void checkUsbDrives(bool inserted);
    QStringList usbDrivePaths;
    bool isUsbInserted = false;
    bool isSignalsEmit = false;
};

#endif // FUNCTIONS_H
