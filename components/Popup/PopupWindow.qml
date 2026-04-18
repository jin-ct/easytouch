import QtQuick
import QtQuick.Controls
import Functions 1.0

Window {
    id: popup
    color: "transparent"
    flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
    opacity: 0
    title: "易触控工具栏"
    width: popup.popupWidth
    height: popup.popupHeight
    x: heartPointX < (Screen.desktopAvailableWidth/2) ? (heartPointX + 27) : (heartPointX - width - 27)
    y: heartPointY - height/2

    property int heartPointX: 0
    property int heartPointY: 0
    property int popupWidth: 0
    property int popupHeight: 0

    property bool isHideByHook: false

    signal windowHide()

    Component.onCompleted: {
        Global.funs.setWindowNoActivate(popup)
    }

    Connections {
        target: Global.funs
        function onMousePressed(pos) {
            if (popup.visible) {
                isHideByHook = true;
                popup.hideOrShow()
            }
        }
    }

    Timer {id: timer}
    function setTimeout(cb, delayTime) {
       timer.interval = delayTime;
       timer.repeat = false;
       timer.triggered.connect(cb);
       timer.start();
    }
    function delayColse(delayTime) {
        setTimeout(() => {
            hideOrShow()
        }, delayTime)
    }
    function hideOrShow(pointX = 0, pointY = 0) {
        if (pointX)
            heartPointX = pointX
        if (pointY)
            heartPointY = pointY
        if (!popup.visible) {
            popup.visible = true
            Global.funs.addMouseHookIgnoreAreas(Qt.rect(popup.x, popup.y, popup.width, popup.height), "Popup")
            Global.funs.installHook()
        } else {
            Global.funs.uninstallHook()
        }

        windowAnimation.start()
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: 6
        color: "#FFFFFF"
        border.color: "#cfcfcf"
        border.width: 1
    }


    PropertyAnimation {
        id: windowAnimation
        target: popup
        property: "opacity"
        duration: 90
        to: popup.opacity === 0 ? 1 : 0
        easing.type: Easing.OutInQuad

        onStopped: {
            if (popup.opacity === 0) {
                popup.visible = false
                if (!isHideByHook) {
                    windowHide()
                } else {
                    setTimeout(() => {   // 延时销毁对象防止重复触发
                        isHideByHook = false
                        windowHide()
                    }, 50)
                }
            }
        }
    }

}
