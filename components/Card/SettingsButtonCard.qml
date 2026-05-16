import QtQuick
import QtQuick.Controls
import "."

SettingsCard {
    id: root

    // 对外暴露 Button 的常用属性
    property alias text: actionButton.text
    property alias button: actionButton

    Button {
        id: actionButton
        padding: 6
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        background: Rectangle {
            radius: 4
            color: actionButton.enabled ? (actionButton.down ? "#337ecc" : "#409EFF") : "#7A7A7A"
        }

        contentItem: Text {
            text: actionButton.text
            color: "#ffffff"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}



