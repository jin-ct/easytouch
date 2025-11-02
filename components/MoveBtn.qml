import QtQuick
import QtQuick.Controls

// 移动区域
Rectangle {
    id: btnMove
    width: parent.width
    height: 32
    color: "transparent"

    property var window

    Item {
        height: btnMove.width * 0.40 + 10
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: iconMove
            source: "qrc:/icon/move.png"
            width: btnMove.width * 0.40
            height: btnMove.width * 0.40
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            height: 10
            text: "按住移动"
            font.pixelSize: 7
            color: Qt.rgba(1, 1, 1, 1)
            anchors.top: iconMove.bottom
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        property point lastMousePos: Qt.point(0, 0)
        onPressed: lastMousePos = Qt.point(mouseX, mouseY)
        onPositionChanged: {
            if (pressed) {
                var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
                window.x += delta.x
                window.y += delta.y
            }
        }
    }
}
