import QtQuick
import Functions 1.0

Connections {
    target: Global.notification
    signal showContentMenu(point anchor)
    function onNotificationClicked(id) {
        if (id === "openUsb") {
            Global.funs.openDrive()
        }
        if (id === "update" && Config.settings.get("AutoUpdateBehavior") === "onlyRemind") {
            Global.updateHelper.startDownload()
        }
    }
    function onShowContentMenu(anchor) {
        showContentMenu(anchor)
    }
}