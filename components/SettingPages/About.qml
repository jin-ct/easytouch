import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../SettingItems"


FluScrollablePage{
    id: root
    title: qsTr("关于")

    SettingItemExpander {
        id: aboutItem
        title: "易触控优化软件"
        expand: true
        description: "优化大屏触控体验 | MIT协议开源 | 作者：Jin"
        contentHeight: aboutSubItem.implicitHeight
        ColumnLayout {
            id: aboutSubItem
            width: parent.width
            spacing: -1
            clip: true
            ExpandedItem {
                title: "软件版本: " + Config.settings.get("App.Verson")
            }
            ExpandedItem {
                title: "Github"
                description: "https://github.com/jin-ct/easytouch"
                controlDelegate:
                    FluTextButton {
                        text: "打开链接"
                        onClicked: {
                            Qt.openUrlExternally("https://github.com/jin-ct/easytouch")
                        }
                    }
            }
        }
    }
}