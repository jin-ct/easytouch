import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI
import Functions 1.0
import "../../Control"

FluFrame {
    id: root
    implicitHeight: 120
    color: FluTheme.frameColor
    property string title: ""
    property var model: []
    property bool enableSelect: true
    property int selected: 0
    signal editClicked(int id)
    signal itemClicked(int id)
    signal itemDoubleClicked(int id)

    FluText {
        text: title
        anchors.bottom: parent.top
        anchors.left: parent.left
        anchors.bottomMargin: 2
    }
    ListView {
        id: list
        anchors.fill: parent
        spacing: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.model
        bottomMargin: 8
        leftMargin: 8
        rightMargin: 8
        topMargin: 8
        delegate: Rectangle {
            id: item
            required property int id
            required property string text
            radius: 6
            color: FluTheme.frameActiveColor
            border.color: FluTheme.dividerColor
            border.width: root.enableSelect ? (root.selected === item.id ? 2 : 0) : 0
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28

            Button {
                anchors.fill: parent
                background: Rectangle { color: "transparent" }
                onClicked: {
                    root.selected = item.id
                    root.itemClicked(item.id)
                }
                onDoubleClicked: {
                    root.itemDoubleClicked(item.id)
                }
                onHoveredChanged: {
                    item.color = hovered ? FluTheme.itemHoverColor : FluTheme.frameActiveColor
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8
                FluText {
                    text: id
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignVCenter
                }
                FluText {
                    text: item.text
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    clip: true
                }
                FluIconButton{
                    Layout.alignment: Qt.AlignVCenter
                    iconSource: FluentIcons.Edit
                    iconSize: 9
                    background.implicitWidth: 20
                    background.implicitHeight: 20
                    onClicked: {
                        root.editClicked(item.id)
                    }
                }
            }
        }
        ScrollBar.vertical: FluScrollBar {}
    }
}