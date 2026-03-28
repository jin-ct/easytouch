import QtQuick
import QtQuick.Controls
import Functions 1.0
import "../components/Card"
import "../components"

Window {
    id: win
    visible: true
    opacity: 1
    height: 480
    width: 640
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    // 各设置选项数据
    property alias isShowToolBar: showToolBar.checked
    property alias isAutoStart: autoStart.checked
    property alias isAutoShowBtns: autoShowBtns.checked
    property alias isSendOpenUsb: sendOpenUsb.checked
    property alias isAutoUpdate: autoUpdate.checked
    property alias isWeChatTouchHelperEnable: weChatTouchHelperSwich.checked
    property alias isWindowFocusHelperEnable: windowFocusHelperSwich.checked
    property alias penSavePath: penSavePathSetting.description

    Rectangle {
        id: root

        color: "#ffffff"
        border.color: "#dcdfe6"
        border.width: 1
        radius: 10


        anchors.fill: parent

        WindowTitleBar {
            id: titleBar
            title: "易触控设置"
            window: win
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
                                mipmap:true
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
                        id: showToolBar
                        title: "显示侧边工具栏"
                        description: "是否显示侧边工具栏"
                        checked: true
                        switchControl.onClicked: {
                            console.log("SettingChanged: (isShowToolBar)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoStart
                        title: "开机自启动"
                        description: "Windows 登录后自动启动易触控"
                        checked: false
                        switchControl.onCheckedChanged: {
                            Global.funs.setAutoStart(checked)
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
                        description: "软件启动时自动从远程仓库检查并获取最新发布版"
                        checked: true
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoUpdate)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: weChatTouchHelperSwich
                        title: "微信触控优化"
                        description: "针对微信4.0不支持触控问题优化（微信窗口顶置时失效，可用于临时关闭）"
                        checked: true
                        switchControl.onClicked: {
                            console.log("SettingChanged: (weChatTouchHelperSwich)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: windowFocusHelperSwich
                        title: "窗口焦点助手"
                        description: "保障新窗口获取焦点，防止触控下多次点击导致新窗口焦点被抢占"
                        checked: true
                        switchControl.onClicked: {
                            console.log("SettingChanged: (windowFocusHelperSwich)checked=", checked)
                        }
                    }

                    // 屏幕批注保存位置设置
                    SettingsButtonCard {
                        id: penSavePathSetting
                        title: "屏幕批注保存位置"
                        description: Global.fileHelper.desktopFolder() + "/屏幕批注"  // 当前位置（默认为桌面下屏幕批注目录）
                        text: "选择目录"
                        button.onClicked: {
                            let newPath = Global.fileHelper.openFolderDialog("选择屏幕批注保存目录", penSavePath)
                            if (newPath) {
                                penSavePath = newPath
                                console.log("penSavePathChanged: ", penSavePath)
                            }
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

                    Item { height: 8; width: 1 } // 底部留白
                }
            }
        }
    }
}
