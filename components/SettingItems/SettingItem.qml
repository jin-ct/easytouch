import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FluentUI

FluFrame {
    id: root
    Layout.fillWidth: true
    padding: 16
    Layout.topMargin: 6

    property int iconSource: 0
    property string title: ""
    property string description: ""
    property color iconColor: FluTheme.fontPrimaryColor
    property color textColor: FluTheme.fontPrimaryColor
    property color descTextColor: FluTheme.fontSecondaryColor
    property Component controlDelegate

    RowLayout {
        anchors.fill: parent
        Layout.alignment: Qt.AlignVCenter
        spacing: 12

        FluIcon {
            visible: root.iconSource !== 0
            id: text_icon
            font.pixelSize: 20
            iconSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            iconColor: root.iconColor
            iconSource: root.iconSource
            Layout.alignment: Qt.AlignVCenter
            padding: 4
        }

        ColumnLayout {
            id: inf_text
            spacing: 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Text {
                text: root.title
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                color: root.textColor
                font.pixelSize: 14
                renderType: FluTheme.nativeText ? Text.NativeRendering : Text.QtRendering
            }
            Text {
                visible: root.description !== ""
                text: root.description
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft
                color: root.descTextColor
                font.pixelSize: 11
                renderType: FluTheme.nativeText ? Text.NativeRendering : Text.QtRendering
                wrapMode: Text.Wrap
                lineHeight: 1
            }
        }

        FluLoader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: root.controlDelegate
        }
    }
}