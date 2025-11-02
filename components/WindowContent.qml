import QtQuick
import QtQuick.Controls
import "./"

Rectangle {
    id: items
    width: parent.width
    height: windowBaseHeight
    radius: parent.width * 0.5
    anchors.bottom: parent.bottom
    color: '#62000000'
    clip: true
    border.color: "#40FAFCFF"
    border.width: 1

    property var window
    property int funBtnCount: 0
    property int windowBaseHeight: 0
    property bool isFolded: false

    property var funsObject

    property bool isFunCloseWindowEnable: true
    onIsFunCloseWindowEnableChanged: {
        funBtnCount += isFunCloseWindowEnable ? 1 : -1
        funCloseWindow.btnVisible = isFunCloseWindowEnable
    }
    property bool isFunVolumeEnable: true
    onIsFunVolumeEnableChanged: {
        funBtnCount += isFunCloseWindowEnable ? 1 : -1
        funVolume.btnVisible = isFunVolumeEnable
    }
    property bool isFunOpenUDiskEnable: false
    onIsFunOpenUDiskEnableChanged: {
        funBtnCount += (isFunOpenUDiskEnable ? 2 : -2)
        funOpenUDisk.btnVisible = isFunOpenUDiskEnable
    }
    property bool isFunRmUDiskEnable: false
    onIsFunRmUDiskEnableChanged: {
        funRmUDisk.btnVisible = isFunRmUDiskEnable
    }

    Component.onCompleted: {
        funBtnCount = 2
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 4

        MoveBtn {
            id: btnMove
            window: items.window
        }
        FunBtn {
            id: funCloseWindow
            icon: "qrc:/icon/close.png"
            text: "关闭窗口"
            onClicked: {
                funsObject.closeTopWindow()
            }
        }
        FunBtn {
            id: funVolume
            icon: "qrc:/icon/volume.png"
            text: "系统音量"

            DialogWindow {
                id: volumeDialog
                dialogWidth: 126
                dialogHeight: 30
                visible: false
                funsObject: items.funsObject
                Slider {
                    id: volumeSlider
                    width: 110
                    height: parent.height
                    anchors.centerIn: parent
                    from: 0
                    to: 1
                    value: funsObject.getVolume()
                    onValueChanged: {
                        console.log("当前值:", value)
                        funsObject.setVolume(value)
                    }
                }
            }

            onClicked: {
                volumeDialog.heartPointX = funVolume.mapToGlobal(0, 0).x + funVolume.width/2
                volumeDialog.heartPointY = funVolume.mapToGlobal(0, 0).y + funVolume.height/2
                volumeDialog.visible = !volumeDialog.visible
            }
        }
        FunBtn {
            id: funOpenUDisk
            icon: "qrc:/icon/UDisk.png"
            text: "打开U盘"
            btnVisible: false
            onClicked: {
                funsObject.openDrive()
            }
        }
        FunBtn {
            id: funRmUDisk
            icon: "qrc:/icon/rmudisk.png"
            text: "弹出U盘"
            btnVisible: false

            DialogWindow {
                id: rmUDiskDialog
                dialogWidth: 50
                dialogHeight: 24
                visible: false
                funsObject: items.funsObject

                property bool success: false

                Text {
                    text: rmUDiskDialog.success ? "弹出成功" : "弹出失败"
                    color: "#fff"
                    font.pixelSize: 10
                    anchors.centerIn: parent
                }
            }

            onClicked: {
                rmUDiskDialog.success = funsObject.ejectDrive()
                rmUDiskDialog.heartPointX = items.mapToGlobal(0, 0).x + items.width/2
                rmUDiskDialog.heartPointY = items.mapToGlobal(0, 0).y + items.height/2
                rmUDiskDialog.visible = true
                rmUDiskDialog.delayColse(2000)
            }
        }
    }
    FoldBtn {
        id: btnFold
        isFold: items.isFolded
        onFold: {
            funCloseWindow.btnVisible = isFunCloseWindowEnable ? !funCloseWindow.btnVisible : isFunCloseWindowEnable
            funVolume.btnVisible = isFunVolumeEnable ? !funVolume.btnVisible : isFunVolumeEnable
            funOpenUDisk.btnVisible = isFunOpenUDiskEnable ? !funOpenUDisk.btnVisible : isFunOpenUDiskEnable
            funRmUDisk.btnVisible = isFunRmUDiskEnable ? !funRmUDisk.btnVisible : isFunRmUDiskEnable
            items.isFolded = !isFolded
        }
    }
}
