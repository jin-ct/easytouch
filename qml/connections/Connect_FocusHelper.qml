import QtQuick
import Functions 1.0

Connections {
    enabled: Global.windowFocusHelper
    target: Global.windowFocusHelper
    signal newWindowCreated()
    function onStarted() {
        console.log("WindowFocusHelper已加载")
    }
    function onNewWindowCreated() {
        newWindowCreated()
    }
}