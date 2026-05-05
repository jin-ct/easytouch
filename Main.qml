import QtQuick
import QtQuick.Controls
import QtCore
import Functions 1.0
import "./components"
import "./components/Popup"
import "./views"

ApplicationWindow {
    visible: true
    opacity: 0
    id: windows
    flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint

    // cpp通信
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
        target: Global.notification
        function onNotificationClicked(id) {
            if (id === "openUsb") {
                Global.funs.openDrive()
            }
        }
        function onAppQuit() {
            Qt.quit()
        }
        function onStartSettings() {
            settingsPage.show()
        }
    }
    Connections {
        target: Global.updateHelper
        function onUpdateAvailable(version) {
            Global.notification.showNotification("update", "有新版本的易触控" + "（" + version + "）", "现在开始更新易触控")
        }
    }
    Component {
        id: weChatHelper
        WeChatHelper {}
    }
    Loader {
        id: weChatHelperLoader
        sourceComponent: Config.settings.data.WeChatTouchHelper.Enable ? weChatHelper : undefined
        onLoaded: {
            console.log("weChatHelperLoaded")
        }
    }
    Component {
        id: windowFocusHelper
        WindowFocusHelper {}
    }
    Loader {
        id: windowFocusHelperLoader
        sourceComponent: Config.settings.data.WindowFocusHelper.Enable ? windowFocusHelper : undefined
        onLoaded: {
            console.log("windowFocusHelperLoaded")
        }
        Connections {
            target: windowFocusHelperLoader.item
            // 新窗口出现时更新工具栏窗口置顶
            function onNewWindowCreated() {
                if (toolWindows.status === Loader.Ready) {
                    toolWindows.item.updateWindows()
                }
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

    // =============== 窗口 ===============

    // 设置窗口
    Loader {
        id: settingsPage
        function show() {
            source = "views/SettingsPage.qml"
        }
        Connections {
            target: settingsPage.item
            function onVisibleChanged(val) {
                if (!val) settingsPage.source = ""
            }
        }
    }

    // 批注窗口
    Loader {
        id: whileboard
        function show() {
            source = "views/Whileboard.qml"
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
            source = "views/RandomGenerator.qml"
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
        source: Config.settings.data.ToolBar.Enable ? "views/ToolWindows.qml" : ""
    }

    // =============== 窗口（结束） ===============

    // 工具函数
    Timer {id: timer}
    function setTimeout(cb, delayTime) {
       timer.interval = delayTime;
       timer.repeat = false;
       timer.triggered.connect(cb);
       timer.restart();
    }
    function showMessageBox(title, message, okBtnClickedCb = () =>{} , cancelBtnClickedCb = () =>{}) {
        const comp = Qt.createComponent("components/Dialog/MessageBoxDialog.qml")
        if (comp.status === Component.Ready) {
            const dlg = comp.createObject()
            dlg.title = title
            dlg.message = message
            dlg.okBtnClicked.connect(() => {
                okBtnClickedCb()
            })
            dlg.cancelBtnClicked.connect(() => {
                cancelBtnClickedCb()
            })
            dlg.visibleChanged.connect((visible) => {
                if (!visible)
                    dlg.destroy()
            })
        }
    }
}
