import QtQuick
import QtQuick.Controls
import Functions 1.0

Window {
    id: dialog
    color: "transparent"
    flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
    opacity: 0
    title: "易触控工具栏"
    width: dialog.dialogWidth
    height: dialog.dialogHeight
    x: heartPointX < (Screen.desktopAvailableWidth/2) ? (heartPointX + 27) : (heartPointX - width - 27)
    y: heartPointY - height/2

    required property Functions funs

    property int heartPointX: 0
    property int heartPointY: 0
    property int dialogWidth: 0
    property int dialogHeight: 0

    Component.onCompleted: {
        funs.setWindowNoActivate(dialog)
    }

    Connections {
        target: funs
        function onMousePressed(pos) {
            if (dialog.visible && !funs.isRectContains(Qt.rect(dialog.x, dialog.y, dialog.width, dialog.height), pos))
                dialog.hideOrShow()
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
        if (!dialog.visible)
            dialog.visible = true
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
        target: dialog
        property: "opacity"
        duration: 90
        to: dialog.opacity === 0 ? 1 : 0
        easing.type: Easing.OutInQuad

        onStopped: {
            if (dialog.opacity === 0)
                dialog.visible = false
        }
    }

}
