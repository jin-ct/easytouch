import QtQuick
import QtQuick.Controls

// 功能按钮
Rectangle {
    id: btnFun
    width: parent.width
    height: 30
    color: "transparent"
    anchors.left: parent.left
    anchors.leftMargin: 1
    anchors.right: parent.right
    anchors.rightMargin: 1

    property string text: ""
    property string icon: ""
    property bool btnVisible: true

    signal clicked()

    state: "visible"
    states: [
        State { name: "visible";  PropertyChanges { target: btnFun; opacity: 1 } },
        State { name: "hidden";   PropertyChanges { target: btnFun; opacity: 0 } }
    ]
    transitions: Transition {
        from: "visible"
        to: "hidden"
        reversible: true

        SequentialAnimation {
            NumberAnimation {
                target: btnFun
                property: "opacity"
                duration: 50
                easing.type: Easing.InOutQuad
            }
        }
    }
    onBtnVisibleChanged: {
        if (btnVisible) {
            btnFun.visible = true
            btnFun.state = "visible"
        } else {
            btnFun.state = "hidden"
        }
    }

    Item {
        height: btnFun.width * 0.40 + 10
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: iconFun
            source: btnFun.icon
            width: btnFun.width * 0.40
            height: btnFun.width * 0.40
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            height: 10
            text: btnFun.text
            font.pixelSize: 7
            color: Qt.rgba(1, 1, 1, 1)
            anchors.top: iconFun.bottom
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: btnFun.clicked()
        onPressed: btnFun.color = "#409EFF"
        onReleased: btnFun.color = "transparent"
    }
}
