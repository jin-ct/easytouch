import QtQuick
import QtQuick.Controls
import "."

SettingsCard {
    id: root

    // 对外暴露 Slider 的常用属性
    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to
    property alias stepSize: slider.stepSize
    property alias slider: slider

    Row {
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        Slider {
            id: slider
            width: 160

            from: 0
            to: 100

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 4
                radius: 2
                color: "#e4e7ed"

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: "#409EFF"
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 14
                height: 14
                radius: 7
                color: "#ffffff"
                border.color: "#409EFF"
                border.width: 2
            }
        }

        Label {
            text: Math.round(slider.value).toString()
            color: "#606266"
            font.pixelSize: 12
        }
    }
}


