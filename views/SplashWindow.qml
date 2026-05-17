import QtQuick
import QtQuick.Controls
import Functions 1.0

Window {
    id: win
    visible: true
    height: Screen.height
    width: Screen.width
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput

    property string exeName: ""
    property var exeIcon: null
    property point cursorPos: Qt.point(Screen.width/2, Screen.height/2)

    Connections {
        enabled: Global.launchingHelper
        target: Global.launchingHelper

        function onWindowShownWithInfo(windowTile, exeName, exeIcon, cursorPos) {
            if (exeName === win.exeName)
            win.destroy()
        }
    }

    Rectangle {
        width: 480
        height: 320
        radius: 10
        opacity: 0.96
        anchors.centerIn: parent

        Text {
            text: "易触控提醒: " + exeName + " 正在启动"
            font.pixelSize: 14
            color: "#6E6E6E"
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            id: loading
            width: 320
            height: 8
            radius: height / 2

            anchors.centerIn: parent

            color: "#CDDEEB"
            clip: true

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

        // Image {
        //     source: exeIcon
        //     anchors.centerIn: parent
        // }
    }
}
