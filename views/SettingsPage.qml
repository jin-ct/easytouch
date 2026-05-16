import QtQuick
import QtQuick.Controls
import Functions 1.0
import "../components/Card"
import "../components"

Window {
    id: win
    visible: true
    opacity: 1
    height: 480
    width: 640
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    Connections {
        target: Config.settings
        function onConfigChanged(path, value) {
            if (!Config.settings.readReady)
                return
            switch(path) {
            case "AutoStart":
                Global.funs.setAutoStart(value)
                break;
            }
        }
    }

    Connections {
        target: Global.updateHelper
        function onUpdateCheckFinished() {
            updateBtn.button.enabled = true
            updateBtn.text = "检查更新"
        }
    }

    Rectangle {
        id: root

        color: "#ffffff"
        border.color: "#dcdfe6"
        border.width: 1
        radius: 10


        anchors.fill: parent

        WindowTitleBar {
            id: titleBar
            title: "易触控设置"
            window: win
        }

        ScrollView {
            id: scrollView
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            contentItem: Flickable {
                id: flickableItem
                contentWidth: contentColumn.implicitWidth
                contentHeight: contentColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: contentColumn
                    width: scrollView.width
                    spacing: 12
                    padding: 16

                    // 顶部基本信息
                    Rectangle {
                        id: headerCard
                        implicitHeight: 80
                        radius: 10
                        color: "#ffffff"
                        border.color: "#e4e7ed"
                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }

                        Item {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 20
                            }

                            Image {
                                id: logoImage
                                source: "qrc:/icon/icon.svg"
                                mipmap:true
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                id: info
                                anchors.left: logoImage.right
                                anchors.leftMargin: 16
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Label {
                                    text: "易触控工具栏"
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: "#303133"
                                }

                                Label {
                                    text: qsTr("版本：%1").arg(Qt.application.version)
                                    font.pixelSize: 12
                                    color: "#606266"
                                }

                                Label {
                                    text: "优化大屏触控体验 | MIT协议开源 | 作者：Jin"
                                    font.pixelSize: 12
                                    color: "#909399"
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Text {
                        text: "常规"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    SettingsSwitchCard {
                        id: autoStart
                        title: "开机自启动"
                        description: "Windows 登录后自动启动易触控"
                        checked: Config.settings.data.AutoStart
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.AutoStart)
                                Config.settings.set("AutoStart", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoStart)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoUpdate
                        title: "自动更新"
                        description: "软件启动时自动从远程仓库检查并获取最新发布版"
                        checked: Config.settings.data.AutoUpdate
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.AutoUpdate)
                                Config.settings.set("AutoUpdate", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoUpdate)checked=", checked)
                        }
                    }

                    SettingsComboCard {
                        id: updatChannel
                        title: "更新通道"
                        description: "检查更新版本通道，测试版(beta)通常功能较新但可能存在稳定性问题"
                        model: ["release",  "beta"]
                        comboBox.currentIndex: Config.settings.get("UpdateChannel") === "release" ? 0 : 1
                        comboBox.onActivated: {
                            Config.settings.set("UpdateChannel", comboBox.currentValue)
                            console.log("SettingChanged: (UpdateChannel)selected=", currentText)
                        }
                    }

                    SettingsButtonCard {
                        id: updateBtn
                        title: "检查更新"
                        description: Global.updateHelper.latestVersion === ""
                                     ? "未检查更新，或检查失败"
                                     : (Global.updateHelper.hasUpdate
                                        ? "有新版本 (" + Global.updateHelper.latestVersion + "), 现在开始更新"
                                        : "当前版本已为最新")
                        text: "检查更新"
                        button.onClicked: {
                            Global.updateHelper.checkForUpdates("jin-ct", "easytouch")
                            button.enabled = false
                            text = "检查中"
                        }
                    }

                    Text {
                        text: "工具栏设置"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    SettingsSwitchCard {
                        id: showToolBar
                        title: "显示侧边工具栏"
                        description: "是否显示侧边工具栏"
                        checked: Config.settings.data.ToolBar.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.Enable)
                                Config.settings.set("ToolBar.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (isShowToolBar)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoShowBtns
                        title: "自动展开工具栏"
                        description: "软件启动时左右侧工具栏按钮自动展开"
                        checked: Config.settings.data.ToolBar.AutoShowBtns
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.AutoShowBtns)
                                Config.settings.set("ToolBar.AutoShowBtns", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoShowBtns)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoHideBtns
                        title: "自动收起工具栏"
                        description: "当点击工具栏窗口以外区域时自带收起工具栏"
                        checked: Config.settings.data.ToolBar.AutoHideBtns
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.AutoHideBtns)
                                Config.settings.set("ToolBar.AutoHideBtns", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoHideBtns)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: showWinodwOpacityAnimation
                        title: "窗口透明度闪烁"
                        description: "窗口透明度周期性闪烁"
                        checked: Config.settings.data.ToolBar.ShowWindowOpacityAnimation
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.ShowWindowOpacityAnimation)
                                Config.settings.set("ToolBar.ShowWindowOpacityAnimation", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (ShowWindowOpacityAnimation)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: stayTopEnhanced
                        title: "置顶增强"
                        description: "通过定时器触发让工具栏和相关窗口置于最顶层"
                        checked: Config.settings.data.ToolBar.StayTopEnhanced
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.StayTopEnhanced)
                                Config.settings.set("ToolBar.StayTopEnhanced", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (stayTopEnhanced)checked=", checked)
                        }
                    }

                    Text {
                        text: "触控优化功能开关"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    SettingsSwitchCard {
                        id: sendOpenUsb
                        title: "发送“打开U盘”通知"
                        description: "插入U盘时发送“点击打开U盘”的系统通知"
                        checked: Config.settings.data.USBDriveHelper.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.USBDriveHelper.Enable)
                                Config.settings.set("USBDriveHelper.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (sendOpenUsb)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: weChatTouchHelperSwich
                        title: "微信触控优化"
                        description: "针对微信4.0不支持触控问题优化（微信窗口顶置时失效，可用于临时关闭）"
                        checked: Config.settings.data.WeChatTouchHelper.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.WeChatTouchHelper.Enable)
                                Config.settings.set("WeChatTouchHelper.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (weChatTouchHelperSwich)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: windowFocusHelperSwich
                        title: "窗口焦点助手"
                        description: "保障新窗口获取焦点，防止触控下多次点击导致新窗口焦点被抢占"
                        checked: Config.settings.data.WindowFocusHelper.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.WindowFocusHelper.Enable)
                                Config.settings.set("WindowFocusHelper.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (windowFocusHelperSwich)checked=", checked)
                        }
                    }

                    Text {
                        text: "其他"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    // 屏幕批注保存位置设置
                    SettingsButtonCard {
                        id: penSavePathSetting
                        title: "屏幕批注保存位置"
                        description: Config.settings.data.Drawpad.SavePath // 当前位置
                        text: "选择目录"
                        button.onClicked: {
                            let newPath = Global.fileHelper.openFolderDialog("选择屏幕批注保存目录", Config.settings.get("Drawpad.SavePath"))
                            if (newPath) {
                                Config.settings.set("Drawpad.SavePath", newPath)
                                console.log("penSavePathChanged: ", penSavePath)
                            }
                        }
                    }

                    SettingsButtonCard {
                        title: "Github仓库"
                        description: "https://github.com/jin-ct/easytouch"
                        text: "打开链接"
                        button.onClicked: {
                            Qt.openUrlExternally("https://github.com/jin-ct/easytouch")
                        }
                    }

                    Item { height: 8; width: 1 } // 底部留白
                }
            }
        }
    }
}
