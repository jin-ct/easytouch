import QtQuick
import Functions 1.0
import FluentUI

Item {
    id: root
    Component.onCompleted: Config.loadConfig()

    FluLauncher {
        id: fluUI
        Connections{
            target: FluTheme
            function onDarkModeChanged(){
                Config.settings.set("DarkMode", FluTheme.darkMode)
            }
        }
    }

    Connections {
        target: Config
        function onAllConfigLoaded() {
            FluApp.init(fluUI)
            FluApp.windowIcon = "qrc:/icon/icon.svg"
            FluTheme.darkMode = Config.settings.get("DarkMode")
            FluTheme.animationEnabled = true
            FluRouter.routes = {
                "/": "qrc:/qt/qml/easytouch/qml/views/SettingsPage.qml",
                "/hotload": "qrc:/qt/qml/easytouch/qml/views/HotloadWindow.qml",
                "/crash":"qrc:/qt/qml/easytouch/qml/views/CrashWindow.qml"
            }
            var args = Qt.application.arguments
            let crashedOperation = Config.settings.get("CrashedOperation")
            if(args.length>=2 && args[1].startsWith("-crashed=")){
                if (crashedOperation === "report")
                    FluRouter.navigate("/crash", {crashFilePath: args[1].replace("-crashed=","")})
                else if (crashedOperation === "closeApp")
                    Qt.quit()
            } else {
                var comp = Qt.createComponent("Main.qml")
                var win = comp.createObject(root)
                win.show()
            }
        }
    }
}
