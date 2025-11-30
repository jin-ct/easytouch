import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// 收起按钮
Rectangle {
    id: btnFold
    width: parent.width
    height: 36
    color: "transparent"
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 2

    property bool isFold: false

    signal fold()

    Item {
        anchors.fill: parent

        Image {
            id: iconFold
            source: "qrc:/icon/chevron.svg"
            rotation: isFold ? 0 : 180
            width: btnFold.width * 0.42
            height: btnFold.width * 0.42
            anchors.horizontalCenter: parent.horizontalCenter
        }

        MultiEffect {
            anchors.fill: iconFold
            source: iconFold
            colorization: 1.0
            colorizationColor: "#303133"
            rotation: iconFold.rotation
        }

        Text {
            text: isFold ? "展开" : "收起"
            font.pixelSize: 8
            color: "#303133"
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
