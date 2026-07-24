#ifndef MOUSEHOOK_H
#define MOUSEHOOK_H

#include <QThread>
#include <QGlobalStatic>
#include <windows.h>
#include <QTimer>
#include <QRect>
#include <QVariant>
#include <QMutex>
#include <QEvent>

class MouseHook : public QThread
{
    Q_OBJECT
    Q_PROPERTY(bool hasMouseEvent MEMBER hasMouseEvent NOTIFY mousePressed)
public:
    MouseHook();
    static MouseHook* instance();
    void stop();

    Q_INVOKABLE void addIgnoreAreas(const QVariant &rect, QVariant idStr);
    Q_INVOKABLE void removeIgnoreAreas(QVariant idStr);

    Q_INVOKABLE bool getHasMouseEvent();

    static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam);


public slots:
    void onMouse(QEvent::Type eventType);

signals:
    void mousePressedUnfiltered(QVariant pos);
    void mousePressed(QVariant pos);
    void mouseMoved(QVariant pos);

    void installed();
    void uninstalled();

protected:
    void run() override;

private:
    void installHook();
    void uninstallHook();
    bool isRectContains(const QRect &rect, const QPoint &point);
    void setHasMouseEvent();
    static HHOOK g_mouseHook;
    QMutex mutex;
    QMap<QString, QRect> ignoreAreas;
    QTimer recordTimer;
    bool hasMouseEvent = false;
};

#endif // MOUSEHOOK_H
