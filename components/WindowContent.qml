import QtQuick
import QtQuick.Controls
import "./"

Rectangle {
    id: items
    width: parent.width
    height: windowBaseHeight
    radius: parent.width * 0.5
    anchors.bottom: parent.bottom
    color: "#96FFFFFF"
    clip: true
    border.color: "#70909399"
    border.width: 1

    signal btnClicked()

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
        anchors.topMargin: 6

        MoveBtn {
            id: btnMove
            window: items.window
        }
        FunBtn {
            id: funCloseWindow
            icon: "qrc:/icon/close.svg"
            text: "关闭窗口"
            onClicked: {
                funsObject.closeTopWindow()
                btnClicked()
            }
        }
        FunBtn {
            id: funVolume
            icon: "qrc:/icon/volume.svg"
            text: "系统音量"

            VolumeDialog {
                id: volumeDialog
                funsObject: items.funsObject
            }

            onClicked: {
                volumeDialog.heartPointX = funVolume.mapToGlobal(0, 0).x + funVolume.width/2
                volumeDialog.heartPointY = funVolume.mapToGlobal(0, 0).y + funVolume.height/2
                volumeDialog.hideOrShow()
                btnClicked()
            }
        }
        FunBtn {
            id: funOpenUDisk
            icon: "qrc:/icon/UDisk.svg"
            text: "打开U盘"
            btnVisible: false
            onClicked: {
                funsObject.openDrive()
                btnClicked()
            }
        }
        FunBtn {
            id: funRmUDisk
            icon: "qrc:/icon/rmudisk.svg"
            text: "弹出U盘"
            btnVisible: false

            DialogWindow {
                id: rmUDiskDialog
                dialogWidth: 50
                dialogHeight: 24
                visible: false
                funsObject: items.funsObject

                property string tipsText: "弹出失败"

                Text {
                    text: rmUDiskDialog.tipsText
                    color: "#303133"
                    font.pixelSize: 10
                    anchors.centerIn: parent
                }
            }

            onClicked: {
                let isSuccess = funsObject.ejectDrive()
                rmUDiskDialog.tipsText =  isSuccess ? "弹出成功" : "弹出失败"
                rmUDiskDialog.heartPointX = items.mapToGlobal(0, 0).x + items.width/2
                rmUDiskDialog.heartPointY = items.mapToGlobal(0, 0).y + items.height/2
                rmUDiskDialog.hideOrShow()
                rmUDiskDialog.delayColse(2000)
                btnClicked()
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
            btnClicked()
        }
    }
}
