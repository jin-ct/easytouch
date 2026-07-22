import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../SettingItems"
import "../Control"

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
                    MDropDownButton {
                        id: input_windowStyle
                        property var selectedFlags: []
                        property int windowStyle: 0
                        readonly property int windowStyleCount: selectedFlags.length
                        contentItem: FluText {
                            text: qsTr("已选 ") + input_windowStyle.windowStyleCount + qsTr(" 项")
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignVCenter
                        }
                        anchors.fill: parent
                        menu.width: Math.max(200, input_windowStyle.width)
                        menu.height: 240
                        menuContentItem: Item {
                            RowLayout {
                                id: control_box
                                spacing: 8
                                anchors.margins: 6
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                FluTextBox {
                                    id: filter_text
                                    iconSource: FluentIcons.Search
                                    Layout.fillWidth: true
                                    placeholderText: qsTr("筛选")
                                    onTextChanged: {
                                        list_windowStyle.model = getWindowStyleListModel(text)
                                    }
                                }
                                FluButton {
                                    text: qsTr("全部取消")
                                    onClicked: {
                                        clearWindowStyleSelection()
                                    }
                                }
                            }
                            ListView {
                                id: list_windowStyle
                                anchors {
                                    top: control_box.bottom
                                    bottom: parent.bottom
                                    left: parent.left
                                    right: parent.right
                                    margins: 6
                                }
                                spacing: 4
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                model: getWindowStyleListModel(filter_text.text)
                                delegate: FluCheckBox {
                                    required property string name
                                    required property string tip
                                    required property int value
                                    text: name
                                    padding: 1
                                    checked: isWindowStyleSelected(value, input_windowStyle.selectedFlags)
                                    onClicked: {
                                        toggleWindowStyleFlag(value)
                                        checked = Qt.binding(function () {
                                            return isWindowStyleSelected(value, input_windowStyle.selectedFlags)
                                        })
                                    }
                                    onDoubleClicked: {
                                        toolTip_windowStyle.visible = true
                                    }
                                    FluTooltip {
                                        id: toolTip_windowStyle
                                        visible: parent.hovered && tip !== ""
                                        text: tip
                                        delay: 500
                                    }
                                }
                                ScrollBar.vertical: FluScrollBar {}
                            }
                        }
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

                FluFrame {
                    implicitHeight: 120
                    Layout.fillWidth: true
                    Layout.preferredWidth: 200
                    FluText {
                        text: qsTr("触摸事件")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                }
                FluFrame {
                    implicitHeight: 120
                    Layout.fillWidth: true
                    Layout.preferredWidth: 200
                    FluText {
                        text: qsTr("动作")
                        anchors.bottom: parent.top
                        anchors.left: parent.left
                        anchors.bottomMargin: 2
                    }
                }
            }
        }
    }

    function getWindowStyleFlags() {
        return [
            {name: "WS_CAPTION", value: 0x00C00000, tip: "窗口具有标题栏"},
            {name: "WS_MAXIMIZEBOX", value: 0x00010000, tip: "窗口具有最大化按钮"},
            {name: "WS_MINIMIZEBOX", value: 0x00020000, tip: "窗口具有最小化按钮"},
            {name: "WS_VISIBLE", value: 0x10000000, tip: "窗口最初可见"},
            {name: "WS_SYSMENU", value: 0x00080000, tip: "标题栏上有一窗口菜单"},
            {name: "WS_BORDER", value: 0x00800000, tip: "窗口具有细线边框"},
            {name: "WS_DISABLED", value: 0x08000000, tip: "窗口最初处于禁用状态"},
            {name: "WS_MAXIMIZE", value: 0x01000000, tip: "窗口最初是最大化的"},
            {name: "WS_MINIMIZE", value: 0x20000000, tip: "窗口最初是最小化的"},
            {name: "WS_POPUP", value: 0x80000000, tip: "窗口是弹出窗口"},
            {name: "WS_CHILD", value: 0x40000000, tip: "窗口是子窗口"},
            {name: "WS_THICKFRAME", value: 0x00040000, tip: "窗口具有大小调整边框"},
            {name: "WS_CLIPCHILDREN", value: 0x02000000, tip: ""},
            {name: "WS_CLIPSIBLINGS", value: 0x04000000, tip: ""},
            {name: "WS_DLGFRAME", value: 0x00400000, tip: ""},
            {name: "WS_HSCROLL", value: 0x00100000, tip: ""},
            {name: "WS_VSCROLL", value: 0x00200000, tip: ""}
        ]
    }

    // 统一按 uint32 比较，避免 WS_POPUP(0x80000000) 有符号/无符号不一致
    function styleFlagKey(value) {
        return value >>> 0
    }

    function isWindowStyleSelected(value, selectedFlags) {
        var key = styleFlagKey(value)
        for (var i = 0; i < selectedFlags.length; i++) {
            if (styleFlagKey(selectedFlags[i]) === key)
                return true
        }
        return false
    }

    function rebuildWindowStyleFromSelection(selectedFlags) {
        var style = 0
        for (var i = 0; i < selectedFlags.length; i++)
            style = style | selectedFlags[i]
        // 归一为 int32，与 QML property int 一致
        input_windowStyle.windowStyle = style | 0
    }

    function toggleWindowStyleFlag(value) {
        var key = styleFlagKey(value)
        var next = []
        var found = false
        for (var i = 0; i < input_windowStyle.selectedFlags.length; i++) {
            var flag = input_windowStyle.selectedFlags[i]
            if (styleFlagKey(flag) === key)
                found = true
            else
                next.push(flag)
        }
        if (!found)
            next.push(value | 0)
        input_windowStyle.selectedFlags = next
        rebuildWindowStyleFromSelection(next)
    }

    function clearWindowStyleSelection() {
        input_windowStyle.selectedFlags = []
        input_windowStyle.windowStyle = 0
    }

    function getWindowStyleListModel(filterText) {
        var list = getWindowStyleFlags()
        if (!filterText)
            return list
        var keyword = filterText.toLowerCase()
        return list.filter(function (item) {
            return item.name.toLowerCase().indexOf(keyword) !== -1
        })
    }
}
