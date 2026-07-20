import QtQuick 2.15
import QtQuick.Controls 2.15
import Functions 1.0

Window {
    id: whileboardWin
    width: Screen.width
    height: Screen.height
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    /* ===== 画笔与橡皮参数 ===== */
    property color penColor: "red"
    property real penWidth: 1.5
    property bool eraserMode: false
    property real eraserRadius: 18

    function clear() {
        wb.clear()
    }
    function exportPng(path) {
        wb.exportPng(path)
    }
    function switchToEraser() {
        eraserMode = true
    }
    function switchToPen() {
        eraserMode = false
    }

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
    }
}
