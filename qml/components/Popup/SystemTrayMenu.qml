import QtQuick
import QtQuick.Controls
import FluentUI
import Functions 1.0

FluMenu {
    id: menu
    popupType: Popup.Window
    spacing: 2
    FluMenuItem {
        text: "设置"
        iconSource: FluentIcons.Settings
        iconSpacing: 8
        iconSize: 13
        padding: 10
        onClicked: {
            FluRouter.navigate("/")
        }
    }
    FluMenuItem {
        text: "关于"
        iconSource: FluentIcons.Info
        iconSpacing: 8
        iconSize: 13
        padding: 10
        onClicked: {
            FluRouter.navigate("/", {"page": "about"})
        }
    }
    FluMenuSeparator { }
    FluMenuItem {
        text:"重启"
        iconSource: FluentIcons.UpdateRestore
        iconSpacing: 8
        iconSize: 13
        padding: 10
        onClicked: {
            Global.funs.restartApp()
        }
    }
    FluMenuItem {
        text:"退出程序"
        iconSource: FluentIcons.PowerButton
        iconSpacing: 8
        iconSize: 13
        spacing: 2
        padding: 10
        onClicked: {
            Qt.quit()
        }
    }
}