import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import FluentUI

FluFrame {
    id: root
    Layout.fillWidth: true
    topPadding: 16
    bottomPadding: 16
    leftPadding: 56
    rightPadding: 16
    color: "#00000000"
    border.width: 1
    border.color: FluTheme.darkMode === FluThemeType.Dark ? "#084A4A4A" : "#08878787"

    property string title: ""
    property string description: ""
    property color textColor: FluTheme.fontPrimaryColor
    property color descTextColor: FluTheme.fontSecondaryColor
    property Component controlDelegate

    RowLayout {
        anchors.fill: parent
        Layout.alignment: Qt.AlignVCenter
        spacing: 12

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