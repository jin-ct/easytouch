import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import FluentUI
import Functions 1.0
import Qt.labs.platform 1.0

FluWindow {

    id:window
    title: qsTr("易触控提示")
    width: 300
    height: 160
    fixSize: true
    showMinimize: false

    property string crashFilePath

    Component.onCompleted: {
        window.stayTop = true
    }
    Component.onDestruction: {
        FluRouter.exit()
    }

    onInitArgument:
        (argument)=>{
            crashFilePath = argument.crashFilePath
        }

    FluText{
        id:text_info
        anchors{
            top: parent.top
            topMargin: 50
            left: parent.left
            right: parent.right
            leftMargin: 10
            rightMargin: 10
        }
        wrapMode: Text.WrapAnywhere
        text: qsTr("程序遇到致命错误并导致崩溃")
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    RowLayout{
        anchors{
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        FluButton{
            text: qsTr("Dump目录")
            onClicked: {
                FluTools.showFileInFolder(crashFilePath)
            }
        }
        Item{
            width: 30
            height: 1
        }
        FluFilledButton{
            text: qsTr("重启程序")
            onClicked: {
                Global.funs.restartApp()
            }
        }
    }

}
