import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Functions 1.0
import "./Popup"

Item {
    id: root
    width: 48
    height: parent.height
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top

    required property Window window
    required property Functions funs

    property alias model: listView.model
    property bool isFolded: true
    property double backgroundOpacity: 1
    property int windowAnimationDuration: 160

    property bool isLongPressing: false
    property bool isLongPressed: false
    property int longPressingBtnIndex: 0
    property var longPressingBtnPoint: ({x: 0, y: 0})

    signal buttonTriggered(string idStr, bool checked, bool perState, int pointX, int pointY)
    signal drag()

    // 背景
    Rectangle {
        opacity: backgroundOpacity
        anchors.fill: parent
        anchors.topMargin: 18
        radius: 8
        color: "#f2f2f2"
        border.color: "#cfcfcf"
    }

    // 主图标
    Rectangle {
        id: dragHandle
        width: 52
        height: 52
        radius: width / 2
        color: "#eaeaea"
        border.color: "#c8c8c8"
        z: 99

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        Image {
            source: "qrc:/icon/icon.svg"
            width: 36; height: 36
            mipmap:true
            anchors.centerIn: parent
        }

        MouseArea {
            anchors.fill: parent
            property point lastMousePos: Qt.point(0, 0)
            property bool isMoved: false
            onPressed: lastMousePos = Qt.point(mouseX, mouseY)
            onPositionChanged: {
                if (pressed) {
                    var delta = Qt.point(mouseX - lastMousePos.x, mouseY - lastMousePos.y)
                    if (Math.abs(delta.x) < 2 && Math.abs(delta.y) < 2)
                        return
                    root.window.x += delta.x
                    root.window.y += delta.y
                    isMoved = true;
                }
            }
            onClicked: {
                if (isMoved) {
                    isMoved = false
                    return
                }
                buttonTriggered("mainIconClick", false, false, parent.mapToGlobal(0, 0).x + parent.width/2, parent.mapToGlobal(0, 0).y + parent.height/2)
            }

        }
    }

    // 按钮列表
    ListView {
        id: listView
        opacity: backgroundOpacity

        anchors {
            top: parent.top; topMargin: 18
            left: parent.left
            right: parent.right
            bottom: parent.bottom; bottomMargin: 6
        }

        clip: true
        spacing: 2
        model: model
        interactive: true

        header: Rectangle { height: 36 }
        delegate: Rectangle {
            id: btn
            width: 42
            height: 38
            radius: 6
            x: (listView.width - width) / 2

            color: (model.checked && model.checkable) ? "#4f8cff" : "#ffffff"
            border.color: (model.checked && model.checkable) ? "#2f6fe0" : "#cfcfcf"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 3

                Image {
                    width: 16; height: 16;
                    source: model.icon
                    mipmap:true
                    anchors.horizontalCenter: parent.horizontalCenter

                    MultiEffect {
                        visible: model.checkable
                        anchors.fill: parent
                        source: parent
                        colorization: 1.0
                        colorizationColor: (model.checked && model.checkable) ? "#ffffff" : "#525252"
                    }
                }

                Text {
                    text: model.text
                    font.pixelSize: 8
                    wrapMode: Text.NoWrap
                    color: (model.checked && model.checkable) ? "#ffffff" : "#2f2f2f"
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressedChanged: {
                    btn.scale = pressed ? 0.94 : 1.0
                    if (pressed) {
                        isLongPressing = true
                        longPressingBtnIndex = index
                        longPressingBtnPoint =
                                {x: parent.mapToGlobal(0, 0).x + parent.width/2, y: parent.mapToGlobal(0, 0).y + parent.height/2}
                        longPressTimer.start()
                    } else {
                        isLongPressing = false
                    }
                }
                onClicked: {
                    if (isLongPressed) {
                        isLongPressed = false;
                        return
                    }
                    root.handleButtonTap(index, parent.mapToGlobal(0, 0).x + parent.width/2, parent.mapToGlobal(0, 0).y + parent.height/2)
                }
            }

            Behavior on scale {
                NumberAnimation { duration: 88 }
            }
        }
        footer: Rectangle { height: 16 }
        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: 160
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0
                to: 1
                duration: 160
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: 160
                }
                NumberAnimation {
                    property: "scale"
                    from: 1
                    to: 0.6
                    duration: 160
                }
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: 160
                easing.type: Easing.OutCubic
            }
        }
        onDragStarted: drag()
    }

    function handleButtonTap(index, pointX, pointY) {
        let item = model.get(index)
        let perState = item.checked
        let newState
        if (item.cancelable) {
            newState = !item.checked
        } else  {
            newState = true
        }

        // 联动
        if (item.link) {
            model.setProperty(index, "checked", newState)
        } else {
            item.checked = newState
        }

        // 互斥
        if (newState && item.exclusive) {
            for (let i = 0; i < model.count; ++i) {
                if (i !== index && model.get(i).exclusive) {
                    model.setProperty(i, "checked", false)
                }
            }
        }

        buttonTriggered(item.idStr, newState, perState, pointX, pointY)
    }

    function longPressed() {
        let item = model.get(longPressingBtnIndex)
        let pointX = longPressingBtnPoint.x
        let pointY = longPressingBtnPoint.y
        buttonTriggered(item.idStr + "LongPressed", false, false, pointX, pointY)
    }

    Rectangle {
        opacity: backgroundOpacity
        height: 30
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        radius: 8

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.8; color: "#f2f2f2" }
            GradientStop { position: 1.0; color: "#f2f2f2" }
        }
    }

    Behavior on height {
        NumberAnimation { duration: windowAnimationDuration }
    }
    Behavior on backgroundOpacity {
        NumberAnimation { duration: windowAnimationDuration }
    }

    Timer {
        id: longPressTimer
        interval: 500
        repeat: false

        onTriggered: {
            if (isLongPressing) {
                isLongPressed = true
                longPressed()
                isLongPressing = false
            }
        }
    }
}
