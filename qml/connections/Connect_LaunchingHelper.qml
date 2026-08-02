import QtQuick
import Functions 1.0

Connections {
    enabled: Global.launchingHelper
    target: Global.launchingHelper
    property var exeList: []
    function onLoaded() {
        console.log("LaunchingHelper已加载")
    }
    function onProcessStartedWithInfo(exeName, exeIconId, cursorPos, duration, manualDuration) {
        var filtered = exeList.filter(function(item) {
            return item.exeName === exeName
        })
        if (filtered.length > 0) {
            var object = filtered[0].object
            if (object.hasOwnProperty("multipleStart"))
                object.multipleStart = true
        } else {
            var splashWindow = Qt.createComponent("qml/views/SplashWindow.qml");
            if (splashWindow.status === Component.Ready) {
                var obj = splashWindow.createObject(null, {
                    exeName: exeName, exeIconId: exeIconId, cursorPos: cursorPos,  duration: duration, manualDuration: manualDuration
                });
                obj.destroy(16000)
                exeList.push({exeName: exeName, object: obj})
                obj.aboutDestroyed.connect(function() {
                    exeList = exeList.filter(function(item) {
                        return item.exeName !== exeName
                    })
                })
            }
        }
    }
}