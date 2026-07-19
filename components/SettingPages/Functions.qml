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
            RowLayout {
                spacing: 12
                Layout.leftMargin: 54
                Layout.bottomMargin: 4
                FluTextBox{
                    placeholderText: qsTr("搜索进程名称")
                    onTextChanged: {
                        launchingHelperSubItem.showList = launchingHelperSubItem.appList.filter(function(item) {
                            return item.exeName.toLowerCase().includes(text)
                                || item.appName.toLowerCase().includes(text)
                        })
                    }
                }
                FluFilledButton{
                    text: qsTr("添加新进程")
                    onClicked: {
                        launchingHelperEditDialog.open()
                    }
                }
                FluToggleSwitch {
                    text: "禁用自动添加"
                    textRight: false
                    Layout.alignment: Qt.AlignVCenter
                    checked: Config.launchingHelperCfg.data.OnlyManualAddition
                    onCheckedChanged: {
                        if (checked !== Config.launchingHelperCfg.data.OnlyManualAddition)
                            Config.launchingHelperCfg.set("OnlyManualAddition", checked)
                    }
                    onClicked: {
                        console.log("SettingChanged: (launchingHelperCfg.OnlyManualAddition)checked=", checked)
                    }
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
                            RowLayout {
                                spacing: 5
                                FluToggleSwitch {
                                    Layout.alignment: Qt.AlignVCenter
                                    checked: itemData.enableHelper
                                    onCheckedChanged: {
                                        if (checked !== itemData.enableHelper) {
                                            Global.launchingHelper.switchHelperForItem(itemData.exeName, checked)
                                        }
                                    }
                                }
                                FluIconButton{
                                    iconSource: FluentIcons.Edit
                                    iconSize: 10
                                    onClicked: {
                                        params.exeName = itemData.exeName
                                        params.appName = itemData.appName
                                        params.enableHelper = itemData.enableHelper
                                        params.manualDuration = itemData.manualDuration
                                        params.exePath = itemData.exePath
                                        params.isEditMode = true
                                        launchingHelperEditDialog.open()
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

    FluContentDialog {
        id: launchingHelperEditDialog
        title: params.isEditMode ? qsTr("监测信息") : qsTr("添加进程")
        property int btns: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
        buttonFlags: params.isEditMode ? FluContentDialogType.NeutralButton | btns : btns
        negativeText: qsTr("取消")
        onNegativeClicked: {
            if (params.isEditMode)
                params.reset()
        }
        QtObject {
            id: params
            property string exeName: ""
            property string appName: ""
            property bool enableHelper: true
            property int manualDuration: 0
            property string exePath: ""
            property bool isEditMode: false
            function reset() {
                exeName = ""; appName = ""; enableHelper = true; manualDuration = 0; exePath = ""; isEditMode = false;
            }
        }
        contentDelegate: Component {
            ColumnLayout {
                RowLayout {
                    Layout.topMargin: 20
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 16
                    FluTextBox{
                        placeholderText: qsTr("例: app.exe")
                        Layout.fillWidth: true
                        Layout.horizontalStretchFactor: 1
                        text: params.exeName
                        onTextChanged: {
                            params.exeName = text
                        }
                        FluText {
                            text: qsTr("进程名称")
                            anchors.bottom: parent.top
                            anchors.left: parent.left
                            anchors.bottomMargin: 2
                        }
                    }
                    FluTextBox{
                        placeholderText: qsTr("软件名称 (选填)")
                        Layout.fillWidth: true
                        Layout.horizontalStretchFactor: 1
                        text: params.appName
                        onTextChanged: {
                            params.appName = text
                        }
                        FluText {
                            text: parent.placeholderText
                            anchors.bottom: parent.top
                            anchors.left: parent.left
                            anchors.bottomMargin: 2
                        }
                    }
                }
                FluTextBox{
                    placeholderText: qsTr("选填, 后续可自动识别")
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    text: params.exePath
                    onTextChanged: {
                        params.exePath = text
                    }
                    FluText {
                        text:  qsTr("进程路径 (选填)")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                }
                RowLayout {
                    Layout.topMargin: 16
                    Layout.bottomMargin: 10
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 30
                    FluTextBox {
                        placeholderText: qsTr("单位: 毫秒(ms)")
                        inputMethodHints: Qt.ImhDigitsOnly
                        text: params.manualDuration
                        onTextChanged: {
                            params.manualDuration = Number(text)
                        }
                        FluText {
                            text: qsTr("加载时间 (选填)")
                            anchors.bottom: parent.top
                            anchors.left: parent.left
                            anchors.bottomMargin: 2
                        }
                    }
                    FluToggleSwitch {
                        text: "是否启用"
                        textRight: false
                        Layout.alignment: Qt.AlignVCenter
                        checked: params.enableHelper
                        onCheckedChanged: {
                            params.enableHelper = checked
                        }
                    }
                }
            }
        }
        positiveText: qsTr("确定")
        onPositiveClicked: {
            Global.launchingHelper.setItem(params.exeName, params.appName, params.enableHelper, params.manualDuration, params.exePath)
            params.reset()
        }
        neutralText: qsTr("删除该项")
        onNeutralClicked: {
            launchingHelperDeleteDialog.open()
        }
    }
    FluContentDialog {
        id: launchingHelperDeleteDialog
        title: qsTr("删除选项")
        contentDelegate: Component {
            FluText {
                text: qsTr("确定要删除该项进程吗？")
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
            }
        }
        onPositiveClicked: {
            Global.launchingHelper.deleteItem(params.exeName)
            params.reset()
            console.log("LaunchingHelper:", params.exeName, "deleted")
        }
        onNegativeClicked: {
            params.reset()
        }
    }
}