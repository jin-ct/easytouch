/**
 * @file functions.cpp
 * @note 用于设置窗口或监听信号，以及实现基本功能（如关闭窗口、系统音量等）
 */

#include "Functions.h"
#include <QDesktopServices>
#include <QUrl>
#include <QFile>
#include <QAbstractNativeEventFilter>
#include <QGuiApplication>
#include <Dbt.h>
#include <mmdeviceapi.h>
#include <endpointvolume.h>
#include <comdef.h>
#include <QTimer>
#include <QSettings>
#include <QDebug>
#include <QProcess>
#include <WinUser.h>
#include <windowsx.h>


//=== 用于全局安装 nativeEventFilter ===
class EventFilter : public QAbstractNativeEventFilter {
public:
    EventFilter(Functions *mgr) : funs(mgr) {}
    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override {
        return funs->nativeEventFilter(eventType, message, result);
    }
private:
    Functions *funs;
};

Functions::Functions(QObject *parent)
    : QObject{parent}
{
    qApp->installNativeEventFilter(new EventFilter(this));
}

Functions::~Functions()
{
}

void Functions::setWindowNoActivate(QWindow *window)
{
    HWND hwnd = (HWND)window->winId();
    SetWindowLongPtr(hwnd, GWL_EXSTYLE,
                     GetWindowLongPtr(hwnd, GWL_EXSTYLE) | WS_EX_NOACTIVATE);
}

void Functions::setOwner(QWindow *child, QWindow *owner)
{
    if (!child || !owner) return;

    HWND childHwnd = (HWND)child->winId();
    HWND ownerHwnd = (HWND)owner->winId();

    SetWindowLongPtr(
        childHwnd,
        GWLP_HWNDPARENT,
        (LONG_PTR)ownerHwnd
        );
}

void Functions::disableTouchFeedback(QWindow *window)
{
    if (!window) return;

    HWND hwnd = (HWND)window->winId();
    if (!hwnd) return;

    // Windows 8+ 方法：使用 SetWindowFeedbackSetting
    // FEEDBACK_TOUCH_CONTACTVISUALIZATION = 1
    // FEEDBACK_GESTURE_END = 2
    // FEEDBACK_PEN_BARRELVISUALIZATION = 3
    // FEEDBACK_PEN_TAP = 4
    // FEEDBACK_PEN_DOUBLETAP = 5
    // FEEDBACK_PEN_PRESSANDHOLD = 6
    // FEEDBACK_PEN_RIGHTTAP = 7
    // FEEDBACK_TOUCH_TAP = 9
    // FEEDBACK_TOUCH_DOUBLETAP = 10
    // FEEDBACK_TOUCH_PRESSANDHOLD = 11
    // FEEDBACK_TOUCH_RIGHTTAP = 12
    // FEEDBACK_GESTURE_PRESSANDTAP = 13
    // FEEDBACK_MAX = 0xFFFFFFFF

    // BOOL SetWindowFeedbackSetting(HWND, FEEDBACK_TYPE, DWORD, UINT32, const VOID*)
    typedef BOOL (WINAPI *SetWindowFeedbackSettingFunc)(HWND, UINT32, DWORD, UINT32, const VOID*);
    HMODULE hUser32 = LoadLibraryW(L"user32.dll");
    if (hUser32) {
        SetWindowFeedbackSettingFunc pSetWindowFeedbackSetting = 
            (SetWindowFeedbackSettingFunc)GetProcAddress(hUser32, "SetWindowFeedbackSetting");
        
        if (pSetWindowFeedbackSetting) {
            // 通过传入 BOOL(false) 关闭指定反馈（经验做法，Windows 8+ 有效）
            const BOOL off = FALSE;
            const UINT32 sz = sizeof(off);

            pSetWindowFeedbackSetting(hwnd, 1, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 2, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 3, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 4, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 5, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 6, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 7, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 9, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 10, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 11, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 12, 0, sz, &off);
            pSetWindowFeedbackSetting(hwnd, 13, 0, sz, &off);
        }
        FreeLibrary(hUser32);
    }
}

