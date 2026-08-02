import QtQuick
import QtQuick.Controls
import QtCore
import Functions 1.0
import "../"

Window {
    id: dialog
    visible: true
    opacity: 1
    height: 200
    width: 320
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    property string title: ""
    property string message: ""

    signal okBtnClicked()
    signal cancelBtnClicked()

    Component.onCompleted: {
        dialog.height = content.childrenRect.height + titleBar.height + 24
    }

    Rectangle {
        id: root

        color: "#ffffff"
        border.color: "#dcdfe6"
        border.width: 1
        radius: 10

        anchors.fill: parent


        WindowTitleBar {
            id: titleBar
            title: dialog.title
            window: dialog
        }

        Column {
            id: content
            spacing: 6
            width: parent.width
            anchors.margins: 16
            anchors.top: titleBar.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Text {
                id: text
                text: message
                anchors.left: parent.left
                anchors.right: parent.right
                font.pixelSize: 14
                color: "#303133"
            }

            Item {
                anchors.right: parent.right
                height: 40
                width: 86

                Button {
                    id: cancelButton
                    padding: 6
                    width: 80
                    height: 40
                    anchors.right: actionButton.left
                    anchors.rightMargin: 6
                    text: "取消"

                    background: Rectangle {
                        radius: 4
                        border.color: "#666666"
                        border.width: 1
                        color: cancelButton.down ? "#f5f5f5" : "#ffffff"
                    }

                    contentItem: Text {
                        text: cancelButton.text
                        color: "#303133"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        dialog.cancelBtnClicked()
                        dialog.close()
                    }
                }
                Button {
                    id: actionButton
                    padding: 6
                    width: 80
                    height: 40
                    anchors.right: parent.right
                    text: "确定"

                    background: Rectangle {
                        radius: 4
                        color: actionButton.down ? "#337ecc" : "#409EFF"
                    }

                    contentItem: Text {
                        text: actionButton.text
                        color: "#ffffff"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        dialog.okBtnClicked()
                        dialog.close()
                    }
                }
            }
        }
    }
}
