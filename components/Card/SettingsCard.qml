import QtQuick
import QtQuick.Controls

Item {
    id: root

    anchors {
        left: parent.left
        leftMargin: 28
        right: parent.right
        rightMargin: 28
    }

    implicitHeight: Math.max(72,
                             titleLabel.implicitHeight
                             + descriptionLabel.implicitHeight
                             + 32)

    property alias title: titleLabel.text
    property alias description: descriptionLabel.text
    default property alias rightContent: rightContainer.data

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 10
        color: "#ffffff"
        border.color: "#e4e7ed"
        border.width: 1

        Item {
            width: parent.width
            height: parent.height
            anchors.margins: 16
            anchors.verticalCenter: parent.verticalCenter

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: rightContainer.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Label {
                    id: titleLabel
                    text: ""
                    font.pixelSize: 14
                    font.bold: true
                    color: "#303133"
                }

                Label {
                    id: descriptionLabel
                    text: ""
                    font.pixelSize: 12
                    color: "#909399"
                    wrapMode: Text.Wrap
                    width: parent.width
                }
            }

            Item {
                id: rightContainer
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}


