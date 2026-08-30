import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import FluentUI

FluPage {
    id: control
    property bool autoResetScroll: false
    property alias flickable: _flickable
    default property alias content: container.data

    Flickable{
        id: _flickable
        clip: true
        anchors.fill: parent
        ScrollBar.vertical: FluScrollBar {
            id: bar
        }
        boundsBehavior: Flickable.StopAtBounds
        contentHeight: container.height
        ColumnLayout {
            id: container
            width: parent.width - bar.width
            spacing: control.spacing
        }
    }

    function resetScroll() {
        _flickable.contentY = 0;
    }

    StackView.onActivated: {
        if (autoResetScroll) {
            resetScroll(); // Call this function to reset the scroll position to the top
        }
    }
}
