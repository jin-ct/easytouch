#ifndef MOUSEHOOK_H
#define MOUSEHOOK_H

#include <QObject>
#include <QThread>
#include <QGlobalStatic>
#include <windows.h>
#include <QTimer>
#include <QRect>
#include <QVariant>
#include <QMutex>
#include <QEvent>

class MouseHookWorker : public QObject
{
    Q_OBJECT
public:
    MouseHookWorker();
    ~MouseHookWorker();
    void process();

    void addIgnoreAreas(const QRect &rect, QString idStr);
    void removeIgnoreAreas(QString idStr);
    bool getHasMouseEvent();

    static MouseHookWorker* instance;

public slots:
    void onMouse(QEvent::Type eventType);

signals:
    void mousePressedUnfiltered(QVariant pos);
    void mousePressed(QVariant pos);
    void mouseMoved(QVariant pos);

    void installed();
    void uninstalled();

private:
    QMutex mutex;
    void installHook();
    void uninstallHook();
    bool isRectContains(const QRect &rect, const QPoint &point);
    void setHasMouseEvent();
    static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam);
    static HHOOK g_mouseHook;
    QMap<QString, QRect> ignoreAreas;
    QTimer *recordTimer{};
    bool hasMouseEvent = false;
};

class MouseHook : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool hasMouseEvent READ getHasMouseEvent NOTIFY mousePressed)
public:
    MouseHook();
    ~MouseHook();
    static MouseHook* instance();

    Q_INVOKABLE void addIgnoreAreas(const QVariant &rect, QVariant idStr);
    Q_INVOKABLE void removeIgnoreAreas(QVariant idStr);
    Q_INVOKABLE bool getHasMouseEvent();

signals:
    void mousePressedUnfiltered(QVariant pos);
    void mousePressed(QVariant pos);
    void mouseMoved(QVariant pos);

    void installed();
    void uninstalled();

private:
    QMutex mutex;
    QThread workerThread{};
    MouseHookWorker* worker{};
};

#endif // MOUSEHOOK_H
