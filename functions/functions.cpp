#include "functions.h"
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

//=== 用于全局安装 nativeEventFilter ===
class UsbEventFilter : public QAbstractNativeEventFilter {
public:
    UsbEventFilter(Functions *mgr) : funs(mgr) {}
    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override {
        return funs->nativeEventFilter(eventType, message, result);
    }
private:
    Functions *funs;
};

Functions::Functions(QObject *parent)
    : QObject{parent}
{
    qApp->installNativeEventFilter(new UsbEventFilter(this));
}

void Functions::setWindowNoActivate(QWindow *window)
{
    HWND hwnd = (HWND)window->winId();
    SetWindowLongPtr(hwnd, GWL_EXSTYLE,
                     GetWindowLongPtr(hwnd, GWL_EXSTYLE) | WS_EX_NOACTIVATE);
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
        if (!isSignalsEmit) emit usbRemoved();
        isSignalsEmit = true;
        QTimer::singleShot(500, this, [=](){
            isSignalsEmit = false;
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

bool Functions::nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result)
{
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
                    if (!isSignalsEmit) emit usbInserted();
                    isUsbInserted = true;
                    isSignalsEmit = true;
                    QTimer::singleShot(500, this, [=](){
                        isSignalsEmit = false;
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
            if (!isSignalsEmit) emit usbRemoved();
            isSignalsEmit = true;
            QTimer::singleShot(500, this, [=](){
                isSignalsEmit = false;
            });
            isUsbInserted = false;
        }
    }
}
