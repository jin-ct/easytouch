import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../../Control"

FluFrame {
    id: root
    implicitHeight: 120
    property string title: ""
    property var model: [{text: "上下滑动", btnId: 0}]
    FluText {
        text: title
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.bottomMargin: 2
    }
    ListView {
        id: list_windowStyle
        anchors {
            top: control_box.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: 6
        }
        spacing: 4
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.model
        delegate: FluCheckBox {
            required property string name
            required property string tip
            required property int value
            text: name
            padding: 1
            checked: isWindowStyleSelected(value, root.selectedFlags)
            onClicked: {
                toggleWindowStyleFlag(value)
                checked = Qt.binding(function () {
                    return isWindowStyleSelected(value, root.selectedFlags)
                })
            }
            onDoubleClicked: {
                toolTip_windowStyle.visible = true
            }
            FluTooltip {
                id: toolTip_windowStyle
                visible: parent.hovered && tip !== ""
                text: tip
                delay: 500
            }
        }
        ScrollBar.vertical: FluScrollBar {}
    }
}