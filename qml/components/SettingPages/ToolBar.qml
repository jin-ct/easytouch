import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../Control"

FluScrollablePage{
    id: root
    title: qsTr("工具栏")

    SettingItemExpander {
        id: toolBarItem
        title: "启用侧边工具栏"
        expand: true
        iconSource: FluentIcons.HolePunchOff
        description: "是否启用侧边工具栏"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Config.settings.data.ToolBar.Enable
                onCheckedChanged: {
                    if (checked !== Config.settings.data.ToolBar.Enable)
                        Config.settings.set("ToolBar.Enable", checked)
                }
                onClicked: {
                    console.log("SettingChanged: (ToolBar.Enable)checked=", checked)
                }
            }
        contentHeight: toolBarSubItem.implicitHeight
        ColumnLayout {
            id: toolBarSubItem
            width: parent.width
            spacing: -1
            clip: true
            ExpandedItem {
                title: "自动展开工具栏"
                description: "软件启动时左右侧工具栏按钮自动展开"
                controlDelegate:
                    FluToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: Config.settings.data.ToolBar.AutoShowBtns
                        onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.AutoShowBtns)
                                Config.settings.set("ToolBar.AutoShowBtns", checked)
                        }
                        onClicked: {
                            console.log("SettingChanged: (ToolBar.AutoShowBtns)checked=", checked)
                        }
                    }
            }
            ExpandedItem {
                title: "自动收起工具栏"
                description: "当点击工具栏窗口以外区域时自带收起工具栏"
                controlDelegate:
                    FluToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: Config.settings.data.ToolBar.AutoHideBtns
                        onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.AutoHideBtns)
                                Config.settings.set("ToolBar.AutoHideBtns", checked)
                        }
                        onClicked: {
                            console.log("SettingChanged: (ToolBar.AutoHideBtns)checked=", checked)
                        }
                    }
            }
            ExpandedItem {
                title: "窗口透明度闪烁"
                description: "窗口透明度周期性闪烁"
                controlDelegate:
                    FluToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: Config.settings.data.ToolBar.ShowWindowOpacityAnimation
                        onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.ShowWindowOpacityAnimation)
                                Config.settings.set("ToolBar.ShowWindowOpacityAnimation", checked)
                        }
                        onClicked: {
                            console.log("SettingChanged: (ToolBar.ShowWindowOpacityAnimation)checked=", checked)
                        }
                    }
            }
            ExpandedItem {
                title: "置顶增强"
                description: "通过定时器触发让工具栏和相关窗口置于最顶层"
                controlDelegate:
                    FluToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                        checked: Config.settings.data.ToolBar.StayTopEnhanced
                        onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.StayTopEnhanced)
                                Config.settings.set("ToolBar.StayTopEnhanced", checked)
                        }
                        onClicked: {
                            console.log("SettingChanged: (ToolBar.StayTopEnhanced)checked=", checked)
                        }
                    }
            }
        }
    }
}