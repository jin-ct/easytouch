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
    property int funBtnHeight: 30
    property bool isFolded: false
    property int windowWidth: 36
    property int windowBaseHeight: 70
    property int rightWindowHeight: windowBaseHeight + (funBtnHeight*funBtnCount)
    property int leftWindowHeight: windowBaseHeight + (funBtnHeight*funBtnCount)

    Functions {
        id: funs

        onUsbInserted: {
            rightContent.isFunOpenUDiskEnable = true;
            rightContent.isFunRmUDiskEnable = true;
            leftContent.isFunOpenUDiskEnable = true;
            leftContent.isFunRmUDiskEnable = true;
        }
        onUsbRemoved: {
            rightContent.isFunOpenUDiskEnable = false;
            rightContent.isFunRmUDiskEnable = false;
            leftContent.isFunOpenUDiskEnable = false;
            leftContent.isFunRmUDiskEnable = false;
        }
    }

    Component.onCompleted: {
        funs.setWindowNoActivate(windows)
        funs.setWindowNoActivate(rightWindow)
        funs.setWindowNoActivate(leftWindow)
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
        }, 60)
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
        }
    }
    PropertyAnimation {
        id: rightWindowAnimation
        target: rightContent
        property: "height"
        duration: 60
        to: windows.rightWindowHeight
        easing.type: Easing.OutInQuad
    }
    PropertyAnimation {
        id: leftWindowAnimation
        target: leftContent
        property: "height"
        duration: 60
        to: windows.leftWindowHeight
        easing.type: Easing.OutInQuad
    }
}
