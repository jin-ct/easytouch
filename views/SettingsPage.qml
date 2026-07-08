import QtQuick
import QtQuick.Controls
import FluentUI
import Functions 1.0
import "../components/Card"
import "../components"

FluWindow {
    id: win
    title: "易触控设置"
    width: 1000
    height: 668
    minimumWidth: 668
    minimumHeight: 320
    launchMode: FluWindowType.SingleTask
    fitsAppBarWindows: true
    appBar: FluAppBar {
        height: 30
        showDark: true
        darkClickListener:(button)=>handleDarkChanged(button)
        z:7
    }

    property alias navigationView: nav_view

    FluObject{
        id: itemsOriginal

        FluPaneItem{
            title: qsTr("基本设置")
            icon: FluentIcons.Settings
            url: "qrc:/qt/qml/easytouch/components/SettingPages/basic.qml"
            onTap:{
                navigationView.push(url)
            }
        }
    }

    FluObject{
        id: itemsFooter

        FluPaneItemSeparator {}

        FluPaneItem{
            title: qsTr("关于")
            icon: FluentIcons.Info
            url: "qrc:/qt/qml/easytouch/components/SettingPages/about.qml"
            onTap:{
                navigationView.push(url)
            }
        }
    }

    Flipable {
        id:flipable
        anchors.fill: parent
        property bool flipped: false
        property real flipAngle: 0
        transform: Rotation {
            id: rotation
            origin.x: flipable.width/2
            origin.y: flipable.height/2
            axis { x: 0; y: 1; z: 0 }
            angle: flipable.flipAngle
        }
        states: State {
            PropertyChanges { target: flipable; flipAngle: 180 }
            when: flipable.flipped
        }
        transitions: Transition {
            NumberAnimation { target: flipable; property: "flipAngle"; duration: 1000 ; easing.type: Easing.OutCubic}
        }
        back: Item {
            anchors.fill: flipable
            visible: flipable.flipAngle !== 0
            Row {
                id:layout_back_buttons
                z:8
                anchors {
                    top: parent.top
                    left: parent.left
                    topMargin: FluTools.isMacos() ? 20 : 5
                    leftMargin: 5
                }
                FluIconButton {
                    iconSource: FluentIcons.ChromeBack
                    width: 30
                    height: 30
                    iconSize: 13
                    onClicked: {
                        flipable.flipped = false
                    }
                }
                FluIconButton {
                    iconSource: FluentIcons.Sync
                    width: 30
                    height: 30
                    iconSize: 13
                    onClicked: {
                        loader.reload()
                    }
                }
                Component.onCompleted: {
                    win.setHitTestVisible(layout_back_buttons)
                }
            }
        }
        front: Item{
            id:page_front
            visible: flipable.flipAngle !== 180
            anchors.fill: flipable
            FluNavigationView {
                property int clickCount: 0
                id: nav_view
                width: parent.width
                height: parent.height
                z:999
                pageMode: FluNavigationViewType.NoStack
                items: itemsOriginal
                footerItems: itemsFooter
                topPadding: {
                    if(win.useSystemAppBar) {
                        return 0
                    }
                    return FluTools.isMacos() ? 20 : 0
                }
                logo: "qrc:/icon/icon.ico"
                title:"设置"
                autoSuggestBox: FluAutoSuggestBox {
                    iconSource: FluentIcons.Search
                    items: getSearchData()
                    placeholderText: qsTr("搜索")
                    filter: (item) => item[textRole].toLowerCase().includes(text.toLowerCase())
                    onItemClicked:
                        (data) => {
                            navigationView.startPageByItem(data)
                        }
                }
                Component.onCompleted: {
                    win.setHitTestVisible(nav_view.buttonMenu)
                    win.setHitTestVisible(nav_view.buttonBack)
                    win.setHitTestVisible(nav_view.imageLogo)
                    setCurrentIndex(0)
                }
            }
        }
    }

/*
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

    Connections {
        target: Global.updateHelper
        function onUpdateCheckFinished(hasUpdate, success) {
            updateBtn.button.enabled = true
            updateBtn.text = "检查更新"
            if (success)
                updateBtn.description = hasUpdate
                                        ? "有新版本 (" + Global.updateHelper.latestVersion + "), 现在开始更新"
                                        : "当前版本已为最新"
        }
        function onUpdateError(err) {
            updateBtn.description = "检查失败：" + err
        }
    }

    Rectangle {
        id: root

        color: "#ffffff"
        border.color: "#dcdfe6"
        border.width: 1
        radius: 10


        anchors.fill: parent

        // WindowTitleBar {
        //     id: titleBar
        //     title: "易触控设置"
        //     window: win
        // }

        ScrollView {
            id: scrollView
            anchors.top: parent.bottom
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
                                id: info
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

                    Text {
                        text: "常规"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    SettingsSwitchCard {
                        id: autoStart
                        title: "开机自启动"
                        description: "Windows 登录后自动启动易触控"
                        checked: Config.settings.data.AutoStart
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.AutoStart)
                                Config.settings.set("AutoStart", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoStart)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoUpdate
                        title: "自动更新"
                        description: "软件启动时自动从远程仓库检查并获取最新发布版"
                        checked: Config.settings.data.AutoUpdate
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.AutoUpdate)
                                Config.settings.set("AutoUpdate", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoUpdate)checked=", checked)
                        }
                    }

                    SettingsComboCard {
                        id: updatChannel
                        title: "更新通道"
                        description: "检查更新版本通道，测试版(beta)通常功能较新但可能存在稳定性问题"
                        model: ["release",  "beta"]
                        comboBox.currentIndex: Config.settings.get("UpdateChannel") === "release" ? 0 : 1
                        comboBox.onActivated: {
                            Config.settings.set("UpdateChannel", comboBox.currentValue)
                            console.log("SettingChanged: (UpdateChannel)selected=", currentText)
                        }
                    }

                    SettingsButtonCard {
                        id: updateBtn
                        title: "检查更新"
                        description: Global.updateHelper.latestVersion === ""
                                     ? "未检查更新"
                                     : (Global.updateHelper.hasUpdate
                                        ? "有新版本 (" + Global.updateHelper.latestVersion + "), 现在开始更新"
                                        : "当前版本已为最新")
                        text: "检查更新"
                        button.onClicked: {
                            Global.updateHelper.checkForUpdates("jin-ct", "easytouch")
                            button.enabled = false
                            text = "检查中"
                        }
                    }

                    Text {
                        text: "工具栏设置"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    SettingsSwitchCard {
                        id: showToolBar
                        title: "显示侧边工具栏"
                        description: "是否显示侧边工具栏"
                        checked: Config.settings.data.ToolBar.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.Enable)
                                Config.settings.set("ToolBar.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (isShowToolBar)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoShowBtns
                        title: "自动展开工具栏"
                        description: "软件启动时左右侧工具栏按钮自动展开"
                        checked: Config.settings.data.ToolBar.AutoShowBtns
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.AutoShowBtns)
                                Config.settings.set("ToolBar.AutoShowBtns", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoShowBtns)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: autoHideBtns
                        title: "自动收起工具栏"
                        description: "当点击工具栏窗口以外区域时自带收起工具栏"
                        checked: Config.settings.data.ToolBar.AutoHideBtns
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.AutoHideBtns)
                                Config.settings.set("ToolBar.AutoHideBtns", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (autoHideBtns)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: showWinodwOpacityAnimation
                        title: "窗口透明度闪烁"
                        description: "窗口透明度周期性闪烁"
                        checked: Config.settings.data.ToolBar.ShowWindowOpacityAnimation
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.ShowWindowOpacityAnimation)
                                Config.settings.set("ToolBar.ShowWindowOpacityAnimation", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (ShowWindowOpacityAnimation)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: stayTopEnhanced
                        title: "置顶增强"
                        description: "通过定时器触发让工具栏和相关窗口置于最顶层"
                        checked: Config.settings.data.ToolBar.StayTopEnhanced
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.ToolBar.StayTopEnhanced)
                                Config.settings.set("ToolBar.StayTopEnhanced", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (stayTopEnhanced)checked=", checked)
                        }
                    }

                    Text {
                        text: "触控优化功能开关"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    SettingsSwitchCard {
                        id: sendOpenUsb
                        title: "发送“打开U盘”通知"
                        description: "插入U盘时发送“点击打开U盘”的系统通知"
                        checked: Config.settings.data.USBDriveHelper.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.USBDriveHelper.Enable)
                                Config.settings.set("USBDriveHelper.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (sendOpenUsb)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: launchingHelperSwich
                        title: "软件启动提示助手（实验性）"
                        description: "软件启动时显示启动提示"
                        checked: Config.settings.data.LaunchingHelper.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.LaunchingHelper.Enable)
                                Config.settings.set("LaunchingHelper.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (LaunchingHelperSwich)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: weChatTouchHelperSwich
                        title: "微信触控优化"
                        description: "针对微信4.0不支持触控问题优化（微信窗口顶置时失效，可用于临时关闭）"
                        checked: Config.settings.data.WeChatTouchHelper.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.WeChatTouchHelper.Enable)
                                Config.settings.set("WeChatTouchHelper.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (weChatTouchHelperSwich)checked=", checked)
                        }
                    }

                    SettingsSwitchCard {
                        id: windowFocusHelperSwich
                        title: "窗口焦点助手 (Bug较多)"
                        description: "保障新窗口获取焦点 (若遇到可能是由Alt键未释放引起的触控失灵问题请关闭该功能)"
                        checked: Config.settings.data.WindowFocusHelper.Enable
                        switchControl.onCheckedChanged: {
                            if (checked !== Config.settings.data.WindowFocusHelper.Enable)
                                Config.settings.set("WindowFocusHelper.Enable", checked)
                        }
                        switchControl.onClicked: {
                            console.log("SettingChanged: (windowFocusHelperSwich)checked=", checked)
                        }
                    }

                    Text {
                        text: "其他"
                        topPadding: 4
                        font.pixelSize: 12
                        color: "#409EFF"

                        anchors {
                            left: parent.left
                            leftMargin: 28
                            right: parent.right
                            rightMargin: 28
                        }
                    }

                    // 屏幕批注保存位置设置
                    SettingsButtonCard {
                        id: penSavePathSetting
                        title: "屏幕批注保存位置"
                        description: Config.settings.data.Drawpad.SavePath // 当前位置
                        text: "选择目录"
                        button.onClicked: {
                            let newPath = Global.fileHelper.openFolderDialog("选择屏幕批注保存目录", Config.settings.get("Drawpad.SavePath"))
                            if (newPath) {
                                Config.settings.set("Drawpad.SavePath", newPath)
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
    */

    Component {
        id: com_reveal
        CircularReveal {
            id: reveal
            target: win.containerItem()
            anchors.fill: parent
            darkToLight: FluTheme.dark
            onAnimationFinished: {
                //动画结束后释放资源
                loader_reveal.sourceComponent = undefined
            }
            onImageChanged: {
                changeDark()
            }
        }
    }

    FluLoader {
        id:loader_reveal
        anchors.fill: parent
    }

    function distance(x1,y1,x2,y2) {
        return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
    }

    function handleDarkChanged(button) {
        if(FluTools.isMacos() || !FluTheme.animationEnabled) {
            changeDark()
        } else {
            loader_reveal.sourceComponent = com_reveal
            var target = win.containerItem()
            var pos = button.mapToItem(target,0,0)
            var mouseX = pos.x + button.width / 2
            var mouseY = pos.y + button.height / 2
            var radius = Math.max(distance(mouseX,mouseY,0,0),distance(mouseX,mouseY,target.width,0),distance(mouseX,mouseY,0,target.height),distance(mouseX,mouseY,target.width,target.height))
            var reveal = loader_reveal.item
            reveal.start(reveal.width*Screen.devicePixelRatio,reveal.height*Screen.devicePixelRatio,Qt.point(mouseX,mouseY),radius)
        }
    }

    function changeDark() {
        if(FluTheme.dark) {
            FluTheme.darkMode = FluThemeType.Light
        } else {
            FluTheme.darkMode = FluThemeType.Dark
        }
    }

    function getSearchData(){
        if(!navigationView){
            return
        }
        var arr = []
        var items = navigationView.getItems();
        for(var i=0;i<items.length;i++){
            var item = items[i]
            if(item instanceof FluPaneItem){
                if (item.parent instanceof FluPaneItemExpander)
                {
                    arr.push({title:`${item.parent.title} -> ${item.title}`,key:item.key})
                }
                else
                    arr.push({title:item.title,key:item.key})
            }
        }
        return arr
    }
}