import QtQuick 2.15
import QtQuick.Controls 2.15
import Functions 1.0

Window {
    id: whileboardWin
    width: Screen.width / 2
    height: Screen.height
    visible: false
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    /* ===== 画笔与橡皮参数 ===== */
    property color penColor: "red"
    property real penWidth: 1.5
    property bool eraserMode: false
    property real eraserRadius: 18

    Item {
        id: root
        anchors.fill: parent
        clip: true

        WhiteboardItem {
            id: wb
            anchors.fill: parent
            penColor: whileboardWin.penColor
            penWidth: whileboardWin.penWidth
            eraserMode: whileboardWin.eraserMode
            eraserRadius: whileboardWin.eraserRadius
        }

        /* ===== 右下角控制按钮 ===== */
    Column {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        spacing: 8

        Button {
                text: whileboardWin.eraserMode ? "切换为画笔" : "切换为橡皮"
                onClicked: whileboardWin.eraserMode = !whileboardWin.eraserMode
        }

        Button {
            text: "清空"
                onClicked: wb.clear()
        }

        Button {
            text: "导出 PNG"
                onClicked: wb.exportPng("doodle.png")
        }
    }
    }
}
