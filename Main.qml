import QtQuick
import QtQuick.Controls
import QtCore
import FluentUI
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
            // settingsPage.show()
            FluRouter.navigate("/")
        }
    }
    Connections {
        target: Global.updateHelper
        function onUpdateAvailable(version) {
            Global.notification.showNotification("update", "有新版本的易触控" + "（" + version + "）", "现在开始更新易触控")
        }
    }
    Connections {
        enabled: Global.weChatHelper
        target: Global.weChatHelper
        function onLoaded() {
            console.log("WeChatHelper已加载")
        }
    }
    Connections {
        enabled: Global.windowFocusHelper
        target: Global.windowFocusHelper
        // 新窗口出现时更新工具栏窗口置顶
        function onNewWindowCreated() {
            if (toolWindows.status === Loader.Ready) {
                toolWindows.item.updateWindows()
            }
        }
        function onStarted() {
            console.log("WindowFocusHelper已加载")
        }
    }
    Connections {
        enabled: Global.launchingHelper
        target: Global.launchingHelper
        function onLoaded() {
            console.log("LaunchingHelper已加载")
        }
        function onProcessStartedWithInfo(exeName, exeIconId, cursorPos, duration) {
            var splashWindow = Qt.createComponent("views/SplashWindow.qml");
            if (splashWindow.status === Component.Ready) {
                var obj = splashWindow.createObject(null, { exeName: exeName, exeIconId: exeIconId, cursorPos: cursorPos,  duration: duration});
                obj.destroy(15000)  // 最长显示15s
            }
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

    // =============== 窗口 ===============

    FluLauncher {
        id: fluUI
        Connections{
            target: FluTheme
            function onDarkModeChanged(){
                Config.settings.set("DarkMode", FluTheme.darkMode)
            }
        }
        Component.onCompleted: {
            FluApp.init(fluUI)
            FluApp.windowIcon = "qrc:/icon/icon.svg"
            FluTheme.darkMode = Config.settings.get("DarkMode")
            FluTheme.animationEnabled = true
            FluRouter.routes = {
                "/": "qrc:/qt/qml/easytouch/views/SettingsPage.qml",
                "/hotload": "qrc:/qt/qml/easytouch/views/HotloadWindow.qml"
            }
        }
    }

    // 设置窗口
    // Loader {
    //     id: settingsPage
    //     function show() {
    //         source = "views/SettingsPage.qml"
    //     }
    //     Connections {
    //         target: settingsPage.item
    //         function onVisibleChanged(val) {
    //             if (!val) settingsPage.source = ""
    //         }
    //     }
    // }

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
