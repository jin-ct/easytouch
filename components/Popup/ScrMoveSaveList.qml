import QtQuick
import QtQuick.Controls
import Functions 1.0
import "./"

PopupWindow {
    id: srcMoveSaveList
    popupWidth: 140
    popupHeight: saveDatas.count === 0 ? 40 : (listView.contentHeight+4 > 140 ? 140 : listView.contentHeight+12)
    visible: false

    property var screenMoveSaveList: []
    required property ScreenMovement screenMovement

    ListModel {
        id: saveDatas
    }

    onScreenMoveSaveListChanged: {
        deserializeModel(screenMoveSaveList, saveDatas)
        if (saveDatas.count === 0) {
            tipsText.visible = true
        } else {
            tipsText.visible = false
        }
    }

    Text {
        id: tipsText
        visible: false
        text: "暂无保存记录"
        color: "#666666"
        anchors.centerIn: parent
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: 6
        model: saveDatas
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            width: listView.width
            height: 24
            color: mouse.pressed ? "#F5F5F5" : "#00000000"
            radius: 4

            Text {
                id: nameText
                text: model.name
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 4
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                onClicked: {
                    screenMovement.start(
                        Qt.rect(model.sourceRectX, model.sourceRectY, model.sourceRectW, model.sourceRectH),
                        Qt.rect(model.mirrorRectX, model.mirrorRectY, model.mirrorRectW, model.mirrorRectH),
                        index
                    )
                }
            }
        }
    }

    function deserializeModel(array, listModel) {
        if (!array)
            return
        listModel.clear()
        for (let i = 0; i < array.length; ++i) {
            const item = array[i]
            listModel.append({
                name: item.name,
                sourceRectX: item.sourceRect.x,
                sourceRectY: item.sourceRect.y,
                sourceRectW: item.sourceRect.width,
                sourceRectH: item.sourceRect.height,

                mirrorRectX: item.mirrorRect.x,
                mirrorRectY: item.mirrorRect.y,
                mirrorRectW: item.mirrorRect.width,
                mirrorRectH: item.mirrorRect.height
            })
        }
    }
}
