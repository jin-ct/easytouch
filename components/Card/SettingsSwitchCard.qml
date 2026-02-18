import QtQuick
import QtQuick.Controls
import "."

SettingsCard {
    id: root

    // 对外暴露 Switch 的常用属性
    property alias checked: toggle.checked
    property alias switchControl: toggle

    Switch {
        id: toggle
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        implicitWidth: 40
        implicitHeight: 20

        indicator: Rectangle {
            implicitWidth: 40
            implicitHeight: 20
            radius: height / 2
            color: toggle.checked ? "#409EFF" : "#dcdfe6"

            Rectangle {
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                y: 2
                x: toggle.checked ? parent.width - width - 2 : 2
                color: "#ffffff"
                Behavior on x {
                    NumberAnimation { duration: 100 }
                }
            }
        }

        contentItem: Item {}
    }
}



