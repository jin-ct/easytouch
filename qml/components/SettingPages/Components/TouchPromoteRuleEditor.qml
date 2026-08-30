import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../../Control"

FluSheet {
    id: root
    size: 380
    header: null
    closePolicy: Popup.NoAutoClose
    property int _index: -1
    signal save()

    ListModel {
        id: operationTypesModel
        ListElement { text: "上下滑动"; value: 0 }
        ListElement { text: "左右滑动"; value: 1 }
        ListElement { text: "双指捏合"; value: 2 }
        ListElement { text: "(多指)单击"; value: 3 }
        ListElement { text: "(多指)双击"; value: 4 }
        ListElement { text: "(多指)长按"; value: 5 }
    }
    ListModel {
        id: actionTypesModel
        ListElement { text: "鼠标滚轮"; value: 0 }
        ListElement { text: "模拟键盘"; value: 1 }
        ListElement { text: "鼠标点击"; value: 2 }
        ListElement { text: "调用外部链接"; value: 3 }
    }
    ListModel {
        id: fingerCountModel
        ListElement { text: "单指"; value: 1 }
        ListElement { text: "双指"; value: 2 }
        ListElement { text: "三指"; value: 3 }
    }
    ListModel {
        id: requirementLogicModel
        ListElement { text: "为真"; value: 0 }
        ListElement { text: "为假"; value: 1 }
        ListElement { text: "不等"; value: 2 }
        ListElement { text: "等于"; value: 3 }
        ListElement { text: ">"; value: 4 }
        ListElement { text: "<"; value: 5 }
        ListElement { text: ">="; value: 6 }
        ListElement { text: "<="; value: 7 }
    }
    ListModel {
        id: mouseButtonModel
        ListElement { text: "左键"; value: 1 }
        ListElement { text: "右键"; value: 2 }
        ListElement { text: "中键"; value: 4 }
    }

    // ── 元数据（非 ComboBox 绑定） ──
    readonly property var operationMetaMap: ({
        0: { variables: ["up", "down", "dx", "dy", "dt"], defaultArguments: { flip: false } },
        1: { variables: ["left", "right", "dx", "dy", "dt"], defaultArguments: { flip: false } },
        2: { variables: [], defaultArguments: { closeOnly: false, awayOnly: false } },
        3: { variables: [], defaultArguments: { fingersNum: 1, maxDistance: 60 } },
        4: { variables: [], defaultArguments: { fingersNum: 1, maxDistance: 60 } },
        5: { variables: [], defaultArguments: { fingersNum: 1, maxDistance: 60, minDuration: 200 } }
    })
    readonly property var variableLabelMap: ({
        "up": qsTr("向上"), "down": qsTr("向下"),
        "left": qsTr("向左"), "right": qsTr("向右"),
        "dx": "Δx", "dy": "Δy", "dt": "Δt"
    })
    readonly property var wheelParamDefaults: ({
        deltaScale: 3,
        deltaMax: 360,
        velocityThresholdMin: 1.2,
        velocityThresholdMax: 360,
        maxVelocityScale: 0.95,
        velocityScale: 0.9,
        velocityScaleInterval: 12
    })
    // 灵敏度滑块映射比例：50 → 1.0，范围约 0.25x ~ 4.0x
    readonly property real wheelSensitivityMinRatio: 0.20
    readonly property real wheelSensitivityMaxRatio: 2.0

    property int pendingDeleteRuleIndex: -1
    property int pendingDeleteActionRuleIndex: -1
    property int pendingDeleteActionIndex: -1
    property int pendingSwitchOperationRuleIndex: -1
    property int pendingSwitchOperationValue: -1
    property var pendingSwitchOperationCombo: null
    property int pendingSwitchActionRuleIndex: -1
    property int pendingSwitchActionIndex: -1
    property int pendingSwitchActionValue: -1
    property var pendingSwitchActionCombo: null
    property int rulesTick: 0
    property var ruleTicks: ({})
    property var actionTicks: ({})
    property bool scrollToBottomPending: false
    property int scrollToOperationID: 1
    property int scrollToActionID: 1

    Timer {
        id: scrollToDelayTimer
        interval: 500
        repeat: false
        property int operationID: -1
        property int actionID: -1
        onTriggered: {
            if (operationID === -1)
                return
            var item = operationsRepeater.itemAt(operationID - 1)
            if (actionID !== -1) {
                var actionItem = item.actionsRepeater.itemAt(actionID - 1)
                flickable.contentY += actionItem ? actionItem.mapToItem(flickable, 0, 0).y : 0
                operationID = -1
                actionID = -1
                return
            }
            flickable.contentY += item ? item.mapToItem(flickable, 0, 0).y : 0
            operationID = -1
        }
    }

    function scrollToOperation(id) {
        scrollToOperationID = id
        scrollToDelayTimer.operationID = id
        scrollToDelayTimer.start()
    }

    function scrollToAction(operationID, actionID) {
        scrollToOperationID = operationID
        scrollToActionID = actionID
        scrollToDelayTimer.operationID = operationID
        scrollToDelayTimer.actionID = actionID
        scrollToDelayTimer.start()
    }

    function bumpRulesTick() {
        rulesTick++
    }

    function bumpRuleTick(ruleIndex) {
        var ticks = Object.assign({}, ruleTicks)
        ticks[ruleIndex] = (ticks[ruleIndex] || 0) + 1
        ruleTicks = ticks
    }

    function bumpActionsTick(ruleIndex) {
        var ticks = Object.assign({}, actionTicks)
        ticks[ruleIndex] = (ticks[ruleIndex] || 0) + 1
        actionTicks = ticks
    }

    function ruleAt(index) {
        return model[index]
    }

    function actionAt(ruleIndex, actionIndex) {
        return model[ruleIndex].actions[actionIndex]
    }

    function commitIntTo(textBox, target, key, defaultValue) {
        var v = parseIntField(textBox.text, defaultValue)
        target[key] = v
        textBox.text = String(v)
    }

    function commitFloatTo(textBox, target, key, defaultValue) {
        var v = parseFloatField(textBox.text, defaultValue)
        target[key] = v
        textBox.text = String(v)
    }

    function commitNestedInt(textBox, target, nestedKey, key, defaultValue) {
        var v = parseIntField(textBox.text, defaultValue)
        target[nestedKey][key] = v
        textBox.text = String(v)
    }

    function commitNestedFloat(textBox, target, nestedKey, key, defaultValue) {
        var v = parseFloatField(textBox.text, defaultValue)
        target[nestedKey][key] = v
        textBox.text = String(v)
    }

    function cloneObject(obj) {
        return JSON.parse(JSON.stringify(obj))
    }

    function operationMeta(value) {
        return operationMetaMap[value] || operationMetaMap[0]
    }

    function operationText(value) {
        return listModelTextAt(operationTypesModel, comboIndexForListModel(operationTypesModel, value))
    }

    function actionText(value) {
        return listModelTextAt(actionTypesModel, comboIndexForListModel(actionTypesModel, value))
    }

    function listModelTextAt(listModel, index) {
        if (index < 0 || index >= listModel.count)
            return ""
        return listModel.get(index).text
    }

    function comboIndexForListModel(listModel, value) {
        for (var i = 0; i < listModel.count; ++i) {
            if (listModel.get(i).value === value)
                return i
        }
        return 0
    }

    function syncListModelFromVariables(listModel, variables) {
        listModel.clear()
        for (var i = 0; i < variables.length; ++i) {
            var v = variables[i]
            listModel.append({ text: variableLabelMap[v] || v, value: v })
        }
    }

    function parseIntField(text, defaultValue) {
        if (text === undefined || String(text).trim() === "")
            return defaultValue
        var v = parseInt(text)
        return isNaN(v) ? defaultValue : v
    }

    function parseFloatField(text, defaultValue) {
        if (text === undefined || String(text).trim() === "")
            return defaultValue
        var v = parseFloat(text)
        return isNaN(v) ? defaultValue : v
    }

    function wheelRatioFromSlider(slider) {
        return wheelSensitivityMinRatio
                + (slider - 1) / 99 * (wheelSensitivityMaxRatio - wheelSensitivityMinRatio)
    }

    function sliderFromWheelRatio(ratio) {
        ratio = Math.max(wheelSensitivityMinRatio, Math.min(wheelSensitivityMaxRatio, ratio))
        return Math.round(1 + (ratio - wheelSensitivityMinRatio)
                          / (wheelSensitivityMaxRatio - wheelSensitivityMinRatio) * 99)
    }

    function scrollSliderFromArgs(args) {
        if (!args || !wheelParamDefaults.deltaScale)
            return 50
        return sliderFromWheelRatio(args.deltaScale / wheelParamDefaults.deltaScale)
    }

    function inertiaSliderFromArgs(args) {
        if (!args || !wheelParamDefaults.velocityThresholdMax)
            return 50
        return sliderFromWheelRatio(args.velocityThresholdMax / wheelParamDefaults.velocityThresholdMax)
    }

    function applyScrollSensitivity(args, slider) {
        var ratio = wheelRatioFromSlider(slider)
        args.deltaScale = wheelParamDefaults.deltaScale * ratio
        args.deltaMax = Math.round(wheelParamDefaults.deltaMax * ratio)
    }

    function applyInertiaSensitivity(args, slider) {
        var ratio = wheelRatioFromSlider(slider)
        args.velocityThresholdMin = wheelParamDefaults.velocityThresholdMin * ratio
        args.velocityThresholdMax = wheelParamDefaults.velocityThresholdMax * ratio
        args.maxVelocityScale = Math.min(1, wheelParamDefaults.maxVelocityScale * ratio)
        args.velocityScale = wheelParamDefaults.velocityScale * Math.pow(ratio, 0.5)
        args.velocityScaleInterval = Math.max(1, Math.round(wheelParamDefaults.velocityScaleInterval / ratio))
    }

    function touchRules() {
        bumpRulesTick()
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

    function touchActions(ruleIndex) {
        bumpActionsTick(ruleIndex)
    }

    function defaultWheelArguments() {
        return cloneObject(wheelParamDefaults)
    }

    function defaultActionArguments(actionType) {
        switch (actionType) {
        case 0:
            return Object.assign({ enableInertia: true }, defaultWheelArguments())
        case 1:
            return { keys: [], longPress: false }
        case 2:
            return {
                key: Qt.LeftButton,
                longPress: false,
                doubleClick: false,
                relativePoint: { x: 0.0, y: 0.0 },
                windowPoint: { x: 0, y: 0 },
                screenPoint: { x: 0, y: 0 }
            }
        case 3:
            return { url: "" }
        default:
            return {}
        }
    }

    function createAction(actionType) {
        return {
            id: 1,
            action: actionType,
            actionText: actionText(actionType),
            priority: 10,
            executionTiming: 0,
            requirements: [],
            arguments: defaultActionArguments(actionType),
            _isNew: true
        }
    }

    function renumberRules() {
        for (var i = 0; i < model.length; ++i)
            model[i].id = i + 1
    }

    function renumberActions(actions) {
        for (var i = 0; i < actions.length; ++i)
            actions[i].id = i + 1
    }

    function applyRuleOperation(ruleIndex, operationValue) {
        var meta = operationMeta(operationValue)
        var rule = model[ruleIndex]
        rule.operation = operationValue
        rule.operationText = operationText(operationValue)
        rule.variables = meta.variables.slice()
        rule.arguments = cloneObject(meta.defaultArguments)
        rule._isNew = false
        bumpRuleTick(ruleIndex)
    }

    function requestRuleOperationChange(ruleIndex, operationValue, combo) {
        var rule = model[ruleIndex]
        if (operationValue === rule.operation)
            return
        if (rule._isNew) {
            applyRuleOperation(ruleIndex, operationValue)
            return
        }
        pendingSwitchOperationRuleIndex = ruleIndex
        pendingSwitchOperationValue = operationValue
        pendingSwitchOperationCombo = combo
        switchOperationDialog.open()
    }

    function revertOperationCombo() {
        if (!pendingSwitchOperationCombo || pendingSwitchOperationRuleIndex < 0)
            return
        var rule = model[pendingSwitchOperationRuleIndex]
        pendingSwitchOperationCombo.currentIndex = comboIndexForListModel(
            operationTypesModel, rule.operation)
    }

    function setRuleOperation(ruleIndex, operationValue) {
        applyRuleOperation(ruleIndex, operationValue)
    }

    function addRule() {
        var operationValue = operationTypesModel.get(0).value
        var meta = operationMeta(operationValue)
        model.push({
            id: model.length + 1,
            operation: operationValue,
            operationText: operationText(operationValue),
            arguments: cloneObject(meta.defaultArguments),
            variables: meta.variables.slice(),
            actions: [],
            _isNew: true
        })
        renumberRules()
        touchRules()
        scrollToBottom()
    }

    function copyRule(ruleIndex) {
        var copy = cloneObject(model[ruleIndex])
        copy._isNew = false
        for (var i = 0; i < copy.actions.length; ++i)
            copy.actions[i]._isNew = false
        model.push(copy)
        renumberRules()
        renumberActions(copy.actions)
        touchRules()
        scrollToBottom()
    }

    function deleteRule(ruleIndex) {
        if (ruleIndex < 0 || ruleIndex >= model.length)
            return
        model.splice(ruleIndex, 1)
        renumberRules()
        touchRules()
    }

    function addAction(ruleIndex) {
        model[ruleIndex].actions.push(createAction(0))
        renumberActions(model[ruleIndex].actions)
        bumpActionsTick(ruleIndex)
    }

    function deleteAction(ruleIndex, actionIndex) {
        var actions = model[ruleIndex].actions
        if (actionIndex < 0 || actionIndex >= actions.length)
            return
        actions.splice(actionIndex, 1)
        renumberActions(actions)
        bumpActionsTick(ruleIndex)
    }

    function applyActionType(ruleIndex, actionIndex, actionValue) {
        var action = model[ruleIndex].actions[actionIndex]
        action.action = actionValue
        action.actionText = actionText(actionValue)
        action.arguments = defaultActionArguments(actionValue)
        action._isNew = false
        model[ruleIndex].actions[actionIndex] = action
        bumpActionsTick(ruleIndex)
    }

    function requestActionTypeChange(ruleIndex, actionIndex, actionValue, combo) {
        var action = model[ruleIndex].actions[actionIndex]
        if (actionValue === action.action)
            return
        if (action._isNew) {
            applyActionType(ruleIndex, actionIndex, actionValue)
            return
        }
        pendingSwitchActionRuleIndex = ruleIndex
        pendingSwitchActionIndex = actionIndex
        pendingSwitchActionValue = actionValue
        pendingSwitchActionCombo = combo
        switchActionDialog.open()
    }

    function revertActionCombo() {
        if (!pendingSwitchActionCombo || pendingSwitchActionRuleIndex < 0 || pendingSwitchActionIndex < 0)
            return
        var action = model[pendingSwitchActionRuleIndex].actions[pendingSwitchActionIndex]
        pendingSwitchActionCombo.currentIndex = comboIndexForListModel(actionTypesModel, action.action)
    }

    function setActionType(ruleIndex, actionIndex, actionValue) {
        applyActionType(ruleIndex, actionIndex, actionValue)
    }

    function clearActionRequirements(ruleIndex, actionIndex) {
        model[ruleIndex].actions[actionIndex].requirements = []
        bumpActionsTick(ruleIndex)
    }

    property var model: []

    Item {
        id: header
        implicitHeight: 40
        FluText {
            text: qsTr("规则编辑")
            font.pixelSize: 20
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
        }
    }

    Component {
        id: ruleItem
        SettingItemExpander {
            required property int id
            required property int index
            required property int operation
            required property var arguments
            required property var variables
            required property var actions

            property alias actionsRepeater: actions_repeater

            id: ruleExpander
            title: String(id)
            expand: {
                var tick = root.rulesTick
                return root.model[index]._isNew === true || root.scrollToOperationID === index + 1
            }

            readonly property int liveOperation: {
                var tick = root.ruleTicks[index] || 0
                return root.model[index].operation
            }
            readonly property var liveArguments: {
                var tick = root.ruleTicks[index] || 0
                return root.model[index].arguments
            }

            controlDelegate: RowLayout {
                width: 260
                FluText {
                    text: qsTr("当")
                    Layout.alignment: Qt.AlignVCenter
                }
                FluComboBox {
                    id: operationCombo
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 120
                    textRole: "text"
                    valueRole: "value"
                    model: operationTypesModel
                    currentIndex: comboIndexForListModel(operationTypesModel, ruleExpander.liveOperation)
                    onActivated: requestRuleOperationChange(ruleExpander.index, currentValue, operationCombo)
                }
                FluText {
                    text: qsTr("时触发")
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                FluIconButton {
                    Layout.alignment: Qt.AlignVCenter
                    iconSource: FluentIcons.Delete
                    iconSize: 15
                    FluTooltip {
                        visible: parent.hovered
                        text: qsTr("删除")
                        delay: 500
                    }
                    onClicked: {
                        pendingDeleteRuleIndex = ruleExpander.index
                        deleteRuleDialog.open()
                    }
                }
                FluIconButton {
                    Layout.alignment: Qt.AlignVCenter
                    iconSource: FluentIcons.Copy
                    iconSize: 15
                    FluTooltip {
                        visible: parent.hovered
                        text: qsTr("复制")
                        delay: 500
                    }
                    onClicked: copyRule(ruleExpander.index)
                }
            }

            contentHeight: subItem.implicitHeight + 20
            ColumnLayout {
                id: subItem
                clip: true
                spacing: 8
                anchors.fill: parent
                anchors.margins: 10

                FluText {
                    text: qsTr("设置")
                    font.pixelSize: 12
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    visible: ruleExpander.liveOperation === 0 || ruleExpander.liveOperation === 1
                    FluCheckBox {
                        text: qsTr("仅限快速滑动 (拨动)")
                        checked: ruleExpander.liveArguments.flip || false
                        onToggled: root.model[ruleExpander.index].arguments.flip = checked
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    visible: ruleExpander.liveOperation === 2
                    FluCheckBox {
                        text: qsTr("仅限扩大")
                        checked: ruleExpander.liveArguments.awayOnly || false
                        onToggled: {
                            root.model[ruleExpander.index].arguments.awayOnly = checked
                            if (checked)
                                root.model[ruleExpander.index].arguments.closeOnly = false
                        }
                    }
                    FluCheckBox {
                        text: qsTr("仅限缩小")
                        checked: ruleExpander.liveArguments.closeOnly || false
                        onToggled: {
                            root.model[ruleExpander.index].arguments.closeOnly = checked
                            if (checked)
                                root.model[ruleExpander.index].arguments.awayOnly = false
                        }
                    }
                }

                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    visible: ruleExpander.liveOperation === 3 || ruleExpander.liveOperation === 4 || ruleExpander.liveOperation === 5
                    RowLayout {
                        spacing: 8
                        FluText { text: qsTr("手指数") }
                        FluComboBox {
                            implicitWidth: 100
                            textRole: "text"
                            valueRole: "value"
                            model: fingerCountModel
                            currentIndex: comboIndexForListModel(fingerCountModel, ruleExpander.liveArguments.fingersNum || 1)
                            onActivated: root.model[ruleExpander.index].arguments.fingersNum = currentValue
                        }
                    }
                    ShowMoreItem {
                        tip: qsTr("高级选项")
                        ColumnLayout {
                            spacing: 8
                            RowLayout {
                                FluText { text: qsTr("指间最大距离 (px)") }
                                FluIconButton {
                                    iconSource: FluentIcons.Unknown
                                    iconSize: 11
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    horizontalPadding: 2
                                    verticalPadding: 2
                                    FluTooltip {
                                        visible: parent.hovered
                                        text: qsTr("多指间允许的最大距离")
                                        delay: 300
                                    }
                                }
                                FluTextBox {
                                    implicitWidth: 60
                                    cleanEnabled: false
                                    text: String(ruleExpander.liveArguments.maxDistance)
                                    validator: IntValidator { bottom: 0; top: 99999 }
                                    onTextEdited: commitIntTo(
                                        this, root.model[ruleExpander.index].arguments, "maxDistance",
                                        operationMeta(ruleExpander.liveOperation).defaultArguments.maxDistance)
                                }
                            }
                            RowLayout {
                                visible: ruleExpander.liveOperation === 5
                                FluText { text: qsTr("最短按压时间 (ms)") }
                                FluTextBox {
                                    implicitWidth: 60
                                    cleanEnabled: false
                                    text: String(ruleExpander.liveArguments.minDuration)
                                    validator: IntValidator { bottom: 0; top: 99999 }
                                    onTextEdited: commitIntTo(
                                        this, root.model[ruleExpander.index].arguments, "minDuration",
                                        operationMeta(5).defaultArguments.minDuration)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    color: FluTheme.dividerColor
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    height: 1
                }

                RowLayout {
                    FluText {
                        text: qsTr("动作")
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                }

                Component {
                    id: actionItem
                    ColumnLayout {
                        id: actionItem_content
                        required property int index
                        property int ruleIndex: ruleExpander.index
                        readonly property int contentIndent: 40
                        readonly property var act: {
                            var tick = root.actionTicks[ruleIndex] || 0
                            return root.model[ruleIndex].actions[index]
                        }
                        readonly property var args: act.arguments
                        readonly property var ruleVariables: root.model[ruleIndex].variables
                        readonly property int liveAction: {
                            var tick = root.actionTicks[ruleIndex] || 0
                            return act.action
                        }

                        Layout.fillWidth: true
                        Layout.topMargin: index === 0 ? 0 : 8
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            FluText {
                                id: action_num
                                Layout.minimumWidth: 28
                                text: "#" + act.id
                            }
                            FluComboBox {
                                id: actionTypeCombo
                                implicitWidth: 128
                                textRole: "text"
                                valueRole: "value"
                                model: actionTypesModel
                                currentIndex: comboIndexForListModel(actionTypesModel, liveAction)
                                onActivated: requestActionTypeChange(ruleIndex, actionItem_content.index, currentValue, actionTypeCombo)
                            }
                            Item { Layout.fillWidth: true }
                            RowLayout {
                                spacing: 1
                                FluText { text: qsTr("优先级") }
                                FluIconButton {
                                    iconSource: FluentIcons.Unknown
                                    iconSize: 12
                                    implicitHeight: 19
                                    implicitWidth: 19
                                    horizontalPadding: 3
                                    verticalPadding: 3
                                    FluTooltip {
                                        visible: parent.hovered
                                        text: qsTr("优先级数字越大则越早执行，若优先级相同则按照标号顺序执行")
                                    }
                                }
                                FluTextBox {
                                    implicitWidth: 45
                                    cleanEnabled: false
                                    text: String(act.priority)
                                    validator: IntValidator { bottom: 0; top: 99 }
                                    onTextEdited: commitIntTo(this, act, "priority", 10)
                                }
                            }
                            FluIconButton {
                                Layout.alignment: Qt.AlignVCenter
                                iconSource: FluentIcons.Cancel
                                iconSize: 15
                                FluTooltip {
                                    visible: parent.hovered
                                    text: qsTr("删除")
                                    delay: 500
                                }
                                onClicked: {
                                    pendingDeleteActionRuleIndex = ruleIndex
                                    pendingDeleteActionIndex = index
                                    deleteActionDialog.open()
                                }
                            }
                        }

                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true
                            Layout.leftMargin: contentIndent
                            FluText { text: qsTr("执行时机：") }
                            ButtonGroup { id: executionTimingGroup }
                            FluRadioButton {
                                text: qsTr("按下时")
                                ButtonGroup.group: executionTimingGroup
                                checked: act.executionTiming === 0
                                onToggled: { if (checked) act.executionTiming = 0 }
                            }
                            FluRadioButton {
                                text: qsTr("手指离开时")
                                ButtonGroup.group: executionTimingGroup
                                checked: act.executionTiming === 1
                                onToggled: { if (checked) act.executionTiming = 1 }
                            }
                        }

                        ColumnLayout {
                            spacing: 8
                            Layout.fillWidth: true
                            Layout.leftMargin: contentIndent
                            visible: ruleVariables.length > 0

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                FluText { text: qsTr("执行条件：") }
                                FluIconButton {
                                    iconSource: FluentIcons.Add
                                    iconSize: 13
                                    FluTooltip {
                                        visible: parent.hovered
                                        text: qsTr("添加条件")
                                        delay: 500
                                    }
                                    onClicked: {
                                        act.requirements.push({
                                            variable: ruleVariables[0] || "up",
                                            logic: 0,
                                            value: ""
                                        })
                                        bumpActionsTick(ruleIndex)
                                    }
                                }
                                FluIconButton {
                                    iconSource: FluentIcons.Delete
                                    iconSize: 13
                                    FluTooltip {
                                        visible: parent.hovered
                                        text: qsTr("清空条件")
                                        delay: 500
                                    }
                                    visible: act.requirements.length > 0
                                    onClicked: clearActionRequirements(ruleIndex, index)
                                }
                            }

                            Repeater {
                                model: {
                                    var tick = root.actionTicks[ruleIndex] || 0
                                    return act.requirements
                                }
                                delegate: RowLayout {
                                    id: requirementItem
                                    required property int index
                                    required property string variable
                                    required property int logic
                                    required property string value

                                    spacing: 8
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 8

                                    ListModel { id: reqVariableModel }
                                    Component.onCompleted: syncListModelFromVariables(reqVariableModel, ruleVariables)

                                    FluComboBox {
                                        implicitWidth: 70
                                        textRole: "text"
                                        valueRole: "value"
                                        model: reqVariableModel
                                        currentIndex: comboIndexForListModel(reqVariableModel, variable)
                                        onActivated: {
                                            act.requirements[requirementItem.index].variable = currentValue
                                            bumpActionsTick(ruleIndex)
                                        }
                                    }
                                    FluComboBox {
                                        implicitWidth: 70
                                        textRole: "text"
                                        valueRole: "value"
                                        model: requirementLogicModel
                                        currentIndex: comboIndexForListModel(requirementLogicModel, logic)
                                        onActivated: {
                                            act.requirements[requirementItem.index].logic = currentValue
                                            if (currentValue === 0 || currentValue === 1)
                                                act.requirements[requirementItem.index].value = ""
                                            bumpActionsTick(ruleIndex)
                                        }
                                    }
                                    FluTextBox {
                                        implicitWidth: 60
                                        cleanEnabled: false
                                        text: act.requirements[index].value
                                        visible: act.requirements[index].logic !== 0 && act.requirements[index].logic !== 1
                                        onTextEdited: act.requirements[index].value = text
                                    }
                                    FluIconButton {
                                        iconSource: FluentIcons.Cancel
                                        iconSize: 12
                                        onClicked: {
                                            act.requirements.splice(index, 1)
                                            bumpActionsTick(ruleIndex)
                                        }
                                    }
                                }
                            }
                        }

                        Loader {
                            Layout.fillWidth: true
                            Layout.leftMargin: contentIndent
                            property int parentRuleIndex: ruleIndex
                            property int parentActionIndex: index
                            property int refreshKey: {
                                var tick = root.actionTicks[ruleIndex] || 0
                                return tick * 10 + liveAction
                            }
                            sourceComponent: {
                                var key = refreshKey
                                switch (liveAction) {
                                case 0: return wheelParamsPanel
                                case 1: return keyboardParamsPanel
                                case 2: return clickParamsPanel
                                case 3: return urlParamsPanel
                                default: return null
                                }
                            }
                            onLoaded: {
                                if (item) {
                                    item.ruleIndex = parentRuleIndex
                                    item.actionIndex = parentActionIndex
                                }
                            }
                            onItemChanged: {
                                if (item) {
                                    item.ruleIndex = parentRuleIndex
                                    item.actionIndex = parentActionIndex
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 0
                            height: 1
                            color: FluTheme.dividerColor
                        }
                    }
                }

                FluFrame {
                    Layout.fillWidth: true
                    implicitHeight: event_actions.implicitHeight + 16
                    ColumnLayout {
                        id: event_actions
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 0

                        Repeater {
                            id: actions_repeater
                            model: {
                                var tick = root.actionTicks[ruleExpander.index] || 0
                                return root.model[ruleExpander.index].actions
                            }
                            delegate: actionItem
                        }

                        FluTextButton {
                            text: qsTr("添加动作")
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: {
                                var tick = root.actionTicks[ruleExpander.index] || 0
                                return root.model[ruleExpander.index].actions.length > 0 ? 6 : 0
                            }
                            onClicked: root.addAction(ruleExpander.index)
                        }
                    }
                }
            }

            Component {
                id: wheelParamsPanel
                ColumnLayout {
                    property int ruleIndex
                    property int actionIndex
                    readonly property var args: {
                        var tick = root.actionTicks[ruleIndex] || 0
                        var action = root.model[ruleIndex].actions[actionIndex]
                        return action ? action.arguments : ({})
                    }

                    spacing: 6
                    Layout.fillWidth: true

                    FluCheckBox {
                        text: qsTr("启用惯性滚动")
                        checked: args.enableInertia || false
                        onToggled: args.enableInertia = checked
                    }
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        FluText { text: qsTr("滑动灵敏度：") }
                        FluSlider {
                            Layout.fillWidth: true
                            padding: 3
                            from: 1
                            to: 100
                            stepSize: 1
                            value: scrollSliderFromArgs(args)
                            onMoved: applyScrollSensitivity(args, value)
                            onPressedChanged: if (!pressed) applyScrollSensitivity(args, value)
                        }
                    }
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        FluText { text: qsTr("惯性灵敏度：") }
                        FluSlider {
                            Layout.fillWidth: true
                            padding: 3
                            from: 1
                            to: 100
                            stepSize: 1
                            value: inertiaSliderFromArgs(args)
                            onMoved: applyInertiaSensitivity(args, value)
                            onPressedChanged: if (!pressed) applyInertiaSensitivity(args, value)
                        }
                    }
                    ShowMoreItem {
                        tip: qsTr("滚轮高级参数")
                        ColumnLayout {
                            spacing: 6
                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluText { text: qsTr("滚动量/dy"); Layout.preferredWidth: 130 }
                                FluTextBox {
                                    id: deltaScaleBox
                                    Layout.preferredWidth: 72
                                    cleanEnabled: false
                                    text: String(args.deltaScale)
                                    validator: DoubleValidator { bottom: -999999; top: 999999; decimals: 2 }
                                    onTextEdited: commitFloatTo(deltaScaleBox, args, "deltaScale", wheelParamDefaults.deltaScale)
                                }
                            }
                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluText { text: qsTr("最大滚动量"); Layout.preferredWidth: 130 }
                                FluTextBox {
                                    id: deltaMaxBox
                                    Layout.preferredWidth: 72
                                    cleanEnabled: false
                                    text: String(args.deltaMax)
                                    validator: IntValidator { bottom: 0; top: 999999 }
                                    onTextEdited: commitIntTo(deltaMaxBox, args, "deltaMax", wheelParamDefaults.deltaMax)
                                }
                            }
                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluText { text: qsTr("惯性最小速度"); Layout.preferredWidth: 130 }
                                FluTextBox {
                                    id: velMinBox
                                    Layout.preferredWidth: 72
                                    cleanEnabled: false
                                    text: String(args.velocityThresholdMin)
                                    validator: DoubleValidator { bottom: -999999; top: 999999; decimals: 2 }
                                    onTextEdited: commitFloatTo(velMinBox, args, "velocityThresholdMin", wheelParamDefaults.velocityThresholdMin)
                                }
                            }
                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluText { text: qsTr("惯性最大速度"); Layout.preferredWidth: 130 }
                                FluTextBox {
                                    id: velMaxBox
                                    Layout.preferredWidth: 72
                                    cleanEnabled: false
                                    text: String(args.velocityThresholdMax)
                                    validator: DoubleValidator { bottom: -999999; top: 999999; decimals: 2 }
                                    onTextEdited: commitFloatTo(velMaxBox, args, "velocityThresholdMax", wheelParamDefaults.velocityThresholdMax)
                                }
                            }
                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluText { text: qsTr("惯性初始速度缩放"); Layout.preferredWidth: 130 }
                                FluTextBox {
                                    id: maxVelScaleBox
                                    Layout.preferredWidth: 72
                                    cleanEnabled: false
                                    text: String(args.maxVelocityScale)
                                    validator: DoubleValidator { bottom: -999999; top: 999999; decimals: 3 }
                                    onTextEdited: commitFloatTo(maxVelScaleBox, args, "maxVelocityScale", wheelParamDefaults.maxVelocityScale)
                                }
                            }
                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluText { text: qsTr("惯性周期减小速度"); Layout.preferredWidth: 130 }
                                FluTextBox {
                                    id: velScaleBox
                                    Layout.preferredWidth: 72
                                    cleanEnabled: false
                                    text: String(args.velocityScale)
                                    validator: DoubleValidator { bottom: -999999; top: 999999; decimals: 3 }
                                    onTextEdited: commitFloatTo(velScaleBox, args, "velocityScale", wheelParamDefaults.velocityScale)
                                }
                            }
                            RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluText { text: qsTr("惯性减速周期"); Layout.preferredWidth: 130 }
                                FluTextBox {
                                    id: velIntervalBox
                                    Layout.preferredWidth: 72
                                    cleanEnabled: false
                                    text: String(args.velocityScaleInterval)
                                    validator: IntValidator { bottom: 0; top: 999999 }
                                    onTextEdited: commitIntTo(velIntervalBox, args, "velocityScaleInterval", wheelParamDefaults.velocityScaleInterval)
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: keyboardParamsPanel
                ColumnLayout {
                    property int ruleIndex
                    property int actionIndex
                    readonly property var args: {
                        var tick = root.actionTicks[ruleIndex] || 0
                        var action = root.model[ruleIndex].actions[actionIndex]
                        return action ? action.arguments : ({})
                    }
                    spacing: 6
                    Layout.fillWidth: true
                    FluCheckBox {
                        text: qsTr("长按至手指离开屏幕")
                        checked: args.longPress || false
                        onToggled: args.longPress = checked
                    }
                    RowLayout {
                        spacing: 8
                        Layout.fillWidth: true
                        FluText { text: qsTr("按键"); }
                        KeyCollector {
                            currentVals: args.keys || []
                            onAccepted: {
                                args.keys = currentVals
                            }
                        }
                    }
                }
            }

            Component {
                id: clickParamsPanel
                ColumnLayout {
                    property int ruleIndex
                    property int actionIndex
                    readonly property var args: {
                        var tick = root.actionTicks[ruleIndex] || 0
                        var action = root.model[ruleIndex].actions[actionIndex]
                        return action ? action.arguments : ({})
                    }

                    spacing: 6
                    Layout.fillWidth: true
                    RowLayout {
                        spacing: 10
                        FluCheckBox {
                            text: qsTr("长按至手指离开屏幕")
                            checked: args.longPress || false
                            onToggled: args.longPress = checked
                        }
                        FluCheckBox {
                            text: qsTr("双击")
                            checked: args.doubleClick || false
                            onToggled: args.doubleClick = checked
                        }
                    }
                    RowLayout {
                        spacing: 8
                        FluText { text: qsTr("鼠标按键") }
                        FluComboBox {
                            implicitWidth: 90
                            textRole: "text"
                            valueRole: "value"
                            model: mouseButtonModel
                            currentIndex: comboIndexForListModel(mouseButtonModel, args.key)
                            onActivated: args.key = currentValue
                        }
                    }
                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        RowLayout {
                            spacing: 4
                            FluText { text: qsTr("相对坐标") }
                            FluIconButton {
                                iconSource: FluentIcons.Unknown
                                iconSize: 11
                                implicitWidth: 18
                                implicitHeight: 18
                                horizontalPadding: 2
                                verticalPadding: 2
                                FluTooltip {
                                    visible: parent.hovered
                                    text: qsTr("以目标窗口左上角为原点，右下角为 (1, 1) 的相对坐标，设为 (-1, -1) 时表示不使用该坐标系")
                                    delay: 300
                                }
                            }
                        }
                        RowLayout {
                            spacing: 8
                            Layout.leftMargin: 6
                            FluText { text: "X" }
                            FluTextBox {
                                id: relXBox
                                Layout.preferredWidth: 64
                                cleanEnabled: false
                                text: String(args.relativePoint.x || 0.0)
                                validator: DoubleValidator { bottom: -1; top: 1; decimals: 4 }
                                property var commitFunction: function() {
                                    root.commitNestedFloat(relXBox, args, "relativePoint", "x", 0.0)
                                }
                                Component.onCompleted: Global.mouseHook.mousePressed.connect(commitFunction)
                                Component.onDestruction: Global.mouseHook.mousePressed.disconnect(commitFunction) 
                            }
                            FluText { text: "Y" }
                            FluTextBox {
                                id: relYBox
                                Layout.preferredWidth: 64
                                cleanEnabled: false
                                text: String(args.relativePoint.y || 0.0)
                                validator: DoubleValidator { bottom: -1; top: 1; decimals: 4 }
                                property var commitFunction: function() {
                                    root.commitNestedFloat(relYBox, args, "relativePoint", "y", 0.0)
                                }
                                Component.onCompleted: Global.mouseHook.mousePressed.connect(commitFunction)
                                Component.onDestruction: Global.mouseHook.mousePressed.disconnect(commitFunction) 
                            }
                        }
                    }
                    ShowMoreItem {
                        tip: qsTr("其他坐标系")
                        ColumnLayout {
                            spacing: 8
                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                RowLayout {
                                    spacing: 4
                                    FluText { text: qsTr("窗口坐标") }
                                    FluIconButton {
                                        iconSource: FluentIcons.Unknown
                                        iconSize: 11
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        horizontalPadding: 2
                                        verticalPadding: 2
                                        FluTooltip {
                                            visible: parent.hovered
                                            text: qsTr("目标窗口客户区内的像素坐标，设为 (-1, -1) 时表示不使用该坐标系")
                                            delay: 300
                                        }
                                    }
                                }
                                RowLayout {
                                    spacing: 8
                                    Layout.leftMargin: 6
                                    FluText { text: "X" }
                                    FluTextBox {
                                        id: winXBox
                                        Layout.preferredWidth: 64
                                        cleanEnabled: false
                                        text: String(args.windowPoint.x || 0)
                                        validator: IntValidator { bottom: -1; top: 99999 }
                                        property var commitFunction: function() {
                                            root.commitNestedInt(winXBox, args, "windowPoint", "x", 0)
                                        }
                                        Component.onCompleted: Global.mouseHook.mousePressed.connect(commitFunction)
                                        Component.onDestruction: Global.mouseHook.mousePressed.disconnect(commitFunction) 
                                    }
                                    FluText { text: "Y" }
                                    FluTextBox {
                                        id: winYBox
                                        Layout.preferredWidth: 64
                                        cleanEnabled: false
                                        text: String(args.windowPoint.y || 0)
                                        validator: IntValidator { bottom: -1; top: 99999 }
                                        property var commitFunction: function() {
                                            root.commitNestedInt(winYBox, args, "windowPoint", "y", 0)
                                        }
                                        Component.onCompleted: Global.mouseHook.mousePressed.connect(commitFunction)
                                        Component.onDestruction: Global.mouseHook.mousePressed.disconnect(commitFunction) 
                                    }
                                }
                            }
                            ColumnLayout {
                                spacing: 4
                                Layout.fillWidth: true
                                RowLayout {
                                    spacing: 4
                                    FluText { text: qsTr("屏幕坐标") }
                                    FluIconButton {
                                        iconSource: FluentIcons.Unknown
                                        iconSize: 11
                                        implicitWidth: 18
                                        implicitHeight: 18
                                        horizontalPadding: 2
                                        verticalPadding: 2
                                        FluTooltip {
                                            visible: parent.hovered
                                            text: qsTr("屏幕全局坐标系中的像素坐标，设为 (-1, -1) 时表示不使用该坐标系")
                                            delay: 300
                                        }
                                    }
                                }
                                RowLayout {
                                    spacing: 8
                                    Layout.leftMargin: 6
                                    FluText { text: "X" }
                                    FluTextBox {
                                        id: scrXBox
                                        Layout.preferredWidth: 64
                                        cleanEnabled: false
                                        text: String(args.screenPoint.x || 0)
                                        validator: IntValidator { bottom: -1; top: 99999 }
                                        property var commitFunction: function() {
                                            root.commitNestedInt(scrXBox, args, "screenPoint", "x", 0)
                                        }
                                        Component.onCompleted: Global.mouseHook.mousePressed.connect(commitFunction)
                                        Component.onDestruction: Global.mouseHook.mousePressed.disconnect(commitFunction) 
                                    }
                                    FluText { text: "Y" }
                                    FluTextBox {
                                        id: scrYBox
                                        Layout.preferredWidth: 64
                                        cleanEnabled: false
                                        text: String(args.screenPoint.y || 0)
                                        validator: IntValidator { bottom: -1; top: 99999 }
                                        property var commitFunction: function() {
                                            root.commitNestedInt(scrYBox, args, "screenPoint", "y", 0)
                                        }
                                        Component.onCompleted: Global.mouseHook.mousePressed.connect(commitFunction)
                                        Component.onDestruction: Global.mouseHook.mousePressed.disconnect(commitFunction) 
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: urlParamsPanel
                RowLayout {
                    property int ruleIndex
                    property int actionIndex
                    readonly property var args: {
                        var tick = root.actionTicks[ruleIndex] || 0
                        var action = root.model[ruleIndex].actions[actionIndex]
                        return action ? action.arguments : ({})
                    }

                    spacing: 8
                    Layout.fillWidth: true
                    FluText { text: qsTr("链接地址") }
                    FluTextBox {
                        id: urlBox
                        Layout.fillWidth: true
                        cleanEnabled: false
                        text: args.url || ""
                        placeholderText: ""
                        onTextEdited: {
                            args.url = urlBox.text.trim() === "" ? "" : urlBox.text
                            urlBox.text = args.url
                        }
                    }
                }
            }
        }
    }

    Flickable {
        id: flickable
        clip: true
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: footer.top
            bottomMargin: 10
        }
        ScrollBar.vertical: FluScrollBar { id: bar }
        boundsBehavior: Flickable.StopAtBounds
        contentHeight: container.height
        onContentHeightChanged: {
            if (scrollToBottomPending) {
                applyScrollToBottom()
                scrollToBottomDebounce.restart()
            }
        }
        bottomMargin: 10
        ColumnLayout {
            id: container
            spacing: 6
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 10
                topMargin: 2
                rightMargin: 12
            }
            Repeater {
                id: operationsRepeater
                model: {
                    var tick = root.rulesTick
                    return root.model
                }
                delegate: ruleItem
            }
        }
    }

    ColumnLayout {
        id: footer
        spacing: 10
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        FluButton {
            text: qsTr("添加手势")
            Layout.fillWidth: true
            onClicked: addRule()
        }
        RowLayout {
            spacing: 10
            FluButton {
                text: qsTr("取消")
                Layout.fillWidth: true
                onClicked: root.close()
            }
            FluFilledButton {
                text: qsTr("确定")
                Layout.fillWidth: true
                onClicked: {
                    root.save()
                    root.close()
                }
            }
        }
    }

    FluContentDialog {
        id: switchOperationDialog
        title: qsTr("切换手势类型")
        contentDelegate: Component {
            FluText {
                text: qsTr("切换手势类型将清空当前设置（不清空动作），是否继续？")
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
                wrapMode: Text.Wrap
            }
        }
        onPositiveClicked: {
            applyRuleOperation(pendingSwitchOperationRuleIndex, pendingSwitchOperationValue)
            pendingSwitchOperationRuleIndex = -1
            pendingSwitchOperationValue = -1
            pendingSwitchOperationCombo = null
        }
        onNegativeClicked: {
            revertOperationCombo()
            pendingSwitchOperationRuleIndex = -1
            pendingSwitchOperationValue = -1
            pendingSwitchOperationCombo = null
        }
    }

    FluContentDialog {
        id: switchActionDialog
        title: qsTr("切换动作类型")
        contentDelegate: Component {
            FluText {
                text: qsTr("切换动作类型将清空当前参数，是否继续？")
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
                wrapMode: Text.Wrap
            }
        }
        onPositiveClicked: {
            applyActionType(pendingSwitchActionRuleIndex, pendingSwitchActionIndex, pendingSwitchActionValue)
            pendingSwitchActionRuleIndex = -1
            pendingSwitchActionIndex = -1
            pendingSwitchActionValue = -1
            pendingSwitchActionCombo = null
        }
        onNegativeClicked: {
            revertActionCombo()
            pendingSwitchActionRuleIndex = -1
            pendingSwitchActionIndex = -1
            pendingSwitchActionValue = -1
            pendingSwitchActionCombo = null
        }
    }

    FluContentDialog {
        id: deleteRuleDialog
        title: qsTr("删除")
        contentDelegate: Component {
            FluText {
                text: qsTr("所有数据将会被清空，确定要删除该项手势吗？")
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
            }
        }
        onPositiveClicked: {
            deleteRule(pendingDeleteRuleIndex)
            pendingDeleteRuleIndex = -1
        }
        onNegativeClicked: pendingDeleteRuleIndex = -1
    }

    FluContentDialog {
        id: deleteActionDialog
        title: qsTr("删除")
        contentDelegate: Component {
            FluText {
                text: qsTr("确定要删除该项动作吗？")
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
            }
        }
        onPositiveClicked: {
            deleteAction(pendingDeleteActionRuleIndex, pendingDeleteActionIndex)
            pendingDeleteActionRuleIndex = -1
            pendingDeleteActionIndex = -1
        }
        onNegativeClicked: {
            pendingDeleteActionRuleIndex = -1
            pendingDeleteActionIndex = -1
        }
    }
}
