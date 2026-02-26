import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import "./"

PopupWindow {
    id: penPopup
    popupWidth: contentRow.childrenRect.width + 24
    popupHeight: 80
    visible: false

    // 当前选中的笔属性，供外部绑定或读取
    property int selectedColorIndex: 0
    property int selectedWidthIndex: 1
    property color selectedColor: penPopup.penColors[penPopup.selectedColorIndex]
    property real selectedWidth: penPopup.penWidths[penPopup.selectedWidthIndex]

    // 六种常用颜色
    readonly property var penColors: [
        "red",      // 红
        "#3498DB",  // 蓝
        "#2ECC71",  // 绿
        "#F39C12",  // 橙
        "#9B59B6",  // 紫
        "#2C3E50"   // 深灰/黑
    ]

    // 三种画笔粗细（逻辑像素）
    readonly property var penWidths: [1, 1.5, 2]

    function reset() {
        selectedColorIndex = 0;
        selectedWidthIndex = 1;
    }

    Row {
        id: contentRow
        spacing: 12
        anchors {
            centerIn: parent
            left: parent.left
            leftMargin: 12
            right: parent.right
            rightMargin: 12
        }

        Grid {
            columns: 3
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: penPopup.penColors
                delegate: Item {
                    width: 26
                    height: 26
                    readonly property bool isSelected: penPopup.selectedColorIndex === index
                    Rectangle {
                        width: 22
                        height: 22
                        anchors.centerIn: parent
                        radius: 11
                        color: modelData
                        border.width: parent.isSelected ? 2 : 0
                        border.color: "#2C3E50"
                        opacity: parent.isSelected ? 1 : 0.85
                        Behavior on opacity { NumberAnimation { duration: 80 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            penPopup.selectedColorIndex = index
                        }
                    }
                }
            }
        }

        // 分隔线
        Rectangle {
            width: 1
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            color: "#70909399"
        }

        // 粗细选择区
        Column {
            spacing: 1
            Repeater {
                model: penPopup.penWidths
                delegate: Item {
                    width: 22
                    height: 20
                    readonly property bool isSelected: penPopup.selectedWidthIndex === index
                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: 4
                        color: parent.isSelected ? "#E8F4FD" : "transparent"
                        border.width: parent.isSelected ? 1 : 0
                        border.color: "#3498DB"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: (index === 0 ? 4 : index === 1 ? 8 : 11)
                        height: (index === 0 ? 4 : index === 1 ? 8 : 11)
                        radius: (index === 0 ? 4 : index === 1 ? 8 : 11) / 2
                        color: parent.isSelected ? "#3498DB" : "#95A5A6"
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            penPopup.selectedWidthIndex = index
                        }
                    }
                }
            }
        }
    }
}
