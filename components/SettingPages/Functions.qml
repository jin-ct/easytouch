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
    SettingItem {
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