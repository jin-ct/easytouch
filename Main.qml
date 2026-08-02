import QtQuick
import QtQuick.Controls
import QtCore
import FluentUI
import Functions 1.0
import "./qml/connections"
import "./qml/components"
import "./qml/components/Popup"
import "./qml/views"

ApplicationWindow {
    visible: true
    opacity: 0
    id: windows
    flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint

    // cpp通信
    Connect_Notification {
        onShowContentMenu: function(anchor){
            systemTrayMenu.popupTop(anchor.x - windows.x, anchor.y - windows.y)
        }
    }
    Connect_UpdateHelper {}
    Connections {
        enabled: Global.weChatHelper
        target: Global.weChatHelper
        function onLoaded() {
            console.log("WeChatHelper已加载")
        }
    }
    Connect_FocusHelper {
        onNewWindowCreated: {
            // 新窗口出现时更新工具栏窗口置顶
            if (toolWindows.status === Loader.Ready) {
                toolWindows.item.updateWindows()
            }
        }
    }
    Connect_LaunchingHelper {}
    Connections {
        target: Global.funs
        function onUsbInserted() {
            if (toolWindows.status === Loader.Ready)
                toolWindows.item.showUsbBtn()
            if (Config.settings.data.USBDriveHelper.Enable)
                Global.notification.showNotification("openUsb", "点击打开U盘", "轻触此处打开U盘")
            console.log("newUsbInserted")
        }
        function onUsbRemoved() {
            if (toolWindows.status === Loader.Ready)
                toolWindows.item.hideUsbBtn()
            console.log("usbRemoved")
        }
    }
    Connections {
        target: Config.settings
        function onConfigChanged(path, value) {
            if (!Config.settings.readReady)
                return
            switch(path) {
            case "AutoStart":
                Global.funs.setAutoStart(value)
                break;
            }
        }
    }

    // 窗口创建完成
    Component.onCompleted: {
        Global.funs.setWindowNoActivate(windows)
        if (Config.settings.data.AutoUpdate)
            Global.updateHelper.checkForUpdates("jin-ct", "easytouch")

        console.log("windowsCompleted")
    }

    // =================== 窗口 ===================

    // 系统托盘图标菜单
    SystemTrayMenu {
        id: systemTrayMenu
    }

    // 批注窗口
    Loader {
        id: whileboard
        function show() {
            source = "qml/views/Whileboard.qml"
        }
        function close() {
            source = ""
        }
        onLoaded: {
            Global.funs.setWindowNoActivate(whileboard.item)
            // 确保窗口创建出 winId 后再禁用触摸反馈（否则可能不生效）
            Qt.callLater(function() { Global.funs.disableTouchFeedback(whileboard.item) })
        }
        onStatusChanged: {
            if (status === Loader.Null && toolWindows.status === Loader.Ready)
                toolWindows.item.penPopupReset()
        }
    }

    // 随机数生成器窗口
    Loader {
        id: randomGenerator
        function show() {
            source = "qml/views/RandomGenerator.qml"
        }
        Connections {
            target: randomGenerator.item
            function onVisibleChanged(val) {
                if (!val) randomGenerator.source = ""
            }
        }
    }

    // 工具栏窗口
    Loader {
        id: toolWindows
        source: Config.settings.data.ToolBar.Enable ? "qml/views/ToolWindows.qml" : ""
    }

    // =================== 窗口（结束） ===================
}