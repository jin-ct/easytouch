import QtQuick
import QtQuick.Controls

Rectangle {
    id: titleBar
    anchors.left: parent.left
    anchors.right: parent.right
    height: 36
    color: "#00000000"

    property alias title: titleLabel.text
    property var window

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: false
        property point pressPos: Qt.point(0, 0)

        onPressed: function(mouse) {
            var cb = closeButton
            var x1 = cb.x
            var x2 = cb.x + cb.width
            var y1 = cb.y
            var y2 = cb.y + cb.height
            if (mouse.x >= x1 && mouse.x <= x2 && mouse.y >= y1 && mouse.y <= y2) {
                mouse.accepted = false
                return
            }
            pressPos = Qt.point(mouse.x, mouse.y)
        }

        onPositionChanged: function(mouse) {
            if (!(mouse.buttons & Qt.LeftButton))
                return
            if (!window)
                return
            window.x += mouse.x - pressPos.x
            window.y += mouse.y - pressPos.y
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 8

        Label {
            id: titleLabel
            text: "标题"
            color: "#303133"
            font.pixelSize: 13
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        ToolButton {
            id: closeButton
            width: 24
            height: 24
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            background: Rectangle {
                anchors.fill: parent
                radius: 4
                color: closeButton.pressed ? "#e4e7ed" : (closeButton.hovered ? "#ECEFF5" : "transparent")
            }

            contentItem: Image {
                anchors.centerIn: parent
                source: "qrc:/icon/close_2.svg"
                width: 24
                height: 24
                fillMode: Image.PreserveAspectFit
            }

            onClicked: window.close()
            Accessible.name: qsTr("关闭设置")
        }
    }
}
