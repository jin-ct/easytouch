import QtQuick
import QtQuick.Controls

Window {
    id: dialog
    visible: true
    color: "transparent"
    flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
    opacity: 1
    title: "易触控工具栏"
    width: Screen.desktopAvailableWidth
    height: Screen.desktopAvailableHeight

    property var funsObject
    property int heartPointX: 0
    property int heartPointY: 0
    property int dialogWidth: 0
    property int dialogHeight: 0

    default property alias content: background.data

    Component.onCompleted: {
        funsObject.setWindowNoActivate(dialog)
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
            dialog.visible = false
        }, delayTime)
    }

    MouseArea {
        anchors.fill: parent
        onClicked: (e) => {
            if (e.x < background.x || e.x > background.x + dialog.dialogWidth ||
                e.y < background.y || e.y > background.y + dialog.dialogHeight)
            {
                dialog.visible = false
            }
        }
    }

    Rectangle {
        id: background
        width: dialog.dialogWidth
        height: dialog.dialogHeight
        x: heartPointX < (Screen.desktopAvailableWidth/2) ? (heartPointX + 22) : (heartPointX - width - 22)
        y: heartPointY - height/2
        radius: 6
        color: '#62000000'
        border.color: "#40FAFCFF"
        border.width: 1
    }

}
