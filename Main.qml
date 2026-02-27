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

    property int windowBottomMargin: 20                          // 工具栏窗口初始下边距
    property int windowHorizontalMargin: 8                       // 工具栏窗口初始左右边距
    property int windowWidth: 52                                 // 工具栏窗口宽度
    property int windowHeight: 196                               // 工具栏窗口高度（未折叠）
    property int windowFoldedHeight: 52                          // 工具栏窗口高度（已折叠）
    property int rightWindowHeight:  windowHeight                // 工具栏右窗口当前高度（窗口动画前变换）
    property int leftWindowHeight: windowHeight                  // 工具栏左窗口当前高度（窗口动画前变换）
    property int windowAnimationDuration: 160                    // 工具栏窗口动画时长
    property double windowLowOpacity: 0.40                       // 工具栏窗口最低透明度
    property double windowOpacity: 0.80                          // 工具栏窗口最高透明度
    property double windowOpacityChangeDuration: 10000           // 工具栏窗口透明度改变时间间隔

    // 设置保存
    Settings {
        id: settings
        location: "file:///" + getAppDir() + "\\config\\settings.ini"
        category: "Basic"
        property alias isAutoStart: settingsPage.isAutoStart
        property alias isAutoShowBtns: settingsPage.isAutoShowBtns
        property alias isSendOpenUsb: settingsPage.isSendOpenUsb
        property alias isAutoUpdate: settingsPage.isAutoUpdate
        property alias isWeChatTouchHelperEnable: settingsPage.isWeChatTouchHelperEnable
        property alias isWindowFocusHelperEnable: settingsPage.isWindowFocusHelperEnable
        property alias penSavePath: settingsPage.penSavePath
    }
    Settings {
        id: scrMoveSaveData
        location: "file:///" + getAppDir() + "\\config\\screenMove.ini"
        category: "ScreenMoveSaveDatas"
        property var screenMoveSaveList: []
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
    FullscreenWatcher {
        id: fsWatcher

        onFullscreenEntered: {
        }
        onFullscreenExited: {
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
            fsWatcher.stop()
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
        rightWindow.y = Screen.desktopAvailableHeight - (rightWindowHeight + windowBottomMargin)
        leftWindow.y = Screen.desktopAvailableHeight - (rightWindowHeight + windowBottomMargin)
        rightWindow.height = rightWindowHeight
        leftWindow.height = leftWindowHeight
        if (!settingsPage.isAutoShowBtns) {
            rightContent.isFolded = true
            leftContent.isFolded = true
        }
        funs.setWindowNoActivate(windows)
        funs.setWindowNoActivate(rightWindow)
        funs.setWindowNoActivate(leftWindow)
        setTimeout(() => {
            rightWindowOpacity.drop()
            leftWindowOpacity.drop()
            windowsOpacityTimer.start()
        }, 6000)
        console.log("windowsCompleted")
    }

    // 按钮列表数据
    // 默认列表
    ListModel {
        id: toolModel
        ListElement {
            text: "关闭窗口"; idStr: "close"; checked: false; checkable: false; link: false; exclusive: false; cancelable: true; icon: "qrc:/icon/close.svg"
        }
        ListElement {
            text: "系统音量"; idStr: "volume"; checked: false; checkable: false; link: false; exclusive: false; cancelable: true; icon: "qrc:/icon/volume.svg"
        }
        ListElement {
            text: "批注"; idStr: "pen"; checked: false; checkable: false; link: false; exclusive: false; cancelable: true; icon: "qrc:/icon/pen_2.svg"
        }
        ListElement {
            text: "屏幕移位"; idStr: "screenMove"; checked: false; checkable: false; link: false; exclusive: false; cancelable: true; icon: "qrc:/icon/screenMove.svg"
        }
        ListElement {
            text: "随机数"; idStr: "random"; checked: false; checkable: false; link: false; exclusive: false; cancelable: true; icon: "qrc:/icon/random.svg"
        }
    }
    // 屏幕批注列表
    ListModel {
        id: penModel
        ListElement {
            text: "批注"; idStr: "selectPen"; checked: true; checkable: true; link: true; exclusive: true; cancelable: false; icon: "qrc:/icon/pen.svg"
        }
        ListElement {
            text: "橡皮"; idStr: "selectEraser"; checked: false; checkable: true; link: true; exclusive: true; cancelable: false; icon: "qrc:/icon/eraser.svg"
        }
        ListElement {
            text: "关闭批注"; idStr: "closePen"; checked: false; checkable: false; link: false; exclusive: false; cancelable: true; icon: "qrc:/icon/rmudisk.svg"
        }
        ListElement {
            text: "保存批注"; idStr: "savePen"; checked: false; checkable: false; link: false; exclusive: false; cancelable: true; icon: "qrc:/icon/save.svg"
        }
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

    // 屏幕移位保存对话框
    Loader {
        id: scrMoveSaveDialog
        property rect sourceRect
        property rect mirrorRect
        function show(sourceRect, mirrorRect) {
            scrMoveSaveDialog.sourceRect = sourceRect
            scrMoveSaveDialog.mirrorRect = mirrorRect
            source = "components/Dialog/ScrMoveSaveDialog.qml"
        }
        onLoaded: {
            item.setRect(scrMoveSaveDialog.sourceRect, scrMoveSaveDialog.mirrorRect)
        }
        Connections {
            target: scrMoveSaveDialog.item
            function onVisibleChanged(val) {
                if (!val) scrMoveSaveDialog.source = ""
            }
            function onSaved(newData) {
                scrMoveSaveData.screenMoveSaveList =
                        scrMoveSaveData.screenMoveSaveList.concat(newData)
                console.log("ScreenMoveSaved: ", scrMoveSaveDialog.sourceRect, scrMoveSaveDialog.mirrorRect)
            }
        }
    }

    // 工具栏的弹出层
    VolumePopup {
        id: volumePopup
        funs: funs
    }
    PenPopup {
        id: penPopup
        funs: funs
        onSelectedColorChanged: {
            if (whileboard.status === Loader.Ready) {
                console.log("whileboard-onSelectedColorChanged", selectedColor)
                whileboard.item.penColor = selectedColor
            }
        }
        onSelectedWidthChanged: {
            if (whileboard.status === Loader.Ready) {
                console.log("whileboard-onSelectedWidthChanged", selectedWidth)
                whileboard.item.penWidth = selectedWidth
            }
        }
    }
    EraserPopup {
        id: eraserPopup
        funs: funs
        onClear: {
            if (whileboard.status === Loader.Ready) {
                console.log("whileboard-onClear")
                whileboard.item.clear()
                // 清空后切换回画笔
                whileboard.item.switchToPen()
                toolModel.setProperty(0, "checked", true)
                toolModel.setProperty(1, "checked", false)
            }
        }
    }
    ScrMoveSaveList {
        id: scrMoveSaveList
        funs: funs
        screenMovement: screenMove
        screenMoveSaveList: scrMoveSaveData.screenMoveSaveList
    }

    // 右侧工具栏
    Window {
        id: rightWindow
        width: windowWidth
        x: Screen.desktopAvailableWidth - (width + windowHorizontalMargin)
        visible: true
        color: "transparent"
        flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
        opacity: windowOpacity
        title: "易触控工具栏"

        ToolWindowContent {
            id: rightContent
            window: rightWindow
            funs: funs
            model: toolModel
            windowAnimationDuration: windows.windowAnimationDuration

            onButtonTriggered: (idStr, checked, perState, pointX, pointY) => {
                handleButtonTriggered(idStr, checked, perState, pointX, pointY)
                // 处理窗口主图标按钮事件
                switch(idStr) {
                case "mainIconClick":
                    isFolded = !isFolded
                    break
                }
            }
            onDrag: riseWindows(true)
            onIsFoldedChanged: {
                windows.rightWindowHeight = isFolded ? windowFoldedHeight : windowHeight
                handleWindowHeightChange(rightWindow.height, windows.rightWindowHeight, true)
                height = rightWindowHeight
                backgroundOpacity = isFolded ? 0 : 1
            }
        }
    }

    // 左侧工具栏
    Window {
        id: leftWindow
        width: windowWidth
        x: windowHorizontalMargin
        visible: true
        color: "transparent"
        flags:  Qt.Window | Qt.WindowDoesNotAcceptFocus | Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
        opacity: windowOpacity
        title: "易触控工具栏"

        ToolWindowContent {
            id: leftContent
            window: leftWindow
            funs: funs
            model: toolModel
            windowAnimationDuration: windows.windowAnimationDuration

            onButtonTriggered: (idStr, checked, perState, pointX, pointY) => {
                handleButtonTriggered(idStr, checked, perState, pointX, pointY)
                // 处理窗口主图标按钮事件
                switch(idStr) {
                case "mainIconClick":
                    isFolded = !isFolded
                    break
                }
            }
            onDrag: riseWindows(true)
            onIsFoldedChanged: {
                windows.leftWindowHeight = isFolded ? windowFoldedHeight : windowHeight
                handleWindowHeightChange(leftWindow.height, windows.leftWindowHeight, false)
                height = leftWindowHeight
                backgroundOpacity = isFolded ? 0 : 1
            }
        }
    }
    // =============== 窗口（结束） ===============

    // 动画
    PropertyAnimation {
        id: leftWindowOpacity
        target: leftWindow
        property: "opacity"
        duration: 1500

        function rise(isFast = false) {
            if (leftWindow.opacity === windowOpacity) return
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowLowOpacity
            to = windowOpacity
            start()
        }
        function drop(isFast = false) {
            if (leftWindow.opacity !== windowOpacity) return
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowOpacity
            to = windowLowOpacity
            start()
        }
        function change(isFast = false) {
            if (leftWindow.opacity === windowOpacity) {
                drop(isFast)
            } else {
                rise(isFast)
            }
        }
    }
    PropertyAnimation {
        id: rightWindowOpacity
        target: rightWindow
        property: "opacity"
        duration: 1500

        function rise(isFast = false) {
            if (rightWindow.opacity === windowOpacity) return
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowLowOpacity
            to = windowOpacity
            start()
        }
        function drop(isFast = false) {
            if (rightWindow.opacity !== windowOpacity) return
            if (isFast)
                duration = 150
            else
                duration = 1500
            from = windowOpacity
            to = windowLowOpacity
            start()
        }
        function change(isFast = false) {
            if (rightWindow.opacity === windowOpacity) {
                drop(isFast)
            } else {
                rise(isFast)
            }
        }
    }

    // 窗口渐变动画定时器
    Timer {
        id: windowsOpacityTimer
        interval: windowOpacityChangeDuration
        onTriggered: {
            rightWindowOpacity.change()
            leftWindowOpacity.change()
            setTimeout(() => {
                rightWindowOpacity.drop()
                leftWindowOpacity.drop()
            }, 3000)
        }
    }

    // 工具函数
    Timer {id: timer}
    function setTimeout(cb, delayTime) {
       timer.interval = delayTime;
       timer.repeat = false;
       timer.triggered.connect(cb);
       timer.restart();
    }
    Timer {id: timer_2}
    function setTimeout_2(cb, delayTime) {
       timer_2.interval = delayTime;
       timer_2.repeat = false;
       timer_2.triggered.connect(cb);
       timer_2.restart();
    }
    function handleWindowHeightChange(from, to, isRightWindows) {
        if (to > from) {
            if (isRightWindows) {
                rightWindow.height = rightWindowHeight
            } else {
                leftWindow.height = leftWindowHeight
            }
        }
        setTimeout_2(() => {
            if (to < from) {
                if (isRightWindows) {
                    rightWindow.height = rightWindowHeight
                } else {
                    leftWindow.height = leftWindowHeight
                }
            }
        }, windowAnimationDuration)
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
    ListModel { id: tmpModel }
    function swapModels(modelA, modelB) {
        tmpModel.clear()
        for (let i = 0; i < modelA.count; ++i)
            tmpModel.append(modelA.get(i))
        modelA.clear()
        for (let j = 0; j < modelB.count; ++j)
            modelA.append(modelB.get(j))
        modelB.clear()
        for (let k = 0; k < tmpModel.count; ++k)
            modelB.append(tmpModel.get(k))
    }
    property int usbBtnIndexBegin: 0
    function showUsbBtn() {
        usbBtnIndexBegin = toolModel.count
        toolModel.append({
            text: "弹出U盘",
            idStr: "ejectDrive",
            checked: false,
            checkable: false,
            link: false,
            exclusive: false,
            icon: "qrc:/icon/rmudisk.svg"
        })
        toolModel.append({
            text: "打开U盘",
            idStr: "openDrive",
            checked: false,
            checkable: false,
            link: false,
            exclusive: false,
            icon: "qrc:/icon/UDisk.svg"
        })
    }
    function hideUsbBtn() {
        toolModel.remove(usbBtnIndexBegin, 2)
    }
    function closePen() {
        swapModels(penModel, toolModel)
        penModel.setProperty(0, "checked", true)
        penModel.setProperty(1, "checked", false)
        whileboard.close()
    }
    function riseWindows(isFast) {
        windowsOpacityTimer.stop()
        rightWindowOpacity.rise(isFast)
        leftWindowOpacity.rise(isFast)
        windowsOpacityTimer.restart()
    }

    function handleButtonTriggered(idStr, checked, perState, pointX, pointY) {
        console.log("funBtnTriggered, idStr =", idStr, ", checked =", checked, ", pointX =", pointX, ", pointY =", pointY)
        // 提升窗口透明度 (保存批注时不提升)
        if (idStr !== "savePen")
            riseWindows(true)
        // 处理按钮事件
        switch(idStr) {
        case "close":
            funs.closeTopWindow()
            break
        case "volume":
            if (!volumePopup.visible)
                volumePopup.hideOrShow(pointX, pointY)
            break
        case "openDrive":
            funs.openDrive()
            break
        case "ejectDrive":
            if (funs.ejectDrive()) {
                notificationHp.showNotification("rmUsb", "U盘已安全拔出", "U盘已安全拔出")
                console.log("ejectDriveSuccess")
            } else {
                notificationHp.showNotification("rmUsb", "U盘弹出失败", "U盘弹出失败")
                console.error("ejectDriveError")
            }
            break
        case "random":
            randomGenerator.show()
            break
        case "pen":
            swapModels(toolModel, penModel)
            whileboard.show()
            rightWindow.raise()
            leftWindow.raise()
            break
        case "closePen":
            closePen()
            break
        case "selectPen":
            if(checked) {
                whileboard.item.switchToPen()
                if (perState) {
                    if (!penPopup.visible)
                        penPopup.hideOrShow(pointX, pointY)
                }
            }
            break
        case "selectEraser":
            if(checked) {
                whileboard.item.switchToEraser()
                if (perState) {
                    if (!eraserPopup.visible)
                        eraserPopup.hideOrShow(pointX, pointY)
                }
            }
            break
        case "savePen":
            rightWindow.opacity = 0.2  // 截屏时降透明度
            leftWindow.opacity = 0.2
            whileboard.item.exportPng(fileHelper.getNowDateTimeNameFilePath(settings.penSavePath, "png", true))
            closePen()
            riseWindows()
            break
        case "screenMove":
            if (!screenMove.isStarted()) {
                screenMove.start()
            } else {
                screenMove.stopAll()
            }
            break
        case "screenMoveLongPressed":
            scrMoveSaveList.hideOrShow(pointX, pointY)
            break
        }
    }
}
