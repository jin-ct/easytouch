import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import "./"

DialogWindow {
    id: eraserDialog
    dialogWidth: contentRow.childrenRect.width + 12  // "+12" 表示左右边距和
    dialogHeight: 36
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
            eraserDialog.hideOrShow()
        }
    }
}
