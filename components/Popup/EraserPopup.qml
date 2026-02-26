import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import "./"

PopupWindow {
    id: eraserPopup
    popupWidth: contentRow.childrenRect.width + 12  // "+12" 表示左右边距和
    popupHeight: 36
    visible: false

    signal clear()

    Row {
        id: contentRow
        anchors {
            centerIn: parent
            left: parent.left; leftMargin: 10
            right: parent.right; rightMargin: 10
        }

        Text {
            text: "点击清空"
            color: "#666666"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            clear()
            eraserPopup.hideOrShow()
        }
    }
}
