import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../Control"

FluScrollablePage{
    id: root
    title: qsTr("基本设置")

    Connections {
        target: Global.updateHelper
        function onUpdateCheckFinished(hasUpdate, success) {
            let msg = ""
            if (success) {
                showSuccess(qsTr("检查成功"))
                msg = hasUpdate
                        ? "有新版本 (" + Global.updateHelper.latestVersion + "), 现在开始更新"
                        : "当前版本已为最新" + " (" + Global.updateHelper.latestVersion + ")"
            }
            checkUpdateItem.setCheckFinished(true, msg)
        }
        function onUpdateError(err) {
            showError(qsTr("检查失败"))
            checkUpdateItem.setCheckFinished(false, err)
        }
    }

    SettingItem {
        title: "开机自启动"
        iconSource: FluentIcons.Location
        description: "Windows 登录后自动启动易触控"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Config.settings.data.AutoStart
                onCheckedChanged: {
                    if (checked !== Config.settings.data.AutoStart)
                        Config.settings.set("AutoStart", checked)
                }
                onClicked: {
                    console.log("SettingChanged: (autoStart)checked=", checked)
                }
            }
    }
    SettingItemExpander {
        title: "自动更新"
        iconSource: FluentIcons.UpArrowShiftKey
        description: "软件启动时自动从远程仓库检查并获取最新发布版"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Config.settings.data.AutoUpdate
                onCheckedChanged: {
                    if (checked !== Config.settings.data.AutoUpdate)
                        Config.settings.set("AutoUpdate", checked)
                }
                onClicked: {
                    console.log("SettingChanged: (autoUpdate)checked=", checked)
                }
            }
        contentHeight: autoUpdateSubItem.implicitHeight
        ColumnLayout {
            id: autoUpdateSubItem
            width: parent.width
            spacing: -1
            clip: true

            ExpandedItem {
                title: "当检查到新版本时的行为"
                controlDelegate:
                    FluComboBox {
                        Layout.alignment: Qt.AlignVCenter
                        textRole: "text"
                        valueRole: "value"
                        model: ListModel {
                            ListElement { text: "自动安装并提醒"; value: "fullyAuto" }
                            ListElement { text: "仅提醒"; value: "onlyRemind" }
                            ListElement { text: "静默自动安装"; value: "noNotice" }
                        }
                        Component.onCompleted: {
                            let cur = Config.settings.get("AutoUpdateBehavior")
                            let map = {"fullyAuto": 0, "onlyRemind": 1, "noNotice": 2}
                            currentIndex = map[cur]
                        }
                        onActivated: {
                            Config.settings.set("AutoUpdateBehavior", currentValue)
                            console.log("SettingChanged: (AutoUpdateBehavior)selected=", currentText)
                        }
                    }
            }
        }
    }
    SettingItemExpander {
        id: checkUpdateItem
        title: "检查更新"
        expand: true
        iconSource: FluentIcons.CheckMark
        description: "检查更新以获得最新版本"
        property string updateErr: ""
        property string updateMsg:
            Global.updateHelper.latestVersion === ""
               ? "未检查更新"
               : (Global.updateHelper.hasUpdate
                  ? "有新版本 (" + Global.updateHelper.latestVersion + "), 现在开始更新"
                  : "当前版本已为最新" + " (" + Global.updateHelper.latestVersion + ")")
        function setCheckFinished(success, msg) {
            if (controlLoader)
                controlLoader.item.loading = false
            if (msg !== "" && success) {
                updateMsg = msg
                updateErr = ""
            } else if (!success) {
                updateErr = msg
            }
        }
        controlDelegate:
            FluLoadingButton {
                text: "检查更新"
                onClicked: {
                    Global.updateHelper.checkForUpdates("jin-ct", "easytouch")
                    loading = true;
                }
            }
        contentHeight: checkUpdateSubItem.implicitHeight
        ColumnLayout {
            id: checkUpdateSubItem
            width: parent.width
            spacing: -1
            clip: true
            ExpandedItem {
                title: checkUpdateItem.updateErr === "" ? checkUpdateItem.updateMsg : "检查失败"
                description: checkUpdateItem.updateErr
            }
            ExpandedItem {
                title: "更新通道"
                description: "检查更新版本通道，测试版(Beta)通常功能较新但可能存在稳定性问题"
                controlDelegate:
                    FluComboBox {
                        Layout.alignment: Qt.AlignVCenter
                        textRole: "text"
                        valueRole: "value"
                        currentIndex: Config.settings.get("UpdateChannel") === "release" ? 0 : 1
                        model: ListModel {
                            ListElement { text: "稳定版"; value: "release" }
                            ListElement { text: "测试版"; value: "beta" }
                        }
                        onActivated: {
                            Config.settings.set("UpdateChannel", currentValue)
                            console.log("SettingChanged: (UpdateChannel)selected=", currentText)
                        }
                    }
            }
        }
    }
    SettingItem {
        title: "屏幕批注保存位置"
        iconSource: FluentIcons.SIPUndock
        description: Config.settings.data.Drawpad.SavePath // 当前位置
        controlDelegate:
            FluLoadingButton {
                text: "选择目录"
                onClicked: {
                    let newPath = Global.fileHelper.openFolderDialog("选择屏幕批注保存目录", Config.settings.get("Drawpad.SavePath"))
                    if (newPath) {
                        Config.settings.set("Drawpad.SavePath", newPath)
                        console.log("penSavePathChanged: ", penSavePath)
                    }
                }
            }
    }
}