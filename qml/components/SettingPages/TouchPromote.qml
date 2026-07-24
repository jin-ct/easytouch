import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../Control"
import "./Components"

FluScrollablePage{
    id: root
    title: qsTr("触控优化")

    RowLayout {
        Layout.alignment: Qt.AlignTop
        Layout.margins: 8
        Layout.fillWidth: true

        RowLayout {
            spacing: 4
            FluText {
                text: qsTr("规则管理")
                font.pixelSize: 15
            }
            FluIconButton {
                iconSource: FluentIcons.Unknown
                iconSize: 13
                onClicked: {
                    toolTip_rule.visible = true
                }
                FluTooltip {
                    id: toolTip_rule
                    visible: parent.hovered
                    text: qsTr("触控优化规则允许针对窗口定制优化方案，如将触控手势转为键鼠操作")
                }
            }
        }
        Item {
            Layout.fillWidth: true
        }
        RowLayout {
            spacing: 6
            FluFilledButton {
                text: qsTr("新建规则")
            }
            FluDropDownButton {
                text: qsTr("导入/导出")
                FluMenuItem{
                    text: qsTr("导入规则")
                }
                FluMenuItem{
                    text: qsTr("导出规则")
                }
            }
        }
    }

    SettingItemExpander {
        title: "微信触控优化"
        expand: true
        iconSource: FluentIcons.TiltDown
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
        contentHeight: subItem.implicitHeight
        ColumnLayout {
            id: subItem
            width: parent.width
            spacing: -1
            clip: true
            RowLayout {
                spacing: 20
                Layout.leftMargin: 16
                Layout.topMargin: 32
                Layout.rightMargin: 16
                FluTextBox {
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 4
                    Layout.preferredWidth: 150
                    activeFocusOnTab: true
                    onFocusChanged: {
                        if (text === "" && !focus) {
                            showWarning(qsTr("请输入规则名称"))
                            parent.forceActiveFocus()
                        }
                    }
                    FluText {
                        text: qsTr("*规则名称")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                }
                FluTextBox {
                    id: textBox_exeName
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 4
                    Layout.preferredWidth: 150
                    placeholderText: qsTr("example.exe")
                    activeFocusOnTab: true
                    FluText {
                        text: qsTr("*进程名称")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                }
                FluTextBox {
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 4
                    Layout.preferredWidth: 150
                    placeholderText: qsTr("选填，留空则不匹配")
                    activeFocusOnTab: true
                    FluText {
                        text: qsTr("窗口类名")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                }
            }
            RowLayout {
                spacing: 20
                Layout.leftMargin: 16
                Layout.topMargin: 32
                Layout.rightMargin: 16
                FluTextBox {
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 5
                    Layout.preferredWidth: 150
                    placeholderText: qsTr("选填，留空则不匹配")
                    activeFocusOnTab: true
                    FluText {
                        text: qsTr("窗口标题")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                }
                Item {
                    implicitWidth: textBox_exeName.width
                    implicitHeight: textBox_exeName.height
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 3
                    Layout.preferredWidth: 150
                    FluText {
                        text: qsTr("窗口Style")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                    WindowStyleSelectItem {
                        id: input_windowStyle
                    }
                }
                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 5
                    Layout.preferredWidth: 230
                    FluIconButton {
                        iconSource: FluentIcons.Settings
                        iconSize: 15
                        FluTooltip {
                            visible: parent.hovered
                            text: qsTr("高级设置")
                        }
                    }
                    FluIconButton {
                        iconSource: FluentIcons.Delete
                        iconSize: 15
                        FluTooltip {
                            visible: parent.hovered
                            text: qsTr("删除")
                        }
                    }
                    FluButton {
                        text: qsTr("选择窗口")
                    }
                    FluFilledButton {
                        text: qsTr("编辑规则")
                    }
                }
            }
            RowLayout {
                spacing: 20
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 32
                Layout.bottomMargin: 16

                TouchPromoteRuleList {
                    title: qsTr("触摸事件")
                    Layout.fillWidth: true
                    Layout.preferredWidth: 200
                }
                TouchPromoteRuleList {
                    title: qsTr("动作")
                    Layout.fillWidth: true
                    Layout.preferredWidth: 200
                }
            }
        }
    }
}
