import QtQuick
import QtQuick.Controls
import QtCore
import Functions 1.0
import "../components"

Window {
    id: win
    visible: true
    opacity: 1
    height: 405
    width: 480
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    Rectangle {
        id: root
        color: "#ffffff"
        border.color: "#dcdfe6"
        border.width: 1
        radius: 10
        anchors.fill: parent

        WindowTitleBar {
            id: titleBar
            title: "随机数生成器"
            window: win
        }

        Column {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.topMargin: 6
            spacing: 12

            // 范围设置
            Rectangle {
                id: rangeCard
                width: parent.width
                height: 140
                radius: 10
                color: "#fafafa"
                border.color: "#e4e7ed"

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Row {
                        width: parent.width
                        spacing: 16

                        // 最小值输入
                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: 6

                            Label {
                                text: "最小值"
                                font.pixelSize: 12
                                color: "#606266"
                                font.bold: true
                            }

                            SpinBox {
                                id: minField
                                width: parent.width
                                height: 36
                                from: -9999999
                                to: 9999999
                                value: Config.memory.get("RandomGenerator.minNum")
                                editable: true

                                onValueChanged: {
                                    Config.memory.set("RandomGenerator.minNum", value, false)
                                    Config.memory.writeConfigFileDebounced()
                                }

                                background: Rectangle {
                                    radius: 6
                                    color: "#ffffff"
                                    border.color: "#dcdfe6"
                                    border.width: 1
                                }

                                contentItem: TextInput {
                                    text: minField.textFromValue(minField.value, minField.locale)
                                    font.pixelSize: 13
                                    color: "#303133"
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: !minField.editable
                                    validator: minField.validator
                                }
                            }
                        }

                        // 最大值输入
                        Column {
                            width: (parent.width - parent.spacing) / 2
                            spacing: 6

                            Label {
                                text: "最大值"
                                font.pixelSize: 12
                                color: "#606266"
                                font.bold: true
                            }

                            SpinBox {
                                id: maxField
                                width: parent.width
                                height: 36
                                from: -9999999
                                to: 9999999
                                value: Config.memory.get("RandomGenerator.maxNum")
                                editable: true

                                onValueChanged: {
                                    Config.memory.set("RandomGenerator.maxNum", value, false)
                                    Config.memory.writeConfigFileDebounced()
                                }

                                background: Rectangle {
                                    radius: 6
                                    color: "#ffffff"
                                    border.color: "#dcdfe6"
                                    border.width: 1
                                }

                                contentItem: TextInput {
                                    text: maxField.textFromValue(maxField.value, maxField.locale)
                                    font.pixelSize: 13
                                    color: "#303133"
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: !maxField.editable
                                    validator: maxField.validator
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 36

                        Label {
                            id: countLabel
                            text: "生成数量："
                            font.pixelSize: 12
                            font.bold: true
                            color: "#606266"
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        SpinBox {
                            id: countBox
                            width: 100
                            height: parent.height
                            from: 1
                            to: 50
                            value: 1
                            editable: true
                            anchors.left: countLabel.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter

                            background: Rectangle {
                                radius: 6
                                color: "#ffffff"
                                border.color: "#dcdfe6"
                                border.width: 1
                            }

                            contentItem: TextInput {
                                text: countBox.textFromValue(countBox.value, countBox.locale)
                                font.pixelSize: 13
                                color: "#303133"
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                readOnly: !countBox.editable
                                validator: countBox.validator
                            }
                        }

                        Label {
                            id: repeatLable
                            text: "可重复："
                            font.pixelSize: 12
                            font.bold: true
                            color: "#606266"
                            anchors.left: countBox.right
                            anchors.leftMargin: 24
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Switch {
                            id: repeatSwitch
                            checked: false
                            anchors.left: repeatLable.right
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: win.allowRepeat = checked
                            implicitWidth: 40
                            implicitHeight: 20

                            indicator: Rectangle {
                                implicitWidth: 40
                                implicitHeight: 20
                                radius: height / 2
                                color: repeatSwitch.checked ? "#409EFF" : "#dcdfe6"
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    implicitWidth: 16
                                    implicitHeight: 16
                                    radius: 8
                                    y: 2
                                    x: repeatSwitch.checked ? parent.width - width - 2 : 2
                                    color: "#ffffff"
                                    Behavior on x {
                                        NumberAnimation { duration: 100 }
                                    }
                                }
                            }

                        }
                    }
                }
            }

            // 生成按钮
            Button {
                id: generateBtn
                width: parent.width
                height: 48

                background: Rectangle {
                    radius: 8
                    color: generateBtn.pressed ? "#2b75e0" : (generateBtn.hovered ? "#4f8cff" : "#409eff")

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }

                contentItem: Label {
                    text: "生成随机数"
                    font.pixelSize: 15
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: generateRandomNumbers()
            }

            // 结果展示卡片
            Rectangle {
                id: resultCard
                width: parent.width
                height: 134
                radius: 10
                color: "#fafafa"
                border.color: "#e4e7ed"

                Column {
                    id: resultContent
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 12

                    // 随机数卡片列表
                    Rectangle {
                        id: listContainer
                        width: parent.width
                        height: 90
                        radius: 6
                        color: "transparent"

                        ListView {
                            id: listView
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            clip: true
                            orientation: ListView.Horizontal
                            spacing: 8
                            boundsBehavior: Flickable.StopAtBounds

                            // 当内容比容器窄时，ListView 缩小到内容宽度并居中；否则占满宽度并可滚动
                            width: Math.min(contentWidth, listContainer.width - 8)
                            anchors.horizontalCenter: parent.horizontalCenter

                            model: randomNumbers

                            delegate: Rectangle {
                                width: 82
                                height: 82
                                radius: 8
                                color: "#ffffff"
                                border.color: "#e4e7ed"

                                Component.onCompleted: {
                                    scaleAnim.start()
                                    opacityAnim.start()
                                }

                                Label {
                                    id: numText
                                    text: modelData
                                    font.pixelSize: 26
                                    font.bold: true
                                    color: "#303133"
                                    anchors.centerIn: parent
                                }

                                NumberAnimation {
                                    id: scaleAnim
                                    target: parent
                                    property: "scale"
                                    from: 0
                                    to: 1
                                    duration: 500
                                    easing.type: Easing.OutBack
                                }

                                NumberAnimation {
                                    id: opacityAnim
                                    target: parent
                                    property: "opacity"
                                    from: 0
                                    to: 1
                                    duration: 500
                                }
                            }
                        }
                    }
                }
                // 统计信息
                Label {
                    id: resultCountLabel
                    text: ""
                    font.pixelSize: 12
                    color: "#909399"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                }
            }
        }
    }

    property var randomNumbers: []
    property bool allowRepeat: false

    // 生成随机数函数
    function generateRandomNumbers() {
        let min = minField.value
        let max = maxField.value
        let count = countBox.value

        // 验证范围
        if (min >= max) {
            resultCountLabel.text = "错误：最小值必须小于最大值"
            resultCountLabel.color = "#f56c6c"
            randomNumbers = []
            return
        }

        if (count <= 0) {
            resultCountLabel.text = "错误：生成数量必须大于 0"
            resultCountLabel.color = "#f56c6c"
            randomNumbers = []
            return
        }

        // 生成随机数
        let results = []
        let rangeSize = (max - min + 1)

        if (!allowRepeat && count > rangeSize) {
            resultCountLabel.text = "错误：不重复时生成数量不能超过范围大小（" + rangeSize + "）"
            resultCountLabel.color = "#f56c6c"
            randomNumbers = []
            return
        }

        if (allowRepeat) {
            for (let i = 0; i < count; i++) {
                let randomNum = Math.floor(Math.random() * rangeSize) + min
                results.push(randomNum)
            }
        } else {
            let used = new Set()
            while (results.length < count) {
                let randomNum = Math.floor(Math.random() * rangeSize) + min
                if (!used.has(randomNum)) {
                    used.add(randomNum)
                    results.push(randomNum)
                }
            }
        }

        // 更新结果
        randomNumbers = results
        resultCountLabel.text = "共 " + count + " 个随机数（范围：" + min + " - " + max + "，" + (allowRepeat ? "可重复" : "不重复") + "）"
        resultCountLabel.color = "#909399"
    }
}
