import QtQuick
import QtQuick.Controls
import "."

SettingsCard {
    id: root

    // 对外暴露 ComboBox 的常用属性
    property alias model: comboBox.model
    property alias currentIndex: comboBox.currentIndex
    property alias currentText: comboBox.currentText
    property alias comboBox: comboBox

    ComboBox {
        id: comboBox
        width: 160
        height: 45
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        font.pixelSize: 12

        background: Rectangle {
            radius: 4
            color: "#ffffff"
            border.color: "#dcdfe6"
            border.width: 1
        }

        contentItem: Text {
            text: comboBox.displayText
            color: "#303133"
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
            rightPadding: 8
            elide: Text.ElideRight
        }

        popup: Popup {
            y: comboBox.height
            width: comboBox.width
            padding: 4

            background: Rectangle {
                color: "#ffffff"
                radius: 4
                border.color: "#dcdfe6"
                border.width: 1
            }

            contentItem: ListView {
                implicitHeight: contentHeight
                model: comboBox.delegateModel
                currentIndex: comboBox.highlightedIndex
                clip: true
                spacing: 2

                delegate: ItemDelegate {
                    width: ListView.view.width
                    height: 28
                    contentItem: Text {
                        text: modelData
                        color: "#303133"
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                        rightPadding: 8
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        color: hovered ? "#f5f7fa" : "transparent"
                        radius: 4
                    }
                }
            }
        }
    }
}


