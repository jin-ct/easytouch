import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../SettingItems"

FluScrollablePage{
    id: root
    title: qsTr("触控优化功能")

    SettingItem {
        title: "发送“打开U盘”通知"
        iconSource: FluentIcons.USB
        description: "插入U盘时发送“点击打开U盘”的系统通知"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Config.settings.data.USBDriveHelper.Enable
                onCheckedChanged: {
                    if (checked !== Config.settings.data.USBDriveHelper.Enable)
                        Config.settings.set("USBDriveHelper.Enable", checked)
                }
                onClicked: {
                    console.log("SettingChanged: (USBDriveHelper.Enable)checked=", checked)
                }
            }
    }
    SettingItemExpander {
        title: "软件启动提示助手"
        iconSource: FluentIcons.Stop
        description: "软件启动时显示启动提示"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Config.settings.data.LaunchingHelper.Enable
                onCheckedChanged: {
                    if (checked !== Config.settings.data.LaunchingHelper.Enable)
                        Config.settings.set("LaunchingHelper.Enable", checked)
                }
                onClicked: {
                    console.log("SettingChanged: (LaunchingHelper.Enable)checked=", checked)
                }
            }
        contentHeight: launchingHelperSubItem.implicitHeight
        ColumnLayout {
            id: launchingHelperSubItem
            width: parent.width
            spacing: -1
            clip: true

            property var appList: Config.launchingHelperCfg.data.Apps
            property var showList: appList

            FluText {
                text: qsTr("已监测的进程")
                font.pixelSize: 12
                Layout.margins: 10
                Layout.leftMargin: 22
            }
            FluTextBox{
                placeholderText: qsTr("搜索进程名称")
                Layout.leftMargin: 54
                Layout.bottomMargin: 4
                onTextChanged: {
                    launchingHelperSubItem.showList = launchingHelperSubItem.appList.filter(function(item) {
                        return item.exeName.toLowerCase().includes(text)
                            || item.appName.toLowerCase().includes(text)
                    })
                }
            }
            Repeater {
                model: launchingHelperSubItem.showList
                delegate:
                    ExpandedItem {
                        property var itemData: launchingHelperSubItem.showList[index]
                        title: itemData.appName === "" ? itemData.exeName : itemData.appName
                        description: itemData.exePath
                        topPadding: 8
                        bottomPadding: 8
                        controlDelegate:
                            FluToggleSwitch {
                                Layout.alignment: Qt.AlignVCenter
                                checked: itemData.enableHelper
                                onCheckedChanged: {
                                    var app = Config.launchingHelperCfg.get("Apps[" + index + "]");
                                    if (checked !== app.enableHelper) {
                                        Global.launchingHelper.switchHelperForItem(app.exeName, checked)
                                        console.log("SettingChanged: (launchingHelper.*" + app.exeName + "*.enableHelper)checked=", checked)
                                    }
                                }
                            }
                    }
            }
            FluText {
                Layout.alignment: Qt.AlignHCenter
                Layout.margins: 16
                visible: launchingHelperSubItem.showList.length <= 0
                text: qsTr("空")
                textColor: FluTheme.fontTertiaryColor
            }
        }
    }
    SettingItem {
        title: "微信触控优化"
        iconSource: FluentIcons.TiltDown
        description: "针对微信4.x不支持触控问题优化（微信窗口顶置时失效，可用于临时关闭）"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Config.settings.data.WeChatTouchHelper.Enable
                onCheckedChanged: {
                    if (checked !== Config.settings.data.WeChatTouchHelper.Enable)
                        Config.settings.set("WeChatTouchHelper.Enable", checked)
                }
                onClicked: {
                    console.log("SettingChanged: (WeChatTouchHelper.Enable)checked=", checked)
                }
            }
    }
    SettingItem {
        title: "窗口焦点助手"
        iconSource: FluentIcons.Favicon
        description: "保障新窗口获取焦点 (该功能Bug较多，不建议使用该功能)"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Config.settings.data.WindowFocusHelper.Enable
                onCheckedChanged: {
                    if (checked !== Config.settings.data.WindowFocusHelper.Enable)
                        Config.settings.set("WindowFocusHelper.Enable", checked)
                }
                onClicked: {
                    console.log("SettingChanged: (WindowFocusHelper.Enable)checked=", checked)
                }
            }
    }
}