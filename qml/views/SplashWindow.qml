import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Functions 1.0

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

            Rectangle {
                id: loading
                width: 320
                height: 8
                radius: height / 2
                color: "#CDDEEB"
                clip: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: loading.width
                        height: loading.height
                        radius: loading.radius
                    }
                }

                // 背景微光
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "#B9C7E3"
                    opacity: 0.8
                }

                // 流动条
                Rectangle {
                    id: bar

                    width: parent.width * 0.35
                    height: parent.height
                    radius: parent.radius

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#0080FF00" }
                        GradientStop { position: 0.2; color: "#3EA6FF" }
                        GradientStop { position: 0.5; color: "#7CC7FF" }
                        GradientStop { position: 0.8; color: "#3EA6FF" }
                        GradientStop { position: 1.0; color: "#0080FF00" }
                    }

                    layer.enabled: true

                    // 发光
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#5EA9EB"
                        opacity: 0.25
                        scale: 1.8
                        z: -1
                    }

                    NumberAnimation on x {
                        from: -bar.width
                        to: loading.width

                        duration: 800
                        loops: Animation.Infinite

                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Text {
                text: "该软件启动较慢，请耐心等待"
                visible:  win.duration > 6000  // 大于 6s 认为启动较慢 (若未记录启动时间则 duration <= 0, 不影响判断)
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#FF7F27"
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
