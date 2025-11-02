import QtQuick
import QtQuick.Controls


// 收起按钮
Rectangle {
    id: btnFold
    width: parent.width
    height: 30
    color: "transparent"
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 2

    property bool isFold: false

    signal fold()

    Item {
        anchors.fill: parent

        Image {
            id: iconFold
            source: "qrc:/icon/arrow.png"
            rotation: isFold ? 0 : 180
            width: btnFold.width * 0.35
            height: btnFold.width * 0.35
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: isFold ? "展开" : "收起"
            font.pixelSize: 7
            color: Qt.rgba(1, 1, 1, 1)
            anchors.top: iconFold.bottom
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: fold()
    }
}
