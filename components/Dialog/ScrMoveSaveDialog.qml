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

    // 保存数据
    property rect sourceRect
    property rect mirrorRect

    signal saved(var newData)

    function setRect(sourceRect, mirrorRect) {
        dialog.sourceRect = sourceRect
        dialog.mirrorRect = mirrorRect
    }

    function save() {
        if (!input.text)
            return
        saved([{
            name: input.text,
            sourceRect: {x: sourceRect.x, y: sourceRect.y, width: sourceRect.width, height: sourceRect.height},
            mirrorRect: {x: mirrorRect.x, y: mirrorRect.y, width: mirrorRect.width, height: mirrorRect.height}
        }])
    }
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
            title: "保存记录"
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

            TextField {
                id: input
                anchors.left: parent.left
                anchors.right: parent.right
                font.pixelSize: 12
                placeholderText: "请输入名称"

                background: Rectangle {
                    radius: 4
                    color: "#ffffff"
                    border.color: "#dcdfe6"
                    border.width: 1
                }

                color: "#303133"
                selectByMouse: true
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
                    dialog.save()
                    dialog.close()
                }
            }
        }
    }
}
