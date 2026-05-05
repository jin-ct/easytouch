import QtQuick
import Functions 1.0

Item {
    id: root
    Component.onCompleted: Config.loadConfig()

    Connections {
        target: Config
        function onAllConfigLoaded() {
            var comp = Qt.createComponent("Main.qml")
            var win = comp.createObject(root)
            win.show()
        }
    }
}
