import QtQuick
import QtQuick.Controls
import Functions 1.0
import "./components"
import "./views"

ApplicationWindow {
    visible: true
    opacity: 0
    id: windows

    property int windowBottomMargin: 20                          // 工具栏窗口初始下边距
    property int windowHorizontalMargin: 8                       // 工具栏窗口初始左右边距
    property int windowWidth: 52                                 // 工具栏窗口宽度
    property int windowHeight: 196                               // 工具栏窗口高度（未折叠）
    property int windowFoldedHeight: 52                          // 工具栏窗口高度（已折叠）
    property int rightWindowHeight:  windowHeight                // 工具栏右窗口当前高度（窗口动画前变换）
    property int leftWindowHeight: windowHeight                  // 工具栏左窗口当前高度（窗口动画前变换）
    property int windowAnimationDuration: 160                    // 工具栏窗口动画时长
    property double windowLowOpacity: 0.40                       // 工具栏窗口最低透明度
    property double windowOpacity: 0.80                          // 工具栏窗口最高透明度
    property double windowOpacityChangeDuration: 10000           // 工具栏窗口透明度改变时间间隔

    // cpp类实例
    Functions {
        id: funs

        onUsbInserted: {
            showUsbBtn()
            notificationHp.showNotification("openUsb", "点击打开U盘", "轻触此处打开U盘")
            console.log("newUsbInserted")
        }
        onUsbRemoved: {
            hideUsbBtn()
            console.log("usbRemoved")
        }
    }
    FullscreenWatcher {
        id: fsWatcher

        onFullscreenEntered: {
        }
        onFullscreenExited: {
        }
    }
    NotificationHelper {
        id: notificationHp

        onNotificationClicked: (id) => {
            if (id === "openUsb") {
                funs.openDrive()
            }
        }
        onAppQuit: {
            fsWatcher.stop()
            Qt.quit()
        }
    }

    // 窗口创建完成
    Component.onCompleted: {
        rightWindow.y = Screen.desktopAvailableHeight - (rightWindowHeight + windowBottomMargin)
        leftWindow.y = Screen.desktopAvailableHeight - (rightWindowHeight + windowBottomMargin)
        rightWindow.height = rightWindowHeight
        leftWindow.height = leftWindowHeight
        funs.setWindowNoActivate(windows)
        funs.setWindowNoActivate(rightWindow)
        funs.setWindowNoActivate(leftWindow)
        setTimeout(() => {
            rightWindowOpacity.drop()
            leftWindowOpacity.drop()
            windowsOpacityTimer.start()
        }, 6000)
        console.log("windowsCompleted")
    }

    // 按钮列表数据
    ListModel {
        id: toolModel
        ListElement { text: "关闭窗口"; idStr: "close"; checked: false; checkable: false; link: false; exclusive: false; icon: "qrc:/icon/close.svg" }
        ListElement { text: "系统音量"; idStr: "volume"; checked: false; checkable: false; link: false; exclusive: false; icon: "qrc:/icon/volume.svg" }
        ListElement { text: "批注"; idStr: "pen"; checked: false; checkable: true; link: true; exclusive: true; icon: "qrc:/icon/pen.svg" }
        // ListElement { text: "屏幕移位"; idStr: "movetool"; checked: false; checkable: true; link: true; exclusive: true; icon: "qrc:/icon/rmudisk.svg" }
        // ListElement { text: "随机点名"; idStr: "随机数"; checked: false; checkable: true; link: false; exclusive: false; icon: "qrc:/icon/UDisk.svg" }
    }

    // =============== 窗口 ===============
    // 批注窗口
    // Whileboard {
    //     id: whileboard
    //     Component.onCompleted: {
    //         // funs.setWindowNoActivate(whileboard)
    //         whileboard.visible = true
    //         // 确保窗口创建出 winId 后再禁用触摸反馈（否则可能不生效）
    //         Qt.callLater(function() { funs.disableTouchFeedback(whileboard) })
    //     }
    // }

    // 工具栏的悬浮对话框
    VolumeDialog {
        id: volumeDialog
        funsObject: funs
    }

    // 右侧工具栏
    Window {
        id: rightWindow
        width: windowWidth
        x: Screen.desktopAvailableWidth - (width + windowHorizontalMargin)
        visible: true
        color: "transparent"
        flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
        opacity: windowOpacity
        title: "易触控工具栏"

        WindowContent {
            id: rightContent
            window: rightWindow
            funsObject: funs
            model: toolModel

            onButtonTriggered: (idStr, checked, pointX, pointY) => {
                handleButtonTriggered(idStr, checked, pointX, pointY)
                // 处理窗口主图标按钮事件
                switch(idStr) {
                case "mainIconClick":
                    isFolded = !isFolded
                    windows.rightWindowHeight = isFolded ? windowFoldedHeight : windowHeight
                    handleWindowHeightChange(rightWindow.height, windows.rightWindowHeight, true)
                    rightWindowAnimation.start()
                    break
                }
            }
        }
    }

    // 左侧工具栏
    Window {
        id: leftWindow
        width: windowWidth
        x: windowHorizontalMargin
        visible: true
        color: "transparent"
        flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
        opacity: windowOpacity
        title: "易触控工具栏"

        WindowContent {
            id: leftContent
            window: leftWindow
            funsObject: funs
            model: toolModel

            onButtonTriggered: (idStr, checked, pointX, pointY) => {
                handleButtonTriggered(idStr, checked, pointX, pointY)
                // 处理窗口主图标按钮事件
                switch(idStr) {
                case "mainIconClick":
                    isFolded = !isFolded
                    windows.leftWindowHeight = isFolded ? windowFoldedHeight : windowHeight
                    handleWindowHeightChange(leftWindow.height, windows.leftWindowHeight, false)
                    leftWindowAnimation.start()
                    break
                }
            }
        }
    }
    // =============== 窗口（结束） ===============

    // 动画
    PropertyAnimation {
        id: rightWindowAnimation
        target: rightContent
        property: "height"
        duration: windowAnimationDuration
        to: rightWindowHeight
        onStarted: rightWindowOpacityAnimation.start()
    }
    PropertyAnimation {
        id: leftWindowAnimation
        target: leftContent
        property: "height"
        duration: windowAnimationDuration
        to: leftWindowHeight
        from: leftContent.height
        onStarted: leftWindowOpacityAnimation.start()
    }
    PropertyAnimation {
        id: rightWindowOpacityAnimation
        target: rightContent
        property: "backgroundOpacity"
        duration: windowAnimationDuration
        to: rightContent.isFolded ? 0 : 1
        easing.type: Easing.InOutQuad
    }
    PropertyAnimation {
        id: leftWindowOpacityAnimation
        target: leftContent
        property: "backgroundOpacity"
        duration: windowAnimationDuration
        to: leftContent.isFolded ? 0 : 1
        easing.type: Easing.InOutQuad
    }
    PropertyAnimation {
        id: leftWindowOpacity
        target: leftWindow
        property: "opacity"
        duration: 1500

        function rise(isFast = false) {
            if (leftWindow.opacity === windowOpacity) return
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowLowOpacity
            to = windowOpacity
            start()
        }
        function drop(isFast = false) {
            if (leftWindow.opacity !== windowOpacity) return
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

    // 窗口渐变动画定时器
    Timer {
        id: windowsOpacityTimer
        interval: windowOpacityChangeDuration
        onTriggered: {
            rightWindowOpacity.change()
            leftWindowOpacity.change()
            setTimeout(() => {
                rightWindowOpacity.drop()
                leftWindowOpacity.drop()
            }, 3000)
        }
    }

    // 工具函数
    Timer {id: timer}
    function setTimeout(cb, delayTime) {
       timer.interval = delayTime;
       timer.repeat = false;
       timer.triggered.connect(cb);
       timer.restart();
    }
    Timer {id: timer_2}
    function setTimeout_2(cb, delayTime) {
       timer_2.interval = delayTime;
       timer_2.repeat = false;
       timer_2.triggered.connect(cb);
       timer_2.restart();
    }
    function handleWindowHeightChange(from, to, isRightWindows) {
        if (to > from) {
            if (isRightWindows) {
                rightWindow.height = rightWindowHeight
            } else {
                leftWindow.height = leftWindowHeight
            }
        }
        setTimeout_2(() => {
            if (to < from) {
                if (isRightWindows) {
                    rightWindow.height = rightWindowHeight
                } else {
                    leftWindow.height = leftWindowHeight
                }
            }
        }, windowAnimationDuration)
    }
    property int usbBtnIndexBegin: 0
    function showUsbBtn() {
        usbBtnIndexBegin = toolModel.count
        toolModel.append({
            text: "弹出U盘",
            idStr: "ejectDrive",
            checked: false,
            checkable: false,
            link: false,
            exclusive: false,
            icon: "qrc:/icon/rmudisk.svg"
        })
        toolModel.append({
            text: "打开U盘",
            idStr: "openDrive",
            checked: false,
            checkable: false,
            link: false,
            exclusive: false,
            icon: "qrc:/icon/UDisk.svg"
        })
    }
    function hideUsbBtn() {
        toolModel.remove(usbBtnIndexBegin, 2)
    }
    function handleButtonTriggered(idStr, checked, pointX, pointY) {
        console.log("funBtnTriggered, idStr =", idStr, ", checked =", checked, ", pointX =", pointX, ", pointY =", pointY)
        // 提升窗口透明度
        windowsOpacityTimer.stop()
        rightWindowOpacity.rise(true)
        leftWindowOpacity.rise(true)
        windowsOpacityTimer.restart()
        // 处理按钮事件
        switch(idStr) {
        case "close":
            funs.closeTopWindow()
            break
        case "volume":
            volumeDialog.heartPointX = pointX
            volumeDialog.heartPointY = pointY
            volumeDialog.hideOrShow()
            break
        case "openDrive":
            funs.openDrive()
            break
        case "ejectDrive":
            if (funs.ejectDrive()) {
                notificationHp.showNotification("rmUsb", "U盘已安全拔出", "U盘已安全拔出")
                console.log("ejectDriveSuccess")
            } else {
                notificationHp.showNotification("rmUsb", "U盘弹出失败", "U盘弹出失败")
                console.error("ejectDriveError")
            }
            break
        }
    }
}