void Functions::resetWindowStayOnTop(QWindow *window)
{
    if (!window) return;
    HWND hwnd = (HWND)window->winId();
    SetWindowPos(hwnd, HWND_NOTOPMOST, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOSENDCHANGING);
    SetWindowPos(hwnd, HWND_TOPMOST, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOSENDCHANGING);
}

void Functions::ensureWinodowTopMost(QWindow *window)
{
    if (!window) return;
    HWND hwnd = (HWND)window->winId();
    LONG exStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
    if (!(exStyle & WS_EX_TOPMOST))
    {
        SetWindowPos(hwnd, HWND_TOPMOST, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOSENDCHANGING);
    }
    SetWindowPos(hwnd, HWND_TOP, 0,0,0,0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOSENDCHANGING);
}

void Functions::closeTopWindow()
{
    INPUT inputs[4] = {};

    // 按下 Alt
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VK_MENU; // Alt

    // 按下 F4
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = VK_F4;

    // 释放 F4
    inputs[2].type = INPUT_KEYBOARD;
    inputs[2].ki.wVk = VK_F4;
    inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;

    // 释放 Alt
    inputs[3].type = INPUT_KEYBOARD;
    inputs[3].ki.wVk = VK_MENU;
    inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;

    SendInput(4, inputs, sizeof(INPUT));
}

void Functions::openDrive()
{
    for (const QString &path : usbDrivePaths) {
        QDesktopServices::openUrl(path);
    }
}

bool Functions::ejectDrive()
{
    bool success = true;
    for (const QString &path : usbDrivePaths) {
        WCHAR volumeName[] = L"\\\\.\\X:";
        volumeName[4] = path.at(0).unicode();

        HANDLE hVolume = CreateFileW(volumeName, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                                     NULL, OPEN_EXISTING, 0, NULL);
        if (hVolume == INVALID_HANDLE_VALUE)
            break;

        DWORD bytesReturned = 0;
        success = DeviceIoControl(hVolume, FSCTL_LOCK_VOLUME, NULL, 0, NULL, 0, &bytesReturned, NULL) &&
            DeviceIoControl(hVolume, FSCTL_DISMOUNT_VOLUME, NULL, 0, NULL, 0, &bytesReturned, NULL) &&
            DeviceIoControl(hVolume, IOCTL_STORAGE_EJECT_MEDIA, NULL, 0, NULL, 0, &bytesReturned, NULL);

        CloseHandle(hVolume);
    }

    if (success) {
        if (!isUsbSignalsEmit) emit usbRemoved();
        isUsbSignalsEmit = true;
        QTimer::singleShot(500, this, [=](){
            isUsbSignalsEmit = false;
        });
        isUsbInserted = false;
    }
    return success;
}

void Functions::setVolume(float level)
{
    CoInitialize(nullptr);

    IMMDeviceEnumerator *deviceEnumerator = nullptr;
    CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL, IID_PPV_ARGS(&deviceEnumerator));

    IMMDevice *defaultDevice = nullptr;
    deviceEnumerator->GetDefaultAudioEndpoint(eRender, eConsole, &defaultDevice);

    IAudioEndpointVolume *endpointVolume = nullptr;
    defaultDevice->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL, nullptr, (void**)&endpointVolume);

    endpointVolume->SetMasterVolumeLevelScalar(level, nullptr);

    endpointVolume->Release();
    defaultDevice->Release();
    deviceEnumerator->Release();
    CoUninitialize();
}

float Functions::getVolume()
{
    CoInitialize(nullptr);

    IMMDeviceEnumerator* deviceEnumerator = nullptr;
    CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                     IID_PPV_ARGS(&deviceEnumerator));

    IMMDevice* defaultDevice = nullptr;
    deviceEnumerator->GetDefaultAudioEndpoint(eRender, eConsole, &defaultDevice);

    IAudioEndpointVolume* endpointVolume = nullptr;
    defaultDevice->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL,
                            nullptr, (void**)&endpointVolume);

    float currentVolume = 0.0f;
    endpointVolume->GetMasterVolumeLevelScalar(&currentVolume);

    endpointVolume->Release();
    defaultDevice->Release();
    deviceEnumerator->Release();
    CoUninitialize();

    return currentVolume;
}

