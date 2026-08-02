import QtQuick
import QtQuick.Controls
import FluentUI
import Functions 1.0
import "../components"

FluWindow {
    id: win
    title: "易触控设置"
    width: 960
    height: 620
    minimumWidth: 628
    minimumHeight: 320
    launchMode: FluWindowType.SingleTask
    fitsAppBarWindows: true
    appBar: FluAppBar {
        height: 30
        showDark: true
        darkClickListener:(button)=>handleDarkChanged(button)
        z:7
    }
    onArgumentChanged: {
        if (Component.status === Component.Ready)
            toPageInArgument();
    }
    Component.onCompleted: {
        toPageInArgument()
    }
    function toPageInArgument() {
        if (argument.hasOwnProperty("page")) {
            switch(argument.page){
            case "about":
                paneItem_about.tap()
                break
            }
        }
    }

    property alias navigationView: nav_view

    FluObject{
        id: itemsOriginal

        FluPaneItem{
            title: qsTr("基本设置")
            icon: FluentIcons.Settings
            url: "qrc:/qt/qml/easytouch/qml/components/SettingPages/Basic.qml"
            onTap:{
                navigationView.push(url)
            }
        }
        // FluPaneItem{
        //     title: qsTr("触控优化")
        //     icon: FluentIcons.Touch
        //     url: "qrc:/qt/qml/easytouch/qml/components/SettingPages/TouchPromote.qml"
        //     onTap:{
        //         navigationView.push(url)
        //     }
        // }
        FluPaneItem{
            title: qsTr("工具栏")
            icon: FluentIcons.HolePunchLandscapeRight
            url: "qrc:/qt/qml/easytouch/qml/components/SettingPages/ToolBar.qml"
            onTap:{
                navigationView.push(url)
            }
        }
        FluPaneItem{
            title: qsTr("辅助功能")
            icon: FluentIcons.ViewAll
            url: "qrc:/qt/qml/easytouch/qml/components/SettingPages/Functions.qml"
            onTap:{
                navigationView.push(url)
            }
        }
        FluPaneItem{
            title: qsTr("高级")
            icon: FluentIcons.Code
            url: "qrc:/qt/qml/easytouch/qml/components/SettingPages/Advanced.qml"
            onTap:{
                navigationView.push(url)
            }
        }
    }

    FluObject{
        id: itemsFooter

        FluPaneItemSeparator {}

        FluPaneItem{
            id: paneItem_about
            title: qsTr("关于")
            icon: FluentIcons.Info
            url: "qrc:/qt/qml/easytouch/qml/components/SettingPages/About.qml"
            onTap:{
                navigationView.push(url)
            }
        }
        FluPaneItem{
            title: qsTr("重启软件")
            icon: FluentIcons.UpdateRestore
            onTap:{
                Global.funs.restartApp()
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