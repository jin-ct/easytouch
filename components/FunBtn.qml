import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// 功能按钮
Rectangle {
    id: btnFun
    width: parent.width
    height: 36
    color: "transparent"
    anchors.left: parent.left
    anchors.leftMargin: 1
    anchors.right: parent.right
    anchors.rightMargin: 1

    property string text: ""
    property string icon: ""
    property bool btnVisible: true
    property string iconColor: "#303133"
    property string iconColorClicked: "#FFFFFF"
    property string curIconColor: "#303133"

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
        height: btnFun.width * 0.42 + 13
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter

        Image {
            id: iconFun
            source: btnFun.icon
            width: btnFun.width * 0.42
            height: btnFun.width * 0.42
            anchors.horizontalCenter: parent.horizontalCenter
        }

        MultiEffect {
            anchors.fill: iconFun
            source: iconFun
            colorization: 1.0
            colorizationColor: curIconColor
        }

        Text {
            height: 10
            text: btnFun.text
            font.pixelSize: 8
            color: curIconColor
            anchors.top: iconFun.bottom
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        onClicked: btnFun.clicked()
        onPressed: {
            curIconColor = iconColorClicked
            btnFun.color = "#409EFF"
        }
        onReleased: {
            curIconColor = iconColor
            btnFun.color = "transparent"
        }
    }
}
