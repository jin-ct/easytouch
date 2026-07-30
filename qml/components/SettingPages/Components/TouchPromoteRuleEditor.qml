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
    Component.onCompleted: root.open(FluSheetType.Right)

    signal save()

    property var model: [
        {
            id: 1,
            operation: 0,
            operationText: "上下滑动",
            arguments: {xyThreshold: 12, flip: false},
            variables: ["up", "down", "dx", "dy", "dt"],
            actions: [
                {
                    id: 1,
                    action: 0,
                    actionText: "鼠标滚轮",
                    priority: 10,
                    executionTiming: 0,
                    requirements: [
                        {variable: "up", logic: 0, value: ""}
                    ],
                    arguments: {
                        enableInertia: true,
                        variableBinding: "dy",
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
                        {variable: "up", logic: 0, value: ""}
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
                        key: Qt.Key_Left,
                        longPress: false,
                        doubleClick: false,
                        variableBinding: "",
                        relativePoint: {x: 0.0, y: 0.0},
                        windowPoint: {x: 0, y: 0},
                        screenPoint: {x: 0, y: 0}
                    }
                },
                {
                    id: 4,
                    action: 3,
                    actionText: "调用外部链接",
                    priority: 10,
                    executionTiming: 0,
                    requirements: [],
                    arguments: {
                        url: ""
                    }
                }
            ]
        },
        {
            id: 2,
            operation: 2,
            operationText: "左右滑动",
            arguments: {xyThreshold: 12},
            variables: ["left", "right", "dx", "dy", "dt"],
            actions: [
                {
                    id: 1,
                    action: 0,
                    actionText: "鼠标点击",
                    priority: 10,
                    executionTiming: 0,
                    requirements: [],
                    arguments: {
                        key: Qt.Key_Left,
                        longPress: false,
                        doubleClick: false,
                        relativePoint: {x: 0.0, y: 0.0},
                        windowPoint: {x: 0, y: 0},
                        screenPoint: {x: 0, y: 0}
                    }
                }
            ]
        },
        {
            id: 3,
            operation: 3,
            operationText: "双指捏合",
            arguments: {fingersNum: 0, maxDistance: 60},
            variables: [],
            actions: [
                {
                    id: 1,
                    action: 0,
                    actionText: "鼠标点击",
                    priority: 10,
                    executionTiming: 0,
                    requirements: [],
                    arguments: {
                        key: Qt.Key_Left,
                        longPress: false,
                        doubleClick: false,
                        relativePoint: {x: 0.0, y: 0.0},
                        windowPoint: {x: 0, y: 0},
                        screenPoint: {x: 0, y: 0}
                    }
                }
            ]
        },
        {
            id: 4,
            operation: 4,
            operationText: "(多指)单击",
            arguments: {closeOnly: false, awayOnly: false},
            variables: [],
            actions: []
        },
        {
            id: 5,
            operation: 4,
            operationText: "(多指)双击",
            arguments: {fingersNum: 1, maxDistance: 60},
            variables: [],
            actions: []
        },
        {
            id: 6,
            operation: 4,
            operationText: "(多指)长按",
            arguments: {fingersNum: 1, maxDistance: 60, minDuration: 200},
            variables: [],
            actions: []
        }
    ]

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
            required property var actions
            property int eventSelected
            id: ruleExpander
            title: id
            expand: true
            controlDelegate: RowLayout {
                width: 260
                FluText {
                    text: qsTr("当")
                    Layout.alignment: Qt.AlignVCenter
                }
                FluComboBox {
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: 120
                    textRole: "text"
                    valueRole: "value"
                    model: ListModel {
                        ListElement { text: "上下滑动"; value: 0 }
                        ListElement { text: "左右滑动"; value: 1 }
                        ListElement { text: "双指捏合"; value: 2 }
                        ListElement { text: "(多指)单击"; value: 3 }
                        ListElement { text: "(多指)双击"; value: 4 }
                        ListElement { text: "(多指)长按"; value: 5 }
                    }
                    Component.onCompleted: {
                        currentIndex = 0
                        ruleExpander.eventSelected = Qt.binding(function () {
                            return currentValue
                        })
                    }
                    onActivated: {
                    }
                }
                FluText {
                    text: qsTr("时触发")
                    Layout.alignment: Qt.AlignVCenter
                }
                Item {Layout.fillWidth: true}
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
                    onClicked: {
                    }
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
                    visible: ruleExpander.eventSelected == 0 || ruleExpander.eventSelected == 1
                    FluCheckBox {
                        text: qsTr("仅限快速滑动 (拨动)")
                    }
                }
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    visible: ruleExpander.eventSelected === 2
                    FluCheckBox {
                        id: event_settings_awayOnly
                        text: qsTr("仅限扩大")
                        onClicked: {
                            if (checked && event_settings_closeOnly.checked)
                                event_settings_closeOnly.checked = false
                        }
                    }
                    FluCheckBox {
                        id: event_settings_closeOnly
                        text: qsTr("仅限缩小")
                        onClicked: {
                            if (checked && event_settings_awayOnly.checked)
                                event_settings_awayOnly.checked = false
                        }
                    }
                }
                ColumnLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    visible: ruleExpander.eventSelected == 3 ||
                             ruleExpander.eventSelected == 4 ||
                             ruleExpander.eventSelected == 5
                    FluComboBox {
                        implicitWidth: 100
                        textRole: "text"
                        valueRole: "value"
                        model: ListModel {
                            ListElement { text: "单指"; value: 1 }
                            ListElement { text: "双指"; value: 2 }
                            ListElement { text: "三指"; value: 3 }
                        }
                    }
                    ShowMoreItem {
                        tip: qsTr("高级选项")
                        ColumnLayout {
                            spacing: 8
                            RowLayout {
                                FluText {
                                    text: qsTr("指间最大距离 (px)")
                                }
                                FluTextBox {
                                    implicitWidth: 60
                                    validator: IntValidator { bottom: 0; top: 99999 }
                                }
                            }
                            RowLayout {
                                visible: ruleExpander.eventSelected == 5
                                FluText {
                                    text: qsTr("最短按压时间 (ms)")
                                }
                                FluTextBox {
                                    implicitWidth: 60
                                    validator: IntValidator { bottom: 0; top: 999 }
                                }
                            }
                        }
                    }
                }
                Rectangle{
                    color: FluTheme.dividerColor
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    height: 1
                }
                RowLayout {
                    FluText {
                        id: action_title
                        text: qsTr("动作")
                        font.pixelSize: 12
                    }
                    FluIconButton {
                        iconSource: FluentIcons.Unknown
                        iconSize: 12
                        implicitHeight: 19
                        implicitWidth: 19
                        horizontalPadding: 3
                        verticalPadding: 3
                        onClicked: {
                            action_toolTip.visible = true
                        }
                        FluTooltip {
                            id: action_toolTip
                            visible: parent.hovered
                            text: qsTr("优先级数字越小则越早执行，若优先级相同则按照标号顺序执行")
                        }
                    }
                    Item {Layout.fillWidth: true}
                    FluButton {
                        implicitHeight: 24
                        text: qsTr("添加动作")
                        font.pixelSize: 12
                    }
                }
                FluFrame {
                    Layout.fillWidth: true
                    height: event_actions.implicitHeight
                    ColumnLayout {
                        id:event_actions
                        anchors.fill: parent
                        Repeater {
                            model: ruleExpander.actions
                            delegate: actionItem
                        }
                    }
                }
            }
        }
    }
    Component {
        id: actionItem
        Item {
            id: actionItemContent
            required property int index
            required property int id
            required property var requirements
            Layout.fillWidth: true
            implicitHeight: action_column.implicitHeight + 20
            Rectangle {
                visible: index !== 0
                color: FluTheme.dividerColor
                height: 1
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
            }
            ColumnLayout {
                id: action_column
                spacing: 8
                anchors {
                    fill: parent
                    margins: 10
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    FluText {
                        id: action_num
                        text: "#" + actionItemContent.id
                    }
                    FluComboBox {
                        implicitWidth: 130
                        textRole: "text"
                        valueRole: "value"
                        model: ListModel {
                            ListElement { text: "鼠标滚轮"; value: 0 }
                            ListElement { text: "模拟键盘"; value: 1 }
                            ListElement { text: "鼠标点击"; value: 2 }
                            ListElement { text: "调用外部链接"; value: 3 }
                        }
                    }
                    Item {Layout.fillWidth: true}
                    RowLayout {
                        spacing: 6
                        FluText {
                            text: qsTr("优先级")
                        }
                        FluTextBox {
                            implicitWidth: 45
                            validator: IntValidator { bottom: 0; top: 99 }
                            cleanEnabled: false
                        }
                    }
                    Item {Layout.fillWidth: true}
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
                            deleteActionDialog.open()
                        }
                    }
                }
                RowLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Layout.leftMargin: action_num.width + 8
                    FluText {
                        text: qsTr("执行时机：")
                    }
                    FluRadioButtons {
                        spacing: 16
                        orientation: Qt.Horizontal
                        FluRadioButton {
                            text: qsTr("按下时")
                        }
                        FluRadioButton {
                            text: qsTr("松开时")
                        }
                    }
                }
                RowLayout {
                    spacing: 4
                    Layout.fillWidth: true
                    Layout.leftMargin: action_num.width + 8
                    FluText {
                        id: action_executionTiming_text
                        text: qsTr("执行条件：")
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: (action_requirements_addBtn.implicitHeight-implicitHeight)/2
                    }
                    ColumnLayout {
                        spacing: 8
                        Repeater {
                            model: actionItemContent.requirements
                            delegate: RowLayout {
                                spacing: 8
                                Layout.fillWidth: true
                                FluComboBox {
                                    implicitWidth: 70
                                    textRole: "text"
                                    valueRole: "value"
                                    model: ListModel {
                                        ListElement { text: "向上"; value: "up" }
                                        ListElement { text: "向下"; value: "down" }
                                        ListElement { text: "Δx"; value: "dx" }
                                        ListElement { text: "Δy"; value: "dy" }
                                    }
                                }
                                FluComboBox {
                                    implicitWidth: 70
                                    textRole: "text"
                                    valueRole: "value"
                                    model: ListModel {
                                        ListElement { text: "为真"; value: 0 }
                                        ListElement { text: "为假"; value: 1 }
                                        ListElement { text: "不等"; value: 2 }
                                        ListElement { text: "等于"; value: 3 }
                                        ListElement { text: ">"; value: 4 }
                                        ListElement { text: "<"; value: 5 }
                                        ListElement { text: ">="; value: 4 }
                                        ListElement { text: "<="; value: 4 }
                                    }
                                }
                                FluTextBox {
                                    implicitWidth: 60
                                    cleanEnabled: false
                                }
                            }
                        }
                        FluIconButton {
                            id: action_requirements_addBtn
                            iconSource: FluentIcons.Add
                            iconSize: 13
                            FluTooltip {
                                visible: parent.hovered
                                text: qsTr("添加条件")
                                delay: 500
                            }
                        }
                    }
                }
                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.leftMargin: action_num.width + 8
                    FluText {
                        text: qsTr("滑动灵敏度：")
                    }
                    FluSlider {
                        padding: 0
                        value:50
                    }
                }
                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    Layout.leftMargin: action_num.width + 8
                    FluText {
                        text: qsTr("惯性灵敏度：")
                    }
                    FluSlider {
                        padding: 0
                        value:50
                    }
                }
            }
        }
    }

    Flickable{
        id: flickable
        clip: true
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: footer.top
            bottomMargin: 10
        }
        ScrollBar.vertical: FluScrollBar {
            id: bar
        }
        boundsBehavior: Flickable.StopAtBounds
        contentHeight: container.height
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
                model: root.model
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
            text: qsTr("添加规则")
            Layout.fillWidth: true
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
                onClicked: root.save()
            }
        }
    }

    FluContentDialog {
        id: deleteRuleDialog
        title: qsTr("删除")
        contentDelegate: Component {
            FluText {
                text: qsTr("确定要删除该项规则吗？")
                topPadding: 4
                leftPadding: 20
                rightPadding: 20
                bottomPadding: 4
            }
        }
        onPositiveClicked: {
            console.log("TouchPromote: rule deleted")
        }
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
            console.log("TouchPromote: action deleted")
        }
    }
}