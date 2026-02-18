import QtQuick
import QtQuick.Controls
import "../components/Card"

Window {
    id: win
    visible: true
    opacity: 1
    height: 480
    width: 640
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    // 各设置选项数据
    property alias isAutoStart: autoStart.checked
    property alias isAutoShowBtns: autoShowBtns.checked
    property alias isSendOpenUsb: sendOpenUsb.checked
    property alias isAutoUpdate: autoUpdate.checked

    Rectangle {
        id: root

        color: "#ffffff"
        border.color: "#dcdfe6"
        border.width: 1
        radius: 10


        anchors.fill: parent

        Rectangle {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            height: 36
            color: "#00000000"

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: false
                property point pressPos: Qt.point(0, 0)

                onPressed: function(mouse) {
                    var cb = closeButton
                    var x1 = cb.x
                    var x2 = cb.x + cb.width
                    var y1 = cb.y
                    var y2 = cb.y + cb.height
                    if (mouse.x >= x1 && mouse.x <= x2 && mouse.y >= y1 && mouse.y <= y2) {
                        mouse.accepted = false
                        return
                    }
                    pressPos = Qt.point(mouse.x, mouse.y)
                }

                onPositionChanged: function(mouse) {
                    if (!(mouse.buttons & Qt.LeftButton))
                        return
                    if (!win)
                        return
                    win.x += mouse.x - pressPos.x
                    win.y += mouse.y - pressPos.y
                }
            }

            Item {
                anchors.fill: parent
                anchors.margins: 8

                Label {
                    id: titleLabel
                    text: qsTr("易触控设置")
                    color: "#303133"
                    font.pixelSize: 13
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                }

                ToolButton {
                    id: closeButton
                    width: 24
                    height: 24
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    background: Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: closeButton.pressed ? "#e4e7ed" : (closeButton.hovered ? "#ECEFF5" : "transparent")
                    }

                    contentItem: Image {
                        anchors.centerIn: parent
                        source: "qrc:/icon/close_2.svg"
                        width: 24
                        height: 24
                        fillMode: Image.PreserveAspectFit
                    }

                    onClicked: win.close()
                    Accessible.name: qsTr("关闭设置")
                }
            }
        }

        ScrollView {
            id: scrollView
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded

            contentItem: Flickable {
                id: flickableItem
                contentWidth: contentColumn.implicitWidth
                contentHeight: contentColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: contentColumn
                    width: scrollView.width
                    spacing: 12
                    padding: 16

                    // 顶部基本信息
                    Rectangle {
                        id: headerCard
                        implicitHeight: 80
                        radius: 10
                        color: "#ffffff"
                        border.color: "#e4e7ed"
                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }

                        Item {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 20
                            }

                            Image {
                                id: logoImage
                                source: "qrc:/icon/icon.svg"
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                            }

                            Column {
                                anchors.left: logoImage.right
                                anchors.leftMargin: 16
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4

                                Label {
                                    text: "易触控工具栏"
                                    font.pixelSize: 15
                                    font.bold: true
                                    color: "#303133"
                                }

                                Label {
                                    text: qsTr("版本：%1").arg(Qt.application.version)
                                    font.pixelSize: 12
                                    color: "#606266"
                                }

                                Label {
                                    text: "优化大屏触控体验 | MIT协议开源 | 作者：Jin"
                                    font.pixelSize: 12
                                    color: "#909399"
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    SettingsSwitchCard {
                        id: autoStart
                        title: "开机自启动"
                        description: "Windows 登录后自动启动易触控"
                        checked: true
                        switchControl.onCheckedChanged: {
                            funs.setAutoStart(checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoStart)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoShowBtns
                        title: "自动展开工具栏"
                        description: "软件启动时左右侧工具栏按钮自动展开"
                        checked: true
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoShowBtns)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: sendOpenUsb
                        title: "发送“打开U盘”通知"
                        description: "插入U盘时发送“点击打开U盘”的系统通知"
                        checked: true
                        switchControl.onClicked: {
                            console.log("SettingChanged: (sendOpenUsb)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoUpdate
                        title: "自动更新"
                        description: "软件启动时自动从GitHub检查并获取最新发布版"
                        checked: true
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoUpdate)checked=", checked)
                        }
                    }

                    SettingsButtonCard {
                        title: "Github仓库"
                        description: "https://github.com/jin-ct/easytouch"
                        text: "打开链接"
                        button.onClicked: {
                            Qt.openUrlExternally("https://github.com/jin-ct/easytouch")
                        }
                    }

                    // // 文本输入卡片
                    // SettingsTextFieldCard {
                    //     title: qsTr("用户名称")
                    //     description: qsTr("用于在部分界面中显示的称呼")
                    //     width: Math.min(parent.width - 32, 480)
                    //     placeholderText: qsTr("请输入名称")
                    // }

                    // // 下拉框卡片
                    // SettingsComboCard {
                    //     title: qsTr("主题样式")
                    //     description: qsTr("选择应用的主题风格")
                    //     width: Math.min(parent.width - 32, 480)

                    //     model: [qsTr("跟随系统"), qsTr("浅色"), qsTr("深色")]
                    // }

                    // // Slider 卡片
                    // SettingsSliderCard {
                    //     title: qsTr("界面缩放")
                    //     description: qsTr("调整设置界面的缩放比例（示例）")
                    //     width: Math.min(parent.width - 32, 480)
                    //     anchors.horizontalCenter: parent.horizontalCenter

                    //     from: 80
                    //     to: 120
                    //     value: 100
                    // }

                    Item { height: 8; width: 1 } // 底部留白
                }
            }
        }
    }
}
