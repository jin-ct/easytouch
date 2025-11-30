import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic
import "./"

DialogWindow {
    id: volumeDialog
    dialogWidth: 126
    dialogHeight: 30
    visible: false

    onVisibleChanged: {
        volumeSlider.value = funsObject.getVolume()
    }

    Slider {
        id: volumeSlider
        width: 116
        height: parent.height
        anchors.centerIn: parent
        from: 0
        to: 1
        value: funsObject.getVolume()
        onValueChanged: {
            funsObject.setVolume(value)
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
}
