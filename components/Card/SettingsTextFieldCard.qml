import QtQuick
import QtQuick.Controls
import "."

SettingsCard {
    id: root

    // 对外暴露 TextField 的常用属性
    property alias text: input.text
    property alias placeholderText: input.placeholderText
    property alias textField: input

    TextField {
        id: input
        width: 180
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        font.pixelSize: 12

        background: Rectangle {
            radius: 4
            color: "#ffffff"
            border.color: "#dcdfe6"
            border.width: 1
        }

        color: "#303133"
        selectByMouse: true
    }
}



