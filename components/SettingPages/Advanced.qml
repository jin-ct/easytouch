import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../SettingItems"

FluScrollablePage{
    id: root
    title: qsTr("高级")

    SettingItem {
        title: "Qml调试器"
        iconSource: FluentIcons.DeveloperTools
        description: "实时渲染Qml文件"
        controlDelegate:
            FluButton {
                text: "打开"
                onClicked: {
                    FluRouter.navigate("/hotload")
                }
            }
    }
    SettingItemExpander {
        id: pathItem
        title: "程序目录"
        expand: true
        iconSource: FluentIcons.OpenFile
        description: appDir
        controlDelegate:
            FluButton {
                text: "打开目录"
                onClicked: {
                    Qt.openUrlExternally(appDir)
                }
            }
        contentHeight: pathSubItem.implicitHeight
        ColumnLayout {
            id: pathSubItem
            width: parent.width
            spacing: -1
            clip: true
            ExpandedItem {
                title: "日志目录"
                controlDelegate:
                    FluButton {
                        text: "打开目录"
                        onClicked: {
                            Qt.openUrlExternally(appDir + "/logs")
                        }
                    }
            }
            ExpandedItem {
                title: "配置文件"
                controlDelegate:
                    FluButton {
                        text: "打开目录"
                        onClicked: {
                            Qt.openUrlExternally(appDir + "/config")
                        }
                    }
            }
        }
    }
}