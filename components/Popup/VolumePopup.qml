import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import "./"

PopupWindow {
    id: volumePopup
    popupWidth: contentRow.childrenRect.width + 12  // "+12" 表示左右边距和
    popupHeight: 36
    visible: false

    property bool isMute: false

    onVisibleChanged: {
        volumeSlider.value = funs.getVolume()
        isMute = funs.getIsMute()
    }

    Row {
        id: contentRow
        anchors {
            centerIn: parent
            left: parent.left; leftMargin: 6
            right: parent.right; rightMargin: 6
        }

        Button {
            width: 22
            height: 22

            background: Rectangle {
                id: btnBackground
                anchors.fill: parent
                radius: 3

                Image {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    mipmap:true
                    source: isMute ? "qrc:/icon/volume_mute.svg" :"qrc:/icon/volume_2.svg"
                }
            }

            onPressedChanged: {
                scale = pressed ? 0.94 : 1.0
                btnBackground.color = pressed ? "#20000000" : "#00000000"
            }
            onClicked: {
                isMute = !isMute
                funs.setMute(isMute);
            }

            Behavior on scale {
                NumberAnimation { duration: 88 }
            }
        }

        Slider {
            id: volumeSlider
            width: 116
            height: parent.height
            from: 0
            to: 1
            value: funs.getVolume()

            property bool volumeDirty: false

            onValueChanged: {
                volumeDirty = true
                throttleTimer.restart()
            }

            Timer {
                id: throttleTimer
                interval: 80    // 80ms 左右一刷
                repeat: false
                onTriggered: {
                    if (volumeSlider.volumeDirty) {
                        volumeSlider.volumeDirty = false
                        funs.setVolume(volumeSlider.value)
                    }
                }
            }

            background: Rectangle {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: volumeSlider.availableWidth; height: 4; radius: 2
                color: "#34495e"

                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height; radius: 2
                    color: "#409EFF"
                }
            }

            handle: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                width: 14; height: 14; radius: 7
                color: volumeSlider.pressed ? "#79BBFF" : "#ecf0f1"
                border.color: "#409EFF"; border.width: 2

                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        Text {
            leftPadding: 2
            rightPadding: 6
            anchors.verticalCenter: parent.verticalCenter
            text: Number(volumeSlider.value*100).toFixed(0)
            font.pixelSize: 13
            color: "#666666"
        }
    }
}
