import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions
import "../components"

FluWindow {

    id:window
    title: qsTr("Hot Loader")
    width: 800
    height: 600
    launchMode: FluWindowType.SingleTask
    fitsAppBarWindows: false
    appBar: FluAppBar {
        title: "Hot Loader"
        height: 30
        z:7
    }
    FileWatcher{
        id:watcher
        onFileChanged: {
            loader.reload()
        }
    }
    FluFrame{
        anchors.fill: parent
        FluRemoteLoader{
            id:loader
            anchors.fill: parent
            statusMode: FluStatusLayoutType.Success
            lazy: true
            errorItem: Item{
                FluText{
                    text:loader.itemLodaer().sourceComponent.errorString()
                    color:"red"
                    anchors.fill: parent
                    wrapMode: Text.WrapAnywhere
                    padding: 20
                    verticalAlignment: Qt.AlignVCenter
                    horizontalAlignment: Qt.AlignHCenter
                }
            }
        }
        FluText{
            text: qsTr("Drag in a qml file")
            font: FluTextStyle.Title
            anchors.centerIn: parent
            visible: !loader.itemLodaer().item && loader.statusMode === FluStatusLayoutType.Success
        }
        Rectangle{
            radius: 4
            anchors.fill: parent
            color: "#33333333"
            visible: drop_area.containsDrag
        }
        DropArea{
            id:drop_area
            anchors.fill: parent
            onEntered:
                (event)=>{
                    if(!event.hasUrls){
                        event.accepted = false
                        return
                    }
                    var url = getUrlByEvent(event)
                    if(url === ""){
                        event.accepted = false
                        return
                    }
                    var fileExtension = url.substring(url.lastIndexOf(".") + 1)
                    if (fileExtension !== "qml") {
                        event.accepted = false
                        return
                    }
                    return true
                }
            onDropped:
                (event)=>{
                    var url = getUrlByEvent(event)
                    if(url !== ""){
                        loader.source = url
                        watcher.path = url
                        loader.reload()
                    }
                }
        }
    }

    function getUrlByEvent(event){
        var url = ""
        if (event.urls.length === 0) {
            url = "file:///"+event.getDataAsString("text/plain")
        }else{
            url = event.urls[0].toString()
        }
        return url
    }

}
