import QtQuick
import QtQuick.Controls
import Functions 1.0
import "./components"

ApplicationWindow {
    visible: true
    opacity: 0
    id: windows

    property int windowVerticalMargin: 15
    property int windowHorizontalMargin: 8
    property int funBtnCount: 0
    property int funBtnHeight: 36
    property int windowWidth: 42
    property int windowBaseHeight: 80
    property int rightWindowHeight: windowBaseHeight + (funBtnHeight*funBtnCount)
    property int leftWindowHeight: windowBaseHeight + (funBtnHeight*funBtnCount)
    property int windowAnimationDuration: 60
    property double windowLowOpacity: 0.5
    property double windowOpacity: 1.0
    property double windowOpacityChangeDuration: 10000

    property bool isFolded: false
    property bool isUsbInserted: false

    Functions {
        id: funs

        onUsbInserted: {
            isUsbInserted = true
            showUsbBtn()
            notificationHp.showNotification("openUsb", "点击打开U盘", "轻触此处打开U盘")
            console.log("openUsb")
        }
        onUsbRemoved: {
            isUsbInserted = false
            hideUsbBtn()
            notificationHp.showNotification("rmUsb", "U盘已安全拔出", "U盘已安全拔出")
            console.log("rmUsb")
        }
    }

    FullscreenWatcher {
        id: fsWatcher

        onFullscreenEntered: {
            if (isUsbInserted)
                hideUsbBtn()
        }
        onFullscreenExited: {
            if (isUsbInserted)
                showUsbBtn()
        }
    }

    NotificationHelper {
        id: notificationHp

        onNotificationClicked: (id) => {
            if (id === "openUsb") {
                funs.openDrive()
            }
        }
    }

    Component.onCompleted: {
        funs.setWindowNoActivate(windows)
        funs.setWindowNoActivate(rightWindow)
        funs.setWindowNoActivate(leftWindow)
        setTimeout(() => {
            rightWindowOpacity.drop()
            leftWindowOpacity.drop()
            windowsOpacityTimer.start()
        }, 8000)
    }


    Timer {id: timer}
    function setTimeout(cb, delayTime) {
       timer.interval = delayTime;
       timer.repeat = false;
       timer.triggered.connect(cb);
       timer.start();
    }

    function handleWindowHeightChange(from, to, isRightWindows) {
        if (to > from) {
            if (isRightWindows) {
                rightWindow.height = windows.rightWindowHeight
            } else {
                leftWindow.height = windows.leftWindowHeight
            }
        }
        setTimeout(() => {
            if (to < from) {
                if (isRightWindows) {
                    rightWindow.height = windows.rightWindowHeight
                } else {
                    leftWindow.height = windows.leftWindowHeight
                }
            }
        }, windowAnimationDuration)
    }

    Window {
        id: rightWindow
        width: windowWidth
        height: windowBaseHeight
        x: Screen.desktopAvailableWidth - (width + windowHorizontalMargin)
        y: Screen.desktopAvailableHeight - (height + windowVerticalMargin)
        visible: true
        color: "transparent"
        flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
        opacity: 1
        title: "易触控工具栏"

        WindowContent {
            id: rightContent
            window: rightWindow
            windowBaseHeight: windows.windowBaseHeight
            funsObject: funs
            onIsFoldedChanged: {
                windows.isFolded = rightContent.isFolded
                windows.rightWindowHeight = isFolded ? windowBaseHeight : windowBaseHeight + (funBtnHeight*funBtnCount)
                handleWindowHeightChange(rightWindow.height, windows.rightWindowHeight, true)
                rightWindowAnimation.start()
            }
            onFunBtnCountChanged: {
                windows.funBtnCount = rightContent.funBtnCount
                windows.rightWindowHeight = isFolded ? windowBaseHeight : windowBaseHeight + (funBtnHeight*funBtnCount)
                handleWindowHeightChange(rightWindow.height, windows.rightWindowHeight, true)
                rightWindowAnimation.start()
            }
            onBtnClicked: {
                windowsOpacityTimer.stop()
                rightWindowOpacity.rise(true)
                setTimeout(() => {
                    rightWindowOpacity.drop()
                    windowsOpacityTimer.start()
                }, 5000)
            }
        }
    }

    Window {
        id: leftWindow
        width: windowWidth
        height: windowBaseHeight
        x: windowHorizontalMargin
        y: Screen.desktopAvailableHeight - (height + windowVerticalMargin)
        visible: true
        color: "transparent"
        flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
        opacity: 1
        title: "易触控工具栏"

        WindowContent {
            id: leftContent
            window: leftWindow
            windowBaseHeight: windows.windowBaseHeight
            funsObject: funs
            onIsFoldedChanged: {
                windows.isFolded = leftContent.isFolded
                windows.leftWindowHeight = isFolded ? windowBaseHeight : windowBaseHeight + (funBtnHeight*funBtnCount)
                handleWindowHeightChange(leftWindow.height, windows.leftWindowHeight, false)
                leftWindowAnimation.start()
            }
            onFunBtnCountChanged: {
                windows.funBtnCount = leftContent.funBtnCount
                windows.leftWindowHeight = isFolded ? windowBaseHeight : windowBaseHeight + (funBtnHeight*funBtnCount)
                handleWindowHeightChange(leftContent.height, windows.leftWindowHeight, false)
                leftWindowAnimation.start()
            }
            onBtnClicked: {
                windowsOpacityTimer.stop()
                leftWindowOpacity.rise(true)
                setTimeout(() => {
                    leftWindowOpacity.drop()
                    windowsOpacityTimer.start()
                }, 5000)
            }
        }
    }

    function showUsbBtn() {
        rightContent.isFunOpenUDiskEnable = true;
        rightContent.isFunRmUDiskEnable = true;
        leftContent.isFunOpenUDiskEnable = true;
        leftContent.isFunRmUDiskEnable = true;
    }
    function hideUsbBtn() {
        rightContent.isFunOpenUDiskEnable = false;
        rightContent.isFunRmUDiskEnable = false;
        leftContent.isFunOpenUDiskEnable = false;
        leftContent.isFunRmUDiskEnable = false;
    }

    PropertyAnimation {
        id: rightWindowAnimation
        target: rightContent
        property: "height"
        duration: windowAnimationDuration
        to: windows.rightWindowHeight
    }
    PropertyAnimation {
        id: leftWindowAnimation
        target: leftContent
        property: "height"
        duration: windowAnimationDuration
        to: windows.leftWindowHeight
    }
    PropertyAnimation {
        id: leftWindowOpacity
        target: leftWindow
        property: "opacity"
        duration: 1500

        function rise(isFast = false) {
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowLowOpacity
            to = windowOpacity
            start()
        }
        function drop(isFast = false) {
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowOpacity
            to = windowLowOpacity
            start()
        }
        function change(isFast = false) {
            if (leftWindow.opacity === windowOpacity) {
                drop(isFast)
            } else {
                rise(isFast)
            }
        }
    }
    PropertyAnimation {
        id: rightWindowOpacity
        target: rightWindow
        property: "opacity"
        duration: 1500

        function rise(isFast = false) {
            if (rightWindow.opacity === windowOpacity) return
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowLowOpacity
            to = windowOpacity
            start()
        }
        function drop(isFast = false) {
            if (rightWindow.opacity !== windowOpacity) return
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowOpacity
            to = windowLowOpacity
            start()
        }
        function change(isFast = false) {
            if (rightWindow.opacity === windowOpacity) {
                drop(isFast)
            } else {
                rise(isFast)
            }
        }
    }

    Timer {
        id: windowsOpacityTimer
        interval: windowOpacityChangeDuration
        onTriggered: {
            rightWindowOpacity.change()
            leftWindowOpacity.change()
            setTimeout(() => {
                rightWindowOpacity.change()
                leftWindowOpacity.change()
            }, 3000)
        }
    }
}
