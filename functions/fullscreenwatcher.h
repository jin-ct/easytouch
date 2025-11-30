#ifndef FULLSCREENWATCHER_H
#define FULLSCREENWATCHER_H

#include <QObject>
#include <QThread>
#include <QString>
#include <QScreen>
#include <QGuiApplication>
#include <windows.h>
#include <dwmapi.h>

class FullscreenWorker : public QObject {
    Q_OBJECT
public:
    explicit FullscreenWorker(QObject *parent = nullptr);
    bool running = false;
    bool lastState = false;

public slots:
    void process();

signals:
    void fullscreenEntered(QString windowTitle);
    void fullscreenExited(QString windowTitle);
};

class FullscreenWatcher : public QObject {
    Q_OBJECT
public:
    explicit FullscreenWatcher(QObject *parent = nullptr);
    ~FullscreenWatcher();

signals:
    void fullscreenEntered(QString windowTitle);
    void fullscreenExited(QString windowTitle);

private:
    QThread workerThread;
    FullscreenWorker *worker = nullptr;
};

#endif // FULLSCREENWATCHER_H
