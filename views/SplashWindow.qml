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
    property point cursorPos: Qt.point(Screen.width/2, Screen.height/2)

    Connections {
        enabled: Global.launchingHelper
        target: Global.launchingHelper

        function onWindowShownWithInfo(windowTile, exeName, exeIcon, cursorPos) {
            if (exeName === win.exeName) {
                main.opacity = 0;
            }
        }
    }

    Rectangle {
        id: main
        width: 480
        height: 320
        radius: 10
        opacity: 0.96
        anchors.centerIn: parent

        Text {
            text: "易触控提醒: " + exeName + " 正在启动"
            font.pixelSize: 11
            color: "#6E6E6E"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Column {
            anchors.centerIn: parent
            spacing: 36

            Image {
                cache: false
                source: "image://MImage/" + exeIconId
                anchors.horizontalCenter: parent.horizontalCenter
                mipmap:true
                width: 60
                height: 60
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

    }
}
