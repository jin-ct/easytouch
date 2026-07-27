import QtQuick
import Functions 1.0

Connections {
    enabled: Global.launchingHelper
    target: Global.launchingHelper
    function onLoaded() {
        console.log("LaunchingHelper已加载")
    }
    function onProcessStartedWithInfo(exeName, exeIconId, cursorPos, duration, manualDuration) {
        var splashWindow = Qt.createComponent("qml/views/SplashWindow.qml");
        if (splashWindow.status === Component.Ready) {
            var obj = splashWindow.createObject(null, {
                exeName: exeName, exeIconId: exeIconId, cursorPos: cursorPos,  duration: duration, manualDuration: manualDuration
            });
            obj.destroy(15000)  // 最长显示15s
        }
    }
}