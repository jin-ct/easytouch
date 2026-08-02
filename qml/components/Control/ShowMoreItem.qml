import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FluentUI

Item {
    id: root
    implicitHeight: (show ? content.implicitHeight : 0) + btn.implicitHeight
    implicitWidth: Math.max(content.implicitWidth, btn.implicitHeight)

    property string btnText: qsTr("显示更多")
    property string btnExpandedText: qsTr("收起")
    property string tip: ""
    property bool show: false
    default property Component contentItem

    FluTextButton {
        id: btn
        implicitHeight: 20
        anchors {
            bottom: parent.bottom
        }
        text: show ? btnExpandedText : btnText
        font.pixelSize: 11
        onClicked: {
            show = !show
        }
        FluTooltip {
            visible: parent.hovered && tip !== ""
            text: tip
            delay: 500
        }
    }

    FluLoader {
        id: content
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: btn.top
        }
        active: show
        sourceComponent: root.contentItem
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: 88 }
    }
}
