import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import "../SettingItems"

FluScrollablePage{
    id: root
    title: qsTr("基本设置")

    SettingItemExpander {
        title: "测试1"
        iconSource: FluentIcons.Connect
        description: "测试测试测试测试测试测试测试测试测测试测试测试试测试测试测试测试试测试测试测试测试试测试测试测试测试试测试测试测试试测试测试测试测试"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
            }
        contentHeight: sub.implicitHeight
        ColumnLayout {
            id: sub
            width: parent.width
            spacing: -1
            clip: true
            ExpandedItem {
                title: "测试1"
            }
            ExpandedItem {
                title: "测试2"
                description: "测试测试测试测试测试测试测试测试测测试测试测试试测试测试测"
                controlDelegate:
                    FluToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                    }
            }
            ExpandedItem {
                title: "测试3"
                controlDelegate:
                    FluToggleSwitch {
                        Layout.alignment: Qt.AlignVCenter
                    }
            }
        }
    }
    SettingItemExpander {
        title: "测试2"
        expand: true
        iconSource: FluentIcons.Connect
        description: "测试测试测试测试测试测试测试测试试测试测试测试测试试测试测试测试测试试测试测试测试测试测试测试测试"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
            }
    }
    SettingItem {
        title: "测试3"
        iconSource: FluentIcons.Connect
        description: "测试测试测试测试测试测测试测试测试"
        controlDelegate:
            FluToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
            }
    }
    SettingItem {
        title: "测试4"
        iconSource: FluentIcons.Connect
        description: "测试测试测试测试测试测测测试测试测试测试测试测试试测试测试测试测试试测试测试测试测试试测试测试测试测试试测试测试测试测试试测试测试试测试测试"
        controlDelegate:
            RowLayout  {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter
                FluComboBox {
                    Layout.alignment: Qt.AlignVCenter
                    model: ListModel {
                        id: model
                        ListElement { text: "Banana" }
                        ListElement { text: "Apple" }
                        ListElement { text: "Coconut" }
                    }
                }
                FluToggleSwitch {
                    Layout.alignment: Qt.AlignVCenter
                }
            }
    }
}