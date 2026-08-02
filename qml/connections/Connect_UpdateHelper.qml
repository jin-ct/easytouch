import QtQuick
import Functions 1.0

Connections {
    target: Global.updateHelper
    function onUpdateAvailable(version) {
        let behavior = Config.settings.get("AutoUpdateBehavior");
        let msg = behavior === "fullyAuto" ? "更新正在进行" : "点击此处开始更新"
        if (behavior !== "noNotice")
            Global.notification.showNotification("update", "有新版本的易触控" + "（" + version + "）", msg)
    }
}