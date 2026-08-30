import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../Control"
import "./Components"

MScrollablePage {
    id: root
    title: qsTr("触控优化")

    readonly property var dataDefaults: ({
        xyThreshold: 12,
    })

    property var data: [
        {
            name: "XX窗口优化",
            enable: true,
            exeName: "app.exe",
            windowTitle: "",
            windowClass: "",
            windowStyle: 0,
            customArgs: {
                xyThreshold: 12,
                topMargin: 0,
                leftMargin: 0,
                rightMargin: 0,
                bottomMargin: 0
            },
            rules: [
                {
                    id: 1,
                    operation: 0,
                    operationText: "上下滑动",
                    arguments: { flip: false },
                    variables: ["up", "down", "dx", "dy", "dt"],
                    actions: [
                        {
                            id: 1,
                            action: 0,
                            actionText: "鼠标滚轮",
                            priority: 10,
                            executionTiming: 0,
                            requirements: [
                                { variable: "up", logic: 0, value: "" }
                            ],
                            arguments: {
                                enableInertia: true,
                                deltaScale: 3,
                                deltaMax: 360,
                                velocityThresholdMin: 1.2,
                                velocityThresholdMax: 360,
                                maxVelocityScale: 0.95,
                                velocityScale: 0.9,
                                velocityScaleInterval: 12
                            }
                        },
                        {
                            id: 2,
                            action: 1,
                            actionText: "模拟键盘",
                            priority: 10,
                            executionTiming: 0,
                            requirements: [
                                { variable: "up", logic: 0, value: "" }
                            ],
                            arguments: {
                                keys: [Qt.Key_Control, Qt.Key_Right],
                                longPress: false
                            }
                        },
                        {
                            id: 3,
                            action: 2,
                            actionText: "鼠标点击",
                            priority: 10,
                            executionTiming: 0,
                            requirements: [],
                            arguments: {
                                key: Qt.LeftButton,
                                longPress: false,
                                doubleClick: false,
                                relativePoint: { x: 0.0, y: 0.0 },
                                windowPoint: { x: 0, y: 0 },
                                screenPoint: { x: 0, y: 0 }
                            }
                        },
                        {
                            id: 4,
                            action: 3,
                            actionText: "调用外部链接",
                            priority: 10,
                            executionTiming: 0,
                            requirements: [],
                            arguments: { url: "" }
                        }
                    ]
                },
                {
                    id: 2,
                    operation: 1,
                    operationText: "左右滑动",
                    arguments: { flip: false },
                    variables: ["left", "right", "dx", "dy", "dt"],
                    actions: [
                        {
                            id: 1,
                            action: 2,
                            actionText: "鼠标点击",
                            priority: 10,
                            executionTiming: 0,
                            requirements: [],
                            arguments: {
                                key: Qt.LeftButton,
                                longPress: false,
                                doubleClick: false,
                                relativePoint: { x: 0.0, y: 0.0 },
                                windowPoint: { x: 0, y: 0 },
                                screenPoint: { x: 0, y: 0 }
                            }
                        }
                    ]
                },
                {
                    id: 3,
                    operation: 2,
                    operationText: "双指捏合",
                    arguments: { closeOnly: false, awayOnly: false },
                    variables: [],
                    actions: [
                        {
                            id: 1,
                            action: 2,
                            actionText: "鼠标点击",
                            priority: 10,
                            executionTiming: 0,
                            requirements: [],
                            arguments: {
                                key: Qt.LeftButton,
                                longPress: false,
                                doubleClick: false,
                                relativePoint: { x: 0.0, y: 0.0 },
                                windowPoint: { x: 0, y: 0 },
                                screenPoint: { x: 0, y: 0 }
                            }
                        }
                    ]
                },
                {
                    id: 4,
                    operation: 3,
                    operationText: "(多指)单击",
                    arguments: { fingersNum: 2, maxDistance: 60 },
                    variables: [],
                    actions: []
                },
                {
                    id: 5,
                    operation: 4,
                    operationText: "(多指)双击",
                    arguments: { fingersNum: 1, maxDistance: 60 },
                    variables: [],
                    actions: []
                },
                {
                    id: 6,
                    operation: 5,
                    operationText: "(多指)长按",
                    arguments: { fingersNum: 1, maxDistance: 60, minDuration: 200 },
                    variables: [],
                    actions: []
                }
            ]
        },
    ]

    property int rulesTick: 0
    property bool scrollToBottomPending: false

    function bumpRulesTick() {
        rulesTick++
    }

    function cloneObject(obj) {
        return JSON.parse(JSON.stringify(obj))
    }

    function copyItem(index) {
        if (index < 0 || index >= root.data.length)
            return
        var copy = cloneObject(data[index])
        data.push(copy)
        data = data
        scrollToBottom()
    }

    function scrollToBottom() {
        scrollToBottomPending = true
        applyScrollToBottom()
        scrollToBottomDebounce.restart()
    }

    function applyScrollToBottom() {
        flickable.contentY = Math.max(0, flickable.contentHeight - flickable.height)
    }

    Timer {
        id: scrollToBottomDebounce
        interval: 120
        onTriggered: scrollToBottomPending = false
    }

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
            FluButton {
                text: qsTr("导入规则")
            }
        }
    }
    Component {
        id: itemComponent
        SettingItemExpander {
            id: rule
            required property int index
            property var mData: root.data[index]
            title: mData.name
            expand: true
            iconSource: FluentIcons.TiltDown
            controlDelegate:
                FluToggleSwitch {
                    Layout.alignment: Qt.AlignVCenter
                    checked: mData.enable
                    onCheckedChanged: {
                        if (checked !== Config.settings.data.ToolBar.Enable)
                            root.data[index].enable = checked
                    }
                    onClicked: {
                        console.log("TouchPromoteRuleSwitch: (", mData.name, ")", checked)
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
                        text: mData.name
                        onTextEdited: root.data[index].name = text
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
                        text: mData.exeName
                        onTextEdited: root.data[index].exeName = text
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
                        text: mData.windowClass
                        onTextEdited: root.data[index].windowClass = text
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
                        Layout.preferredWidth: 210
                        Layout.minimumWidth: 120
                        placeholderText: qsTr("选填，留空则不匹配")
                        text: mData.windowTitle
                        onTextEdited: root.data[index].windowTitle = text
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
                        Layout.horizontalStretchFactor: 2
                        Layout.preferredWidth: 150
                        Layout.minimumWidth: 95
                        FluText {
                            text: qsTr("窗口Style")
                            anchors.bottom: parent.top
                            anchors.left: parent.left
                            anchors.bottomMargin: 2
                        }
                        WindowStyleSelectItem {
                            id: input_windowStyle
                            windowStyle: mData.windowStyle
                            onWindowChanged: root.data[index].windowStyle = windowStyle
                        }
                    }
                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        Layout.horizontalStretchFactor: 5
                        Layout.preferredWidth: 270
                        FluIconButton {
                            iconSource: FluentIcons.Settings
                            iconSize: 15
                            FluTooltip {
                                visible: parent.hovered
                                text: qsTr("高级设置")
                            }
                            onClicked: {
                                advancedSettingsDialog.show(index)
                            }
                        }
                        FluIconButton {
                            iconSource: FluentIcons.Delete
                            iconSize: 15
                            FluTooltip {
                                visible: parent.hovered
                                text: qsTr("删除")
                            }
                            onClicked: {
                                deleteDialog.show(index)
                            }
                        }
                        FluIconButton {
                            iconSource: FluentIcons.Copy
                            iconSize: 15
                            FluTooltip {
                                visible: parent.hovered
                                text: qsTr("复制")
                            }
                            onClicked: {
                                copyItem(index)
                            }
                        }
                        FluButton {
                            text: qsTr("选择窗口")
                        }
                        FluFilledButton {
                            text: qsTr("编辑规则")
                            onClicked: {
                                ruleEditor.scrollToOperationID = 0
                                ruleEditor.show(index)
                            }
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
                        id: list_touchEvent
                        title: qsTr("触摸事件")
                        model: {
                            var tick = root.rulesTick
                            return mData.rules
                        }
                        textRole: "operationText"
                        Layout.fillWidth: true
                        Layout.preferredWidth: 200
                        selected: 1
                        onItemDoubleClicked: function(id) {
                            ruleEditor.scrollToOperation(id)
                            ruleEditor.show(index)
                        }
                        onEditClicked: function(id) {
                            ruleEditor.scrollToOperation(id)
                            ruleEditor.show(index)
                        }
                    }
                    TouchPromoteRuleList {
                        id: list_touchAction
                        property int eventID: list_touchEvent.selected
                        title: eventID === 0 ? qsTr("执行动作") : qsTr("执行动作 (事件") + eventID + ")"
                        model: {
                            var tick = root.rulesTick
                            return mData.rules[eventID - 1].actions
                        }
                        textRole: "actionText"
                        enableSelect: false
                        Layout.fillWidth: true
                        Layout.preferredWidth: 200
                        onItemDoubleClicked: function(id) {
                            ruleEditor.scrollToAction(list_touchEvent.selected, id)
                            ruleEditor.show(index)
                        }
                        onEditClicked: function(id) {
                            ruleEditor.scrollToAction(list_touchEvent.selected, id)
                            ruleEditor.show(index)
                        }
                    }
                }
            }
        }
    }
    Repeater {
        model: root.data
        delegate: itemComponent
    }
    FluContentDialog {
        id: deleteDialog
        title: qsTr("删除")
        property int itemIndex: -1
        function show(index) {
            itemIndex = index
            open()
        }
        contentDelegate: Component {
            FluText {
                text: qsTr("确定要删除该项吗？")
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
            }
        }
        onPositiveClicked: {
            if (itemIndex < 0 || itemIndex >= root.data.length)
                return
            root.data.splice(itemIndex, 1)
            console.log("TouchPromote: rule deleted", itemIndex)
        }
    }
    FluContentDialog {
        id: advancedSettingsDialog
        title: qsTr("高级设置")
        property int itemIndex: -1
        function show(index) {
            itemIndex = index
            open()
        }
        contentDelegate: Component {
            ColumnLayout {
                property int index: advancedSettingsDialog.itemIndex
                anchors.left: parent.left
                anchors.leftMargin: 20
                spacing: 6
                FluText {
                    text: "接管操作区域与目标窗口边距 (px)"
                }
                RowLayout {
                    spacing: 20
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    RowLayout {
                        spacing: 10
                        FluText { text: qsTr("上边距"); }
                        FluTextBox {
                            Layout.preferredWidth: 72
                            cleanEnabled: false
                            text: String(root.data[index].customArgs.topMargin)
                            validator: IntValidator { bottom: -999999; top: 999999 }
                            onTextEdited: root.data[index].customArgs.topMargin = text === "" ? 0 : Number(text)
                        }
                    }
                    RowLayout {
                        spacing: 10
                        FluText { text: qsTr("下边距"); }
                        FluTextBox {
                            Layout.preferredWidth: 72
                            cleanEnabled: false
                            text: String(root.data[index].customArgs.bottomMargin)
                            validator: IntValidator { bottom: -999999; top: 999999 }
                            onTextEdited: root.data[index].customArgs.bottomMargin = text === "" ? 0 : Number(text)
                        }
                    }
                }
                RowLayout {
                    spacing: 20
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    RowLayout {
                        spacing: 10
                        FluText { text: qsTr("左边距"); }
                        FluTextBox {
                            Layout.preferredWidth: 72
                            cleanEnabled: false
                            text: String(root.data[index].customArgs.leftMargin)
                            validator: IntValidator { bottom: -999999; top: 999999 }
                            onTextEdited: root.data[index].customArgs.leftMargin = text === "" ? 0 : Number(text)
                        }
                    }
                    RowLayout {
                        spacing: 10
                        FluText { text: qsTr("右边距"); }
                        FluTextBox {
                            Layout.preferredWidth: 72
                            cleanEnabled: false
                            text: String(root.data[index].customArgs.rightMargin)
                            validator: IntValidator { bottom: -999999; top: 999999 }
                            onTextEdited: root.data[index].customArgs.rightMargin = text === "" ? 0 : Number(text)
                        }
                    }
                }
                FluText {
                    Layout.topMargin: 6
                    text: "X/Y滑动方向区分"
                }
                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    FluText { text: qsTr("阈值 (px)"); }
                    FluTextBox {
                        Layout.preferredWidth: 72
                        cleanEnabled: false
                        text: root.data[index].customArgs.xyThreshold || root.dataDefaults.xyThreshold
                        validator: IntValidator { bottom: -999999; top: 999999 }
                        onTextEdited: {
                            root.data[index].customArgs.xyThreshold = text === "" ? root.dataDefaults.xyThreshold : Number(text)
                        }
                    }
                }
            }
        }
        onPositiveClicked: {
            if (itemIndex < 0 || itemIndex >= root.data.length)
                return
            root.data.splice(itemIndex, 1)
            console.log("TouchPromote: rule deleted", itemIndex)
        }
    }
    TouchPromoteRuleEditor {
        id: ruleEditor
        scrollToOperationID: 0
        onSave: {
            if (_index !== -1) {
                root.data[_index].rules = model
                root.bumpRulesTick()
            }
        }
        function show(index) {
            _index = index
            model = root.data[index].rules
            open(FluSheetType.Right)
        }
    }
}
