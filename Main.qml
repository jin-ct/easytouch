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

    // 设置保存
    Settings {
        id: settings
        location: "file:///" + getAppDir() + "\\config\\settings.ini"
        category: "Basic"
        property alias isShowToolBar: settingsPage.isShowToolBar
        property alias isAutoStart: settingsPage.isAutoStart
        property alias isAutoShowBtns: settingsPage.isAutoShowBtns
        property alias isSendOpenUsb: settingsPage.isSendOpenUsb
        property alias isAutoUpdate: settingsPage.isAutoUpdate
        property alias isWeChatTouchHelperEnable: settingsPage.isWeChatTouchHelperEnable
        property alias isWindowFocusHelperEnable: settingsPage.isWindowFocusHelperEnable
        property alias penSavePath: settingsPage.penSavePath
    }

    // cpp类实例
    Functions {
        id: funs

        onUsbInserted: {
            showUsbBtn()
            if (settingsPage.isSendOpenUsb)
                notificationHp.showNotification("openUsb", "点击打开U盘", "轻触此处打开U盘")
            console.log("newUsbInserted")
        }
        onUsbRemoved: {
            hideUsbBtn()
            console.log("usbRemoved")
        }
    }
    NotificationHelper {
        id: notificationHp

        onNotificationClicked: (id) => {
            if (id === "openUsb") {
                funs.openDrive()
            }
        }
        onAppQuit: {
            Qt.quit()
        }
        onStartSettings: {
            settingsPage.show()
        }
    }
    UpdateHelper {
        id: updateHelper
        Component.onCompleted: {
            if (settings.isAutoUpdate)
                updateHelper.checkForUpdates("jin-ct", "easytouch")
        }
        onUpdateAvailable: (version) => {
            notificationHp.showNotification("update", "有新版本的易触控" + "（" + version + "）", "现在开始更新易触控")
        }
    }
    FileHelper {
        id: fileHelper
    }
    Component {
        id: weChatHelper
        WeChatHelper {}
    }
    Loader {
        id: weChatHelperLoader
        sourceComponent: settings.isWeChatTouchHelperEnable ? weChatHelper : undefined
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
        sourceComponent: settings.isWindowFocusHelperEnable ? windowFocusHelper : undefined
        onLoaded: {
            console.log("windowFocusHelperLoaded")
        }
    }
    ScreenMovement {
        id: screenMove
        onSaveRequested: (sourceRect, mirrorRect) => {
            scrMoveSaveDialog.show(sourceRect, mirrorRect)
            console.log("onScreenMoveSaveRequested: ", sourceRect, mirrorRect)
        }
        onDeleteRequested: (btnId) => {
            showMessageBox("删除记录", "你确定要删除该记录吗？", () => {
                var data = scrMoveSaveData.screenMoveSaveList
                data.splice(btnId, 1)
                scrMoveSaveData.screenMoveSaveList = data
                console.log("ScreenMoveSaveDataDeleted:", btnId)
            })
        }
    }

    // 窗口创建完成
    Component.onCompleted: {
        funs.setWindowNoActivate(windows)
        if (settings.isShowToolBar) {
            toolWindows.show()
        }

        console.log("windowsCompleted")
    }

    // =============== 窗口 ===============

    // 设置窗口
    SettingsPage {
        id: settingsPage
        visible: false
        funs: funs
        fileHelper: fileHelper
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
            funs.setWindowNoActivate(whileboard.item)
            // 确保窗口创建出 winId 后再禁用触摸反馈（否则可能不生效）
            Qt.callLater(function() { funs.disableTouchFeedback(whileboard.item) })
        }
        onStatusChanged: {
            if (status === Loader.Null)
                penPopup.reset()
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
    ToolWindows {
        id: toolWindows
        funs: funs
        fileHelper: fileHelper
        settings: settings
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
    function getAppDir() {
        var appPath = Qt.application.arguments[0]
        return appPath.substring(0, appPath.lastIndexOf("\\"))
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
