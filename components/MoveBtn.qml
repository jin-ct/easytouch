import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// 移动区域
Rectangle {
    id: btnMove
    width: parent.width
    height: 36
    color: "transparent"

    property var window

    Item {
        height: btnMove.width * 0.42 + 12
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: iconMove
            source: "qrc:/icon/move.svg"
            width: btnMove.width * 0.42
            height: btnMove.width * 0.42
            anchors.horizontalCenter: parent.horizontalCenter
        }

        MultiEffect {
            anchors.fill: iconMove
            source: iconMove
            colorization: 1.0
            colorizationColor: "#303133"
        }

        Text {
            height: 10
            text: "按住移动"
            font.pixelSize: 8
            color: "#303133"
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
