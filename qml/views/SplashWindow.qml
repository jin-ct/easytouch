import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Functions 1.0
import FluentUI

Window {
    id: win
    visible: true
    height: Screen.height
    width: Screen.width
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput

    property string exeName: ""
    property string exeIconId: ""
    property int duration: 0
    property int manualDuration: 0
    property point cursorPos: Qt.point(0, 0)
    property point cursorPosDefault: Qt.point(Screen.width/2, Screen.height*3/4)

    Connections {
        enabled: Global.launchingHelper
        target: Global.launchingHelper

        function onWindowShownWithInfo(windowTile, exeName, exeIcon, cursorPos) {
            if (exeName === win.exeName) {
                floatingTips.opacity = 0;
                main.opacity = 0;
            }
        }
    }

    Component.onCompleted: {
        // 若未检测到鼠标事件则将弹出点调至默认点
        if (!Global.mouseHook.getHasMouseEvent()) {
            main.x = (cursorPosDefault.x - main.width/2)
            main.y = (cursorPosDefault.x - main.width/2)
        }
        mainAnimationScale.start()
        mainAnimationX.start()
        mainAnimationY.start()
    }

    Rectangle {
        id: main
        width: 480
        height: 320
        radius: 10
        opacity: 0.96
        scale: 0.0
        x: (cursorPos.x - main.width/2)
        y: (cursorPos.y - main.height/2)

        Window {
            id: floatingTips
            visible: false
            height: floatingTipsRow.height
            width: floatingTipsRow.width
            color: "transparent"
            flags: Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool
            x: win.width / 2 - floatingTips.width / 2
            y: main.y + main.height - (floatingTips.height + 12)

            Row {
                id: floatingTipsRow
                anchors.centerIn: parent
                spacing: 10

                Text {
                    id: tipText
                    text: "易触控检测到 " + exeName + " 正在启动"
                    font.pixelSize: 11
                    color: "#6E6E6E"
                }

                Text {
                    text: "忽略此进程"
                    color: disableBtn.pressed ? "#337ecc" : "#409EFF"
                    font.pixelSize: 11
                    MouseArea {
                        id: disableBtn
                        anchors.fill: parent
                        onClicked: {
                            Global.launchingHelper.disableHelperForItem(win.exeName)
                            floatingTips.opacity = 0;
                            main.opacity = 0;
                        }
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 12

            Image {
                cache: false
                source: "image://MImage/" + exeIconId
                anchors.horizontalCenter: parent.horizontalCenter
                mipmap:true
                width: 60
                height: 60
            }

            Rectangle {   // 空白占位
                height: 1
                width: 1
            }

            Text {
                text: "正在启动"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#363636"
            }

            FluProgressBar {
                width: 320
                duration: 880
                indeterminate: true
            }

            Text {
                text: "该软件启动较慢，请耐心等待"
                // 大于 6s 认为启动较慢 (若未记录启动时间则 duration <= 0, 不影响判断)
                visible:  win.manualDuration === 0 ? win.duration > 6000 : win.manualDuration > 6000
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#FF7F27"
            }
        }

        Timer {
            id: autoDestroyedTimer
            interval: win.manualDuration
            onTriggered: {
                floatingTips.opacity = 0;
                main.opacity = 0;
            }
            Component.onCompleted: {
                if (win.manualDuration !== 0)
                    autoDestroyedTimer.start()
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                onFinished: {
                    if (opacity === 0)
                        win.destroyed()
                }
            }
        }

        PropertyAnimation {
            id: mainAnimationScale
            target: main
            property: "scale"
            from: 0.0
            to: 1.0
            duration: 260
            easing.type: Easing.InOutQuad
            onFinished: {
                floatingTips.visible = true
            }
        }
        PropertyAnimation {
            id: mainAnimationX
            target: main
            property: "x"
            to: (Screen.width - main.width)/2
            duration: 260
            easing.type: Easing.InOutQuad
        }
        PropertyAnimation {
            id: mainAnimationY
            target: main
            property: "y"
            to: (Screen.height - main.height)/2
            duration: 260
            easing.type: Easing.InOutQuad
        }
    }
}