bool Functions::getIsMute()
{
    CoInitialize(nullptr);

    IMMDeviceEnumerator* deviceEnumerator = nullptr;
    CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                     IID_PPV_ARGS(&deviceEnumerator));

    IMMDevice* defaultDevice = nullptr;
    deviceEnumerator->GetDefaultAudioEndpoint(eRender, eConsole, &defaultDevice);

    IAudioEndpointVolume* endpointVolume = nullptr;
    defaultDevice->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL,
                            nullptr, (void**)&endpointVolume);

    BOOL isMuted = FALSE;
    endpointVolume->GetMute(&isMuted);

    endpointVolume->Release();
    defaultDevice->Release();
    deviceEnumerator->Release();
    CoUninitialize();

    return isMuted == TRUE;
}

void Functions::setMute(bool mute)
{
    CoInitialize(nullptr);

    IMMDeviceEnumerator* deviceEnumerator = nullptr;
    CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                     IID_PPV_ARGS(&deviceEnumerator));

    IMMDevice* defaultDevice = nullptr;
    deviceEnumerator->GetDefaultAudioEndpoint(eRender, eConsole, &defaultDevice);

    IAudioEndpointVolume* endpointVolume = nullptr;
    defaultDevice->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_ALL,
                            nullptr, (void**)&endpointVolume);

    endpointVolume->SetMute(mute ? TRUE : FALSE, nullptr);

    endpointVolume->Release();
    defaultDevice->Release();
    deviceEnumerator->Release();
    CoUninitialize();
}

bool Functions::setAutoStart(bool enable)
{
    QString appName = QCoreApplication::applicationName();
    QString appPath = QCoreApplication::applicationFilePath();
    appPath = QDir::toNativeSeparators(appPath);

    QSettings reg("HKEY_CURRENT_USER\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                  QSettings::NativeFormat);

    if (enable) {
        reg.setValue(appName, "\"" + appPath + "\"");
        qDebug() << "自启动已启用:" << appPath;
    } else {
        reg.remove(appName);
        qDebug() << "自启动已禁用";
    }

    return true;
}

void Functions::restartApp()
{
    QString cmd = QString("ping 127.0.0.1 -n 3 >nul && start %1")
                      .arg(QDir::toNativeSeparators(qApp->applicationFilePath()));
    QProcess::startDetached("cmd.exe", {"/C", cmd});
    qApp->quit();
}

bool Functions::isRectContains(const QVariant &rect, const QVariant &point)
{
    return rect.toRect().contains(point.toPoint());
}

QVariant Functions::windowMapFromGlobal(QWindow *window, const QVariant &pos)
{
    return QVariant(window->mapFromGlobal(pos.toPoint()));
}

bool Functions::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result)
{
    // U盘事件
    MSG *msg = static_cast<MSG*>(message);
    if (msg->message == WM_DEVICECHANGE) {
        if (msg->wParam == DBT_DEVICEARRIVAL) {
            checkUsbDrives(true);
        } else {
            checkUsbDrives(false);
        }
    }
    return false;
}

void Functions::checkUsbDrives(bool inserted)
{
    if (inserted) {
        DWORD drives = GetLogicalDrives();
        for (char d = 'A'; d <= 'Z'; ++d) {
            if (drives & (1 << (d - 'A'))) {
                QString usbDrivePath = QString("%1:/").arg(d);
                UINT type = GetDriveTypeW(reinterpret_cast<LPCWSTR>(usbDrivePath.utf16()));
                if (type == DRIVE_REMOVABLE) {
                    usbDrivePaths.append(usbDrivePath);
                    if (!isUsbSignalsEmit) emit usbInserted();
                    isUsbInserted = true;
                    isUsbSignalsEmit = true;
                    QTimer::singleShot(500, this, [=](){
                        isUsbSignalsEmit = false;
                    });
                }
            }
        }
    } else if (isUsbInserted) {
        for (int i = 0; i < usbDrivePaths.length(); i++) {
            if (!QFile::exists(usbDrivePaths[i])) {
                usbDrivePaths.removeAt(i);
            }
        }
        if (usbDrivePaths.empty()) {
            if (!isUsbSignalsEmit) emit usbRemoved();
            isUsbSignalsEmit = true;
            QTimer::singleShot(500, this, [=](){
                isUsbSignalsEmit = false;
            });
            isUsbInserted = false;
        }
    }
}
